import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']

    print(f"Stopping EC2 instance: {instance_id}")
    ec2.stop_instances(InstanceIds=[instance_id])

    return {
        'statusCode': 200,
        'body': f"Instance {instance_id} is stopping."
    }
