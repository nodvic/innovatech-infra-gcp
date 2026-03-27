import json
import os
import urllib.request


def handle_webhook(request):
    request_json = request.get_json(silent=True)

    webhook_url = os.environ.get("WEBHOOK_URL")
    message = request_json.get("message", "Innovatech SOAR alert triggered")

    payload = json.dumps({"text": message}).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    urllib.request.urlopen(req)

    return {"status": "webhook_sent"}, 200
