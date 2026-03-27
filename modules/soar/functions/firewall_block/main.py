import os
from google.cloud import compute_v1


def handle_firewall_block(request):
    request_json = request.get_json(silent=True)

    project = os.environ.get("GCP_PROJECT_ID")
    network = os.environ.get("NETWORK_NAME")
    source_ip = request_json.get("source_ip")
    rule_name = f"innovatech-soar-block-{source_ip.replace('.', '-')}"

    client = compute_v1.FirewallsClient()

    firewall_rule = compute_v1.Firewall()
    firewall_rule.name = rule_name
    firewall_rule.network = f"projects/{project}/global/networks/{network}"
    firewall_rule.direction = "INGRESS"
    firewall_rule.priority = 100
    firewall_rule.source_ranges = [f"{source_ip}/32"]
    firewall_rule.denied = [compute_v1.Denied(I_p_protocol="all")]

    operation = client.insert(project=project, firewall_resource=firewall_rule)
    operation.result()

    return {"status": "blocked", "ip": source_ip, "rule": rule_name}, 200
