#!/usr/bin/env python3
import asyncio
import json
import os
import urllib.request
from datetime import datetime, timezone
from ruuvitag_sensor.ruuvi import RuuviTagSensor

API_URL = os.environ.get(
    "API_URL",
    "https://wi2pephaj4.execute-api.eu-west-1.amazonaws.com/ingest"
)

API_KEY = os.environ.get("API_KEY", "")

MACS = [
    "D2:E4:35:86:55:22",
    "E2:78:AD:AB:77:8F",
]

NAMES = {
    "D2:E4:35:86:55:22": "LN-Inside",
    "E2:78:AD:AB:77:8F": "LN-Outside",
}

SEND_INTERVAL = int(os.environ.get("SEND_INTERVAL", "60"))
last_sent = {mac: 0 for mac in MACS}


def send_to_aws(mac: str, name: str, data: dict) -> bool:
    payload = {
        "mac": mac,
        "name": name,
        "temperature": data.get("temperature"),
        "humidity": data.get("humidity"),
        "pressure": data.get("pressure"),
        "battery": data.get("battery"),
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    body = json.dumps(payload).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "x-api-key": API_KEY,
    }
    req = urllib.request.Request(
        API_URL,
        data=body,
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"  → AWS OK ({resp.status})", flush=True)
            return True
    except Exception as e:
        print(f"  → AWS ERROR: {e}", flush=True)
        return False


async def main():
    print(f"Ruuvi collector started (every {SEND_INTERVAL}s → AWS)", flush=True)

    async for found_data in RuuviTagSensor.get_data_async(macs=MACS):
        mac = found_data[0]
        data = found_data[1]
        now = datetime.now(timezone.utc).timestamp()

        if now - last_sent[mac] < SEND_INTERVAL:
            continue

        last_sent[mac] = now
        name = NAMES.get(mac, mac)
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        print(f"[{ts}] {name}", flush=True)
        print(
            f"  Temp: {data.get('temperature')} °C | "
            f"Humidity: {data.get('humidity')} % | "
            f"Battery: {data.get('battery')} mV",
            flush=True,
        )
        send_to_aws(mac, name, data)
        print("-" * 50, flush=True)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Stopped.", flush=True)