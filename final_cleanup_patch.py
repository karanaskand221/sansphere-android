import re

def read(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def report(label, ok):
    print(f"  [{'ok' if ok else 'skip'}] {label}")

# ---------------- pubspec.yaml ----------------
print("pubspec.yaml:")
p = "pubspec.yaml"
c = read(p)
changed = False

if "flutter_lints:" not in c:
    c = c.replace(
        "  flutter_test:\n    sdk: flutter\n",
        "  flutter_test:\n    sdk: flutter\n  flutter_lints: ^4.0.0\n",
        1
    )
    changed = True
report("add flutter_lints dependency", "flutter_lints:" in c)

new_c = re.sub(r'\n  assets:\n(\s*#.*\n)*', '\n', c)
if new_c != c:
    c = new_c
    changed = True
    report("remove empty 'assets:' key", True)
else:
    report("remove empty 'assets:' key", False)

if changed:
    write(p, c)

# ---------------- global_state.dart ----------------
print("\nlib/global_state.dart:")
p = "lib/global_state.dart"
c = read(p)
new_c = c.replace("import 'package:flutter/foundation.dart';\n", "")
report("remove unused foundation.dart import", new_c != c)
if new_c != c:
    write(p, new_c)

# ---------------- main.dart ----------------
print("\nlib/main.dart:")
p = "lib/main.dart"
c = read(p)
new_c = c.replace("import 'global_state.dart';\n", "")
report("remove unused global_state.dart import", new_c != c)
if new_c != c:
    write(p, new_c)

# ---------------- delete orphaned files ----------------
print("\nOrphaned files:")
import os
if os.path.exists("lib/screens/main_dashboard.dart"):
    os.remove("lib/screens/main_dashboard.dart")
    print("  [ok] deleted lib/screens/main_dashboard.dart")
else:
    print("  [skip] lib/screens/main_dashboard.dart already gone")

# ---------------- marketplace_feed.dart ----------------
print("\nlib/screens/marketplace_feed.dart:")
p = "lib/screens/marketplace_feed.dart"
c = read(p)
new_c = re.sub(r"import '\.\./models/academic_resource\.dart';[^\n]*\n", "", c)
report("remove unused academic_resource.dart import", new_c != c)
if new_c != c:
    c = new_c
    write(p, c)

# ---------------- profile_screen.dart ----------------
print("\nlib/screens/profile_screen.dart:")
p = "lib/screens/profile_screen.dart"
c = read(p)
new_c = c.replace("import 'dart:math';\n", "")
report("remove unused dart:math import", new_c != c)
if new_c != c:
    write(p, new_c)

# ---------------- withOpacity -> withValues(alpha:) across lib/ ----------------
print("\nwithOpacity fixes across lib/:")
for root, dirs, files in os.walk("lib"):
    for fname in files:
        if fname.endswith(".dart"):
            fpath = os.path.join(root, fname)
            fc = read(fpath)
            new_fc = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', fc)
            if new_fc != fc:
                write(fpath, new_fc)
                print(f"  [ok] fixed withOpacity in {fpath}")

# ---------------- DropdownButtonFormField value -> initialValue ----------------
print("\nDropdown initialValue fixes:")
for fpath, var in [
    ("lib/screens/support_screen.dart", "_selectedTopic"),
    ("lib/screens/upload_resource_screen.dart", "_selectedCollege"),
    ("lib/screens/upload_resource_screen.dart", "_selectedType"),
]:
    c = read(fpath)
    old = f"                value: {var},"
    new = f"                initialValue: {var},"
    if new not in c and old in c:
        c = c.replace(old, new, 1)
        write(fpath, c)
        print(f"  [ok] {fpath} -> initialValue: {var}")
    else:
        print(f"  [skip] {fpath} -> {var} already fixed or not found")

# ---------------- test/widget_test.dart ----------------
print("\ntest/widget_test.dart:")
