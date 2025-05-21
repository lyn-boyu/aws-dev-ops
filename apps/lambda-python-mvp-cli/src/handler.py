import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("🔔 Lambda triggered")
    logger.info("Received event: %s", event)
    return {
        "statusCode": 200,
        "body": "Hello from Lambda!"
    }