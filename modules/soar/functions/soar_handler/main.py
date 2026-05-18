import os
import json
import sqlalchemy
from google.cloud import iap_v1

def handle_soar_event(request):
    request_json = request.get_json(silent=True)
    if not request_json:
        return {"status": "error", "message": "Geen JSON gevonden"}, 400

    action = request_json.get("action")
    user_email = request_json.get("user_email")
    vdi_name = request_json.get("vdi_name")

    if not all([action, user_email, vdi_name]):
        return {"status": "error", "message": "Missing required fields: action, user_email, vdi_name"}, 400

    project_id = os.environ.get("GCP_PROJECT_ID")
    zone = os.environ.get("GCP_ZONE")

    client = iap_v1.IdentityAwareProxyAdminServiceClient()
    resource = f"projects/{project_id}/iap_tunnel/zones/{zone}/instances/{vdi_name}"
    
    try:
        policy = client.get_iam_policy(resource=resource)
        member = f"user:{user_email}"
        role = "roles/iap.tunnelResourceAccessor"

        if action == "assign":
            binding_exists = False
            for b in policy.bindings:
                if b.role == role:
                    if member not in b.members:
                        b.members.append(member)
                    binding_exists = True
                    break
            if not binding_exists:
                policy.bindings.append({"role": role, "members": [member]})
        
        elif action == "revoke":
            for b in policy.bindings:
                if b.role == role and member in b.members:
                    b.members.remove(member)

        client.set_iam_policy(resource=resource, policy=policy)

    except Exception as e:
        return {"status": "error", "message": f"IAP IAM fout: {str(e)}"}, 500

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

    try:
        with pool.connect() as conn:
            conn.execute(sqlalchemy.text(
                "CREATE TABLE IF NOT EXISTS vdi_logs ("
                "  id INT AUTO_INCREMENT PRIMARY KEY,"
                "  action VARCHAR(50) NOT NULL,"
                "  event_data TEXT,"
                "  created_at DATETIME NOT NULL DEFAULT NOW()"
                ")"
            ))
            event_data = json.dumps({"user": user_email, "vdi": vdi_name})
            conn.execute(
                sqlalchemy.text(
                    "INSERT INTO vdi_logs (action, event_data, created_at) "
                    "VALUES (:action, :event_data, NOW())"
                ),
                {"action": action, "event_data": event_data}
            )
            conn.commit()
    except Exception as e:
        return {
            "status": "partial_success", 
            "action": action, 
            "user": user_email, 
            "warning": f"IAM actie geslaagd maar DB log mislukt: {str(e)}"
        }, 207

    return {"status": "success", "action": action, "user": user_email}, 200