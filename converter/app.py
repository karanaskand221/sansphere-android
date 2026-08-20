import os
import subprocess
import tempfile
from flask import Flask, request, send_file, jsonify

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify({"status": "ok"})

@app.post("/convert")
def convert():
    uploaded = request.files.get("file")
    if not uploaded or not uploaded.filename:
        return jsonify({"error": "file is required"}), 400

    with tempfile.TemporaryDirectory() as tmp:
        source = os.path.join(tmp, uploaded.filename)
        uploaded.save(source)

        result = subprocess.run(
            [
                "libreoffice",
                "--headless",
                "--convert-to", "pdf",
                "--outdir", tmp,
                source,
            ],
            capture_output=True,
            text=True,
            timeout=240,
        )

        if result.returncode != 0:
            return jsonify({
                "error": "LibreOffice conversion failed",
                "details": result.stderr[-2000:],
            }), 500

        pdf_name = os.path.splitext(os.path.basename(uploaded.filename))[0] + ".pdf"
        pdf_path = os.path.join(tmp, pdf_name)

        if not os.path.exists(pdf_path):
            return jsonify({
                "error": "PDF was not produced",
                "details": result.stdout[-2000:],
            }), 500

        return send_file(
            pdf_path,
            mimetype="application/pdf",
            as_attachment=False,
            download_name=pdf_name,
        )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
