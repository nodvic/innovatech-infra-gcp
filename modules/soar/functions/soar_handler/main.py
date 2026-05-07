import os
import json
import sqlalchemy
from google.cloud import compute_v1

def handle_soar_event(request):
    request_json = request.get_json(silent=True)
    if not request_json:
        return {"status": "error"}, 400

    action = request_json.get("action")
    user_email = request_json.get("user_email")
    vdi_name = request_json.get("vdi_name")
    project_id = os.environ.get("GCP_PROJECT_ID")
    zone = os.environ.get("GCP_ZONE")

    client = compute_v1.InstancesClient()
    policy = client.get_iam_policy(project=project_id, zone=zone, resource=vdi_name)
    
    member = f"user:{user_email}"
    role = "roles/iap.tunnelResourceAccessor"

    if action == "assign":
        binding_exists = False
        for b in policy.bindings:
            if b.role == role:
                b.members.append(member)
                binding_exists = True
                break
        if not binding_exists:
            policy.bindings.append({"role": role, "members": [member]})
    elif action == "revoke":
        for b in policy.bindings:
            if b.role == role and member in b.members:
                b.members.remove(member)

    client.set_iam_policy(
        project=project_id, 
        zone=zone, 
        resource=vdi_name, 
        zone_set_policy_request_resource={"policy": policy}
    )

    db_user = os.environ.get("DB_USER")
    db_pass = os.environ.get("DB_PASSWORD")
    db_name = os.environ.get("DB_NAME")
    db_host = os.environ.get("DB_HOST")

    pool = sqlalchemy.create_engine(
        sqlalchemy.engine.url.URL.create(
            drivername="mysql+pymysql",
            username=db_user,
            password=db_pass,
            host=db_host,
            port=3306,
            database=db_name,
        )
    )

    event_data = json.dumps({
        "action": action,
        "user": user_email,
        "vdi": vdi_name
    })

    with pool.connect() as conn:
        conn.execute(sqlalchemy.text(
            "CREATE TABLE IF NOT EXISTS vdi_logs ("
            "  id INT AUTO_INCREMENT PRIMARY KEY,"
            "  action VARCHAR(50) NOT NULL,"
            "  event_data TEXT,"
            "  created_at DATETIME NOT NULL"
            ")"
        ))
        conn.execute(
            sqlalchemy.text(
                "INSERT INTO vdi_logs (action, event_data, created_at) "
                "VALUES (:action, :event_data, NOW())"
            ),
            {"action": action, "event_data": event_data}
        )
        conn.commit()

    return {"status": "success", "action": action, "user": user_email}, 200