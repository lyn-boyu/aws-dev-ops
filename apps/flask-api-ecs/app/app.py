from flask import Flask
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

logger.info("✅ Flask app loaded")


@app.route("/health")
def health():
    logger.info("✅ health check endpoint called")
    return "ok", 200

@app.route("/")
def index():
    logger.info("✅ index endpoint called")
    return "Hello from ECS!", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
