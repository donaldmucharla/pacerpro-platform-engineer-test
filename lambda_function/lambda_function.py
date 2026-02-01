import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

INSTANCE_ID = os.environ["EC2_INSTANCE_ID"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    try:
        logger.info("Received alert")
        logger.info(json.dumps(event))

        ec2.reboot_instances(
            InstanceIds=[INSTANCE_ID]
        )

        message = f"EC2 instance {INSTANCE_ID} was restarted due to high latency alert."

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="EC2 Restart Triggered",
            Message=message
        )

        logger.info(message)

        return {
            "statusCode": 200,
            "body": json.dumps({"message": message})
        }

    except Exception as e:
        logger.error(str(e))
        raise
