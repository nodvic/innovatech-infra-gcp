import json
import os
import re
import urllib.request
from google.cloud import logging as cloud_logging


def handle_webhook(request):
    request_json = request.get_json(silent=True)
    if not request_json:
        return {"error": "No JSON payload received"}, 400

    project_id = os.environ.get("GCP_PROJECT_ID")
    firewall_function_url = os.environ.get("FIREWALL_FUNCTION_URL")
    email_function_url = os.environ.get("EMAIL_FUNCTION_URL")
    db_logging_function_url = os.environ.get("DB_LOGGING_FUNCTION_URL")

    incident = request_json.get("incident", {})
    policy_name = incident.get("policy_name", "Unknown Policy")
    state = incident.get("state", "unknown")

    if state != "open":
        return {"status": "ignored", "reason": "incident not open"}, 200

    blocked_ips = []
    logging_client = cloud_logging.Client(project=project_id)

    filter_str = (
        'resource.type="gce_instance" '
        'AND log_name="projects/{}/logs/auth" '
        'AND textPayload:"Failed password"'
    ).format(project_id)

    entries = logging_client.list_entries(
        filter_=filter_str,
        order_by="timestamp desc",
        page_size=50
    )

    ip_pattern = re.compile(r"from\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")

    seen_ips = set()
    for entry in entries:
        payload = entry.payload if isinstance(entry.payload, str) else str(entry.payload)
        match = ip_pattern.search(payload)
        if match:
            ip = match.group(1)
            if ip not in seen_ips:
                seen_ips.add(ip)

    for ip in seen_ips:
        firewall_payload = json.dumps({"source_ip": ip}).encode("utf-8")
        firewall_req = urllib.request.Request(
            firewall_function_url,
            data=firewall_payload,
            headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(firewall_req)
            blocked_ips.append(ip)
        except Exception:
            pass

    if email_function_url and blocked_ips:
        email_payload = json.dumps({
            "subject": "SOAR Alert: SSH Brute Force Detected",
            "body": "Blocked IPs: {}. Policy: {}".format(
                ", ".join(blocked_ips), policy_name
            )
        }).encode("utf-8")
        email_req = urllib.request.Request(
            email_function_url,
            data=email_payload,
            headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(email_req)
        except Exception:
            pass

    if db_logging_function_url and blocked_ips:
        db_payload = json.dumps({
            "event_type": "ssh_brute_force",
            "event_data": {
                "blocked_ips": blocked_ips,
                "policy_name": policy_name
            }
        }).encode("utf-8")
        db_req = urllib.request.Request(
            db_logging_function_url,
            data=db_payload,
            headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(db_req)
        except Exception:
            pass

    return {"status": "processed", "blocked_ips": blocked_ips}, 200
