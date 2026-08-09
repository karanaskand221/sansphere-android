import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const bucket = admin.storage().bucket();

const NEW_USER_COINS = 200;
const REFERRAL_USER_BONUS = 100;
const REFERRER_BONUS = 200;
const AD_REWARD = 10;
const MIN_PRICE = 1;
const MAX_PRICE = 49;

/**
 * Returns the authenticated user ID or throws when unauthenticated.
 *
 * @param {CallableRequest<unknown>} request The callable function request.
 * @return {string} The authenticated user ID.
 */
function requireAuth(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  return uid;
}

/**
 * Creates the user's wallet exactly once.
 * New account = 200 SanCoins.
 */
export const initializeSanCoins = onCall(async (request) => {
  const uid = requireAuth(request);

  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);

    if (snap.exists && snap.data()?.walletInitialized === true) {
      return;
    }

    const existing = snap.exists ? snap.data() : {};

    tx.set(
      userRef,
      {
        sanCoins: Number(existing?.sanCoins ?? NEW_USER_COINS),
        earnedCoins: Number(existing?.earnedCoins ?? NEW_USER_COINS),
        spentCoins: Number(existing?.spentCoins ?? 0),
        purchasedKnowledge: Number(existing?.purchasedKnowledge ?? 0),
        walletInitialized: true,
        referralRewardClaimed: existing?.referralRewardClaimed ?? false,
        createdAt:
            existing?.createdAt ??
            admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });

  return {
    success: true,
    sanCoins: NEW_USER_COINS,
  };
});


/**
 * Apply referral exactly once.
 *
 * New user:
 *   +100
 *
 * Referrer:
 *   +200
 */
export const applyReferral = onCall(async (request) => {
  const uid = requireAuth(request);

  const code = String(request.data?.code ?? "").trim().toUpperCase();

  if (!code) {
    throw new HttpsError("invalid-argument", "Referral code required.");
  }

  const currentUserRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const currentSnap = await tx.get(currentUserRef);

    if (!currentSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "User profile does not exist.",
      );
    }

    const current = currentSnap.data()!;

    if (current.referralRewardClaimed === true || current.referredBy) {
      throw new HttpsError(
        "already-exists",
        "Referral has already been used.",
      );
    }

    const referrerQuery = await db
      .collection("users")
      .where("referralCode", "==", code)
      .limit(1)
      .get();

    if (referrerQuery.empty) {
      throw new HttpsError("not-found", "Invalid referral code.");
    }

    const referrerDoc = referrerQuery.docs[0];

    if (referrerDoc.id === uid) {
      throw new HttpsError(
        "failed-precondition",
        "You cannot use your own referral code.",
      );
    }

    const referrer = referrerDoc.data();

    const currentCoins = Number(current.sanCoins ?? 0);
    const currentEarned = Number(current.earnedCoins ?? 0);

    const referrerCoins = Number(referrer.sanCoins ?? 0);
    const referrerEarned = Number(referrer.earnedCoins ?? 0);

    tx.update(currentUserRef, {
      sanCoins: currentCoins + REFERRAL_USER_BONUS,
      earnedCoins: currentEarned + REFERRAL_USER_BONUS,
      referredBy: referrerDoc.id,
      referralRewardClaimed: true,
      referralAppliedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(referrerDoc.ref, {
      sanCoins: referrerCoins + REFERRER_BONUS,
      earnedCoins: referrerEarned + REFERRER_BONUS,
      referralCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const referralId = `${uid}_${referrerDoc.id}`;

    tx.set(
      db.collection("referral_rewards").doc(referralId),
      {
        referredUserId: uid,
        referrerUserId: referrerDoc.id,
        code,
        newUserReward: REFERRAL_USER_BONUS,
        referrerReward: REFERRER_BONUS,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: false},
    );
  });

  return {
    success: true,
    userReward: REFERRAL_USER_BONUS,
    referrerReward: REFERRER_BONUS,
  };
});


/**
 * Completed rewarded advertisement.
 *
 * Exactly +10 SanCoins.
 *
 * The client should send a unique rewardId generated for
 * the completed ad event.
 */
export const rewardAd = onCall(async (request) => {
  const uid = requireAuth(request);

  const rewardId = String(request.data?.rewardId ?? "").trim();

  if (!rewardId) {
    throw new HttpsError("invalid-argument", "rewardId required.");
  }

  const rewardRef = db.collection("ad_rewards").doc(`${uid}_${rewardId}`);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const rewardSnap = await tx.get(rewardRef);

    if (rewardSnap.exists) {
      throw new HttpsError(
        "already-exists",
        "This ad reward has already been claimed.",
      );
    }

    const userSnap = await tx.get(userRef);

    if (!userSnap.exists) {
      throw new HttpsError("failed-precondition", "User profile missing.");
    }

    const user = userSnap.data()!;
    const coins = Number(user.sanCoins ?? 0);
    const earned = Number(user.earnedCoins ?? 0);

    tx.update(userRef, {
      sanCoins: coins + AD_REWARD,
      earnedCoins: earned + AD_REWARD,
      adsWatched: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.create(rewardRef, {
      uid,
      reward: AD_REWARD,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    reward: AD_REWARD,
  };
});


/**
 * Purchase document.
 *
 * Server reads the real price from Firestore.
 * Client cannot choose a cheaper price.
 *
 * Purchase is permanently recorded.
 */
export const purchaseResource = onCall(async (request) => {
  const uid = requireAuth(request);

  const resourceId = String(request.data?.resourceId ?? "").trim();

  if (!resourceId) {
    throw new HttpsError("invalid-argument", "resourceId required.");
  }

  const resourceRef = db.collection("academic_vault").doc(resourceId);
  const userRef = db.collection("users").doc(uid);
  const purchaseRef = db
    .collection("purchases")
    .doc(`${uid}_${resourceId}`);

  let result: any = null;

  await db.runTransaction(async (tx) => {
    const resourceSnap = await tx.get(resourceRef);
    const userSnap = await tx.get(userRef);
    const purchaseSnap = await tx.get(purchaseRef);

    if (!resourceSnap.exists) {
      throw new HttpsError("not-found", "Document not found.");
    }

    if (!userSnap.exists) {
      throw new HttpsError("failed-precondition", "User profile missing.");
    }

    if (purchaseSnap.exists) {
      result = {
        success: true,
        alreadyPurchased: true,
        price: Number(purchaseSnap.data()?.price ?? 0),
      };
      return;
    }

    const resource = resourceSnap.data()!;
    const user = userSnap.data()!;

    if (resource.uploaderId === uid) {
      throw new HttpsError(
        "failed-precondition",
        "You already own this document.",
      );
    }

    const price = Number(resource.price ?? 0);

    if (
      !Number.isInteger(price) ||
      price < MIN_PRICE ||
      price > MAX_PRICE
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Invalid document price.",
      );
    }

    const coins = Number(user.sanCoins ?? 0);

    if (coins < price) {
      throw new HttpsError(
        "failed-precondition",
        `Insufficient SanCoins. Required ${price}, available ${coins}.`,
      );
    }

    tx.update(userRef, {
      sanCoins: coins - price,
      spentCoins: admin.firestore.FieldValue.increment(price),
      purchasedKnowledge: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(purchaseRef, {
      buyerId: uid,
      resourceId,
      uploaderId: resource.uploaderId ?? null,
      price,
      currency: "SanCoins",
      permanentlyOwned: true,
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (resource.uploaderId) {
      const uploaderRef = db.collection("users").doc(resource.uploaderId);

      tx.set(
        uploaderRef,
        {
          earnedCoins: admin.firestore.FieldValue.increment(price),
          sanCoins: admin.firestore.FieldValue.increment(price),
          salesCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    result = {
      success: true,
      alreadyPurchased: false,
      price,
    };
  });

  return result;
});


/**
 * Check permanent ownership.
 */
export const checkPurchase = onCall(async (request) => {
  const uid = requireAuth(request);

  const resourceId = String(request.data?.resourceId ?? "").trim();

  if (!resourceId) {
    throw new HttpsError("invalid-argument", "resourceId required.");
  }

  const purchase = await db
    .collection("purchases")
    .doc(`${uid}_${resourceId}`)
    .get();

  return {
    purchased: purchase.exists &&
      purchase.data()?.permanentlyOwned === true,
  };
});


/**
 * Get a short-lived file URL only after purchase.
 *
 * This prevents simply hiding a public Storage URL in Flutter.
 */
export const getPurchasedFileUrl = onCall(async (request) => {
  const uid = requireAuth(request);

  const resourceId = String(request.data?.resourceId ?? "").trim();

  if (!resourceId) {
    throw new HttpsError("invalid-argument", "resourceId required.");
  }

  const purchase = await db
    .collection("purchases")
    .doc(`${uid}_${resourceId}`)
    .get();

  if (!purchase.exists || purchase.data()?.permanentlyOwned !== true) {
    throw new HttpsError(
      "permission-denied",
      "Purchase required.",
    );
  }

  const resource = await db
    .collection("academic_vault")
    .doc(resourceId)
    .get();

  if (!resource.exists) {
    throw new HttpsError("not-found", "Document not found.");
  }

  const data = resource.data()!;
  const storagePath = data.storagePath;

  if (!storagePath) {
    throw new HttpsError(
      "failed-precondition",
      "Document storage path is missing.",
    );
  }

  const [url] = await bucket.file(storagePath).getSignedUrl({
    version: "v4",
    action: "read",
    expires: Date.now() + 10 * 60 * 1000,
  });

  return {
    success: true,
    url,
    expiresInSeconds: 600,
  };
});


/**
 * Automatically initialize new Auth users.
 *
 * The Flutter client can also call initializeSanCoins,
 * but this guarantees the account receives its base 200 coins.
 */
export const createUserWallet = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const ref = db.collection("users").doc(uid);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);

      if (!snap.exists) return;

      const data = snap.data()!;

      if (data.walletInitialized === true) return;

      tx.set(
        ref,
        {
          sanCoins: Number(data.sanCoins ?? NEW_USER_COINS),
          earnedCoins: Number(data.earnedCoins ?? NEW_USER_COINS),
          spentCoins: Number(data.spentCoins ?? 0),
          purchasedKnowledge: Number(data.purchasedKnowledge ?? 0),
          walletInitialized: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    });

    console.log(`Wallet initialized for ${uid}`);
  },
);
