import json
import os
import time
from decimal import Decimal
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])
#API_KEY = os.environ.get("API_KEY", "")

ssm = boto3.client("ssm")
_api_key_cache = None

def to_decimal(value):
    if value is None:
        return None
    return Decimal(str(value))

def get_api_key():
    global _api_key_cache
    if _api_key_cache is None:
        param_name = os.environ["API_KEY"]  # "/ruuvi-boat/ingest_api_key"
        resp = ssm.get_parameter(Name=param_name, WithDecryption=True)
        _api_key_cache = resp["Parameter"]["Value"]
    return _api_key_cache


def lambda_handler(event, context):
    try:
        headers = event.get("headers") or {}
        incoming = headers.get("x-api-key") or headers.get("X-Api-Key") or ""

        if incoming != get_api_key():
            return {
                "statusCode": 401,
                "body": json.dumps({"error": "unauthorized"}),
            }
        body = json.loads(event.get("body") or "{}")

        mac = body.get("mac")
        name = body.get("name", "unknown")
        temperature = body.get("temperature")
        humidity = body.get("humidity")
        pressure = body.get("pressure")
        battery = body.get("battery")
        timestamp = body.get("timestamp") or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        if not mac:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "mac is required"})
            }

        item = {
            "pk": f"SENSOR#{mac}",
            "sk": f"TS#{timestamp}",
            "mac": mac,
            "name": name,
            "temperature": to_decimal(temperature),
            "humidity": to_decimal(humidity),
            "pressure": to_decimal(pressure),
            "battery": to_decimal(battery),
            "timestamp": timestamp,
            "ttl": int(time.time()) + 60 * 60 * 24 * 90  # 90 dní
        }

        table.put_item(Item=item)

        return {
            "statusCode": 200,
            "body": json.dumps({"status": "ok"})
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }