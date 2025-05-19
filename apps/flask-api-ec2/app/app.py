from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return "Hello, Flask on EC2!"

# ✅ Health check endpoint
@app.route("/health")
def health_check():
    return jsonify(status="ok"), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)