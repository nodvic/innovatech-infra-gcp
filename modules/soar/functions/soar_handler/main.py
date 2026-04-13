import os
import time
import re
import json
import sqlalchemy
from google.cloud import logging as cloud_logging
from google.cloud import compute_v1


def handle_soar_event(request):
    """Geconsolideerde SOAR handler: leest logs, blokkeert IP en logt naar DB."""
    project_id = os.environ.get("GCP_PROJECT_ID")
    network = os.environ.get("NETWORK_NAME")

    # 1. IP-adres ophalen uit de auth logs
    logging_client = cloud_logging.Client(project=project_id)
    filter_str = (
        'resource.type="gce_instance" '
        'AND log_name="projects/{}/logs/auth" '
        'AND textPayload:"Failed password"'
    ).format(project_id)

    entries = logging_client.list_entries(
        filter_=filter_str,
        order_by="timestamp desc",
        page_size=1
    )

    source_ip = None
    ip_pattern = re.compile(r"from\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")

    for entry in entries:
        payload = entry.payload if isinstance(entry.payload, str) else str(entry.payload)
        match = ip_pattern.search(payload)
        if match:
            source_ip = match.group(1)
            break

    if not source_ip:
        return {"status": "no ip found"}, 200

    # 2. Firewall regel aanmaken om het IP te blokkeren
    fw_client = compute_v1.FirewallsClient()
    timestamp = int(time.time())
    rule_name = f"soar-block-{source_ip.replace('.', '-')}-{timestamp}"

    firewall_rule = compute_v1.Firewall(
        name=rule_name,
        network=f"projects/{project_id}/global/networks/{network}",
        direction="INGRESS",
        priority=100,
        source_ranges=[f"{source_ip}/32"],
        denied=[compute_v1.Denied(I_p_protocol="all")],
        description="Automatische SSH blokkade door SOAR"
    )

    fw_client.insert(project=project_id, firewall_resource=firewall_rule).result()

    # 3. Loggen naar Database
    db_user = os.environ.get("DB_USER")
    db_pass = os.environ.get("DB_PASSWORD")
    db_name = os.environ.get("DB_NAME")
    connection_name = os.environ.get("DB_CONNECTION_NAME")

    pool = sqlalchemy.create_engine(
        sqlalchemy.engine.url.URL.create(
            drivername="mysql+pymysql",
            username=db_user,
            password=db_pass,
            database=db_name,
            query={"unix_socket": f"/cloudsql/{connection_name}"}
        )
    )

    event_data = json.dumps({
        "blocked_ip": source_ip,
        "rule_name": rule_name,
        "action": "firewall_block"
    })

    with pool.connect() as conn:
        conn.execute(
            sqlalchemy.text(
                "INSERT INTO soar_logs (event_type, event_data, created_at) "
                "VALUES (:event_type, :event_data, NOW())"
            ),
            {"event_type": "ssh_brute_force", "event_data": event_data}
        )
        conn.commit()

    return {"status": "blocked", "ip": source_ip, "rule": rule_name}, 200
