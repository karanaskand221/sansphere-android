import re
import os

main_path = "lib/main.dart"

with open(main_path, "r") as f:
    content = f.read()

# This structure dynamically looks at the browser window URL to extract the Codespace base name!
dynamic_emulator_block = """
      // Dynamic Codespace Emulator Router
      import 'package:html/html.dart' as html_parser; // If needed, but standard window detection works:
      import 'dart:html' as html;
      
      String currentUrl = html.window.location.href;
      String host = "localhost";
      
      // If running inside a GitHub Codespace proxy web URL
      if (currentUrl.contains("app.github.dev")) {
        // Extract the unique base subdomain from the window address bar
        final Uri uri = Uri.parse(currentUrl);
        final String baseHost = uri.host.replaceFirst("-5000.", "-");
        
        FirebaseFirestore.instance.useFirestoreEmulator(baseHost.replaceFirst("-", "-8080."), 443, sslEnabled: true);
        FirebaseAuth.instance.useAuthEmulator(baseHost.replaceFirst("-", "-9099."), 443);
        FirebaseStorage.instance.useStorageEmulator(baseHost.replaceFirst("-", "-9199."), 443);
        print("Connected to proxy cloud emulators successfully.");
      } else {
        // Fallback for desktop/local environments
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      }
"""

# Clean out any old static localhost emulator references we added
content = re.sub(r'// Connect to local Firebase Emulators[\s\S]*?FirebaseStorage\.instance\.useStorageEmulator\(host, 9199\);', '', content)

# Inject our dynamic cloud network routing code right under the web initialization block
target_string = "await Firebase.initializeApp(options: webFirebaseOptions);"
if "currentUrl = html.window.location.href" not in content:
    content = content.replace(target_string, target_string + dynamic_emulator_block)
    with open(main_path, "w") as f:
        f.write(content)
    print("🚀 Dynamic cloud emulator networking block successfully configured!")
else:
    print("Block already present.")
