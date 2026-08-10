import json
import os
from decimal import Decimal
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

SENSORS = [
    "D2:E4:35:86:55:22",  # LN-Inside
    "E2:78:AD:AB:77:8F",  # LN-Outside
]


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError


def lambda_handler(event, context):
    results = []

    try:
        for mac in SENSORS:
            resp = table.query(
                KeyConditionExpression=Key("pk").eq(f"SENSOR#{mac}"),
                ScanIndexForward=False,  # nejnovější první
                Limit=1,
            )
            items = resp.get("Items", [])
            if items:
                results.append(items[0])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"sensors": results}, default=decimal_default),
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": str(e)}),
        }