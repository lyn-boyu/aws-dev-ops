import json
import logging
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Optional: Generate a pseudo "instance ID" once per cold start
INSTANCE_ID = str(uuid.uuid4())

def lambda_handler(event, context):
    logger.info("Lambda invoked via ALB.")
    logger.info(f"Event: {json.dumps(event)}")

    response = {
        "message": "Hello from ALB-routed Lambda!",
        "function_name": context.function_name,
        "request_id": context.aws_request_id,
        "instance_id": INSTANCE_ID
    }

    logger.info(f"Response: {response}")
    return {
        "statusCode": 200,
        "statusDescription": "200 OK",
        "isBase64Encoded": False,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Hello from ALB-routed Lambda!",
            "function_name": context.function_name,
            "request_id": context.aws_request_id,
            "instance_id": INSTANCE_ID
        })
    }
