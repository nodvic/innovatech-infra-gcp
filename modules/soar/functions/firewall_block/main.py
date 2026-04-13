import os
import time
from google.cloud import compute_v1

def handle_firewall_block(request):
    request_json = request.get_json(silent=True)
    if not request_json:
        return {"error": "Geen JSON payload ontvangen"}, 400

    project = os.environ.get("GCP_PROJECT_ID")
    network = os.environ.get("NETWORK_NAME")
    source_ip = request_json.get("source_ip")
    
    if not source_ip:
        return {"error": "Ontbrekende source_ip in payload"}, 400

    # Unieke naam genereren met timestamp voor de tijdelijke blokkade
    timestamp = int(time.time())
    rule_name = f"soar-block-{source_ip.replace('.', '-')}-{timestamp}"

    client = compute_v1.FirewallsClient()

    firewall_rule = compute_v1.Firewall()
    firewall_rule.name = rule_name
    firewall_rule.network = f"projects/{project}/global/networks/{network}"
    firewall_rule.direction = "INGRESS"
    firewall_rule.priority = 100
    firewall_rule.source_ranges = [f"{source_ip}/32"]
    firewall_rule.denied = [compute_v1.Denied(I_p_protocol="all")]
    firewall_rule.description = "Tijdelijke blokkade door SOAR. Verloopt na 10 minuten."

    operation = client.insert(project=project, firewall_resource=firewall_rule)
    operation.result()

    return {"status": "blocked", "ip": source_ip, "rule": rule_name}, 200