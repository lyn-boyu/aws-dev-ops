import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("🔔 Lambda triggered")
    logger.info(f"Received event: {json.dumps(event)}")

    name = None

    try:
        if "body" in event:
            body = event["body"]
            logger.info(f"Raw body: {body}")

            if isinstance(body, str):
                body = json.loads(body)
                logger.info(f"Parsed JSON body: {body}")

            name = body.get("name")
        else:
            name = event.get("name")

        logger.info(f"Extracted name: {name}")

    except Exception as e:
        logger.error(f"❌ Error parsing input: {str(e)}")
        return {
            "statusCode": 400,
            "body": f"Invalid input: {str(e)}"
        }

    response = {
        "statusCode": 200,
        "body": f"Hello, {name or 'anonymous'}!"
    }

    logger.info(f"✅ Returning response: {response}")
    return response
