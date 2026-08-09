p = "lib/screens/resource_detail_screen.dart"
with open(p, "r", encoding="utf-8") as f:
    c = f.read()

if "chat_list_screen.dart" not in c:
    c = c.replace(
        "import '../models/academic_resource.dart';",
        "import '../models/academic_resource.dart';\nimport 'chat_list_screen.dart';",
        1
    )
    print("[ok] added chat_list_screen.dart import")
else:
    print("[skip] import already present")

old = """            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isProcessing ? null : _handleAccessTap,
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _isPurchased ? "Open Document" : "Unlock & Open",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),"""

new = """            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isProcessing ? null : _handleAccessTap,
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _isPurchased ? "Open Document" : "Unlock & Open",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
                label: const Text("Message Seller", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => startChatWithUser(
                  context,
                  peerUid: resource.authorUid,
                  peerName: resource.authorName,
                  docTitle: resource.title,
                  docId: resource.id,
                ),
              ),
            ),"""

if new not in c and old in c:
    c = c.replace(old, new, 1)
    with open(p, "w", encoding="utf-8") as f:
        f.write(c)
    print("[ok] added Message Seller button")
else:
    print("[skip] button already present or anchor not found")
