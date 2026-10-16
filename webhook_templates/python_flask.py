"""
=========================================================================
WEBHOOK SERVER MAONEAUTO - PYTHON (FLASK)
=========================================================================

PANDUAN PENGGUNAAN:
1. Install Flask:
   pip install flask
2. Jalankan:
   python app.py
3. URL webhook: http://IP_SERVER:5000/webhook
=========================================================================
"""
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.get_json(force=True) or {}
    sender = data.get('sender', 'Pelanggan')
    message = data.get('message', '').strip()
    clean_msg = message.lower()

    if clean_msg in ['ping', 'tes', 'test']:
        reply = "🏓 Pong! Webhook Python Flask aktif."
    elif 'harga' in clean_msg or 'biaya' in clean_msg:
        reply = f"Halo kak {sender}! Harga layanan kami mulai dari Rp 50.000,-."
    elif 'admin' in clean_msg or 'cs' in clean_msg:
        reply = "Pesan Anda telah diteruskan ke Customer Support kami."
    else:
        reply = f"Halo kak! Pesan '{message}' telah kami terima di server."

    return jsonify({"reply": reply})

@app.route('/webhook', methods=['GET'])
def ping():
    return jsonify({"status": "online", "service": "MaoneAuto Python Webhook"})

if __name__ == '__main__':
    print("🚀 Webhook server Python berjalan di port 5000...")
    app.run(host='0.0.0.0', port=5000)
