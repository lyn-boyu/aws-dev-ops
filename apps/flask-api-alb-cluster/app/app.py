from flask import Flask, jsonify, request
import logging
import os
import socket

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app = Flask(__name__)
logger.info("✅ Flask app loaded")

# Health check endpoint for ALB
@app.route("/health")
def health():
    logger.info("🩺 /health check called")
    return "ok", 200

# Public API endpoint
@app.route("/api/hello")
def hello():
    logger.info("🙋 /api/hello called")
    user = request.args.get("user") 
    return jsonify(message=f"Hello, {user}!")

# Backend node identifier (for ALB demo)
@app.route("/api/node")
def node_info():
    hostname = socket.gethostname()
    logger.info(f"📦 /api/node called on node {hostname}")
    return jsonify(node=hostname)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
