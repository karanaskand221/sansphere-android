with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

changed = False

# Add a named vault Firestore instance alongside _userFirestore
old_field = "final _userFirestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'sansphere');"
new_field = old_field + "\n  final _vaultFirestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'sanvault');"
if new_field not in content and old_field in content:
    content = content.replace(old_field, new_field, 1)
    changed = True
    print("[ok] added _vaultFirestore field")
else:
    print("[skip] _vaultFirestore field already present or anchor not found")

# Point the main feed query at sanvault
old_q = "Query query = FirebaseFirestore.instance\n        .collection('academic_vault')"
new_q = "Query query = _vaultFirestore\n        .collection('academic_vault')"
if old_q in content:
    content = content.replace(old_q, new_q, 1)
    changed = True
    print("[ok] fixed feed query to use sanvault")
else:
    print("[skip] feed query anchor not found (may already be fixed)")

# Point the open-via-link/search query at sanvault
old_s = "final query = await FirebaseFirestore.instance\n        .collection('academic_vault')"
new_s = "final query = await _vaultFirestore\n        .collection('academic_vault')"
if old_s in content:
    content = content.replace(old_s, new_s, 1)
    changed = True
    print("[ok] fixed open-via-link query to use sanvault")
else:
    print("[skip] open-via-link query anchor not found (may already be fixed)")

if changed:
    with open("lib/main.dart", "w", encoding="utf-8") as f:
        f.write(content)
