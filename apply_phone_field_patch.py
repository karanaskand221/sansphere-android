p = "lib/screens/auth/register_screen.dart"
with open(p, "r", encoding="utf-8") as f:
    c = f.read()

old = """          'sanCoins': 0,
          'referralCode': myReferralCode,
        });"""

new = """          'sanCoins': 0,
          'referralCode': myReferralCode,
          'phoneNumber': '',
          'showPhoneNumber': false,
        });"""

if new not in c and old in c:
    c = c.replace(old, new, 1)
    with open(p, "w", encoding="utf-8") as f:
        f.write(c)
    print("[ok] added phoneNumber/showPhoneNumber defaults to registration")
else:
    print("[skip] already present or anchor not found")
