import os
import json
import logging
import sqlalchemy
from google.cloud import compute_v1
from google.cloud.compute_v1.types import ZoneSetPolicyRequest, Binding

logging.basicConfig(level=logging.INFO)


def handle_soar_event(request):
    """
    SOAR handler voor VDI onboarding/offboarding.
    Verwacht JSON body: { "action": "assign"|"revoke", "user_email": "...", "vdi_name": "..." }
    """
    request_json = request.get_json(silent=True)
    if not request_json:
        return {"status": "error", "message": "No JSON body provided"}, 400

    action     = request_json.get("action")
    user_email = request_json.get("user_email")
    vdi_name   = request_json.get("vdi_name")

    if not all([action, user_email, vdi_name]):
        return {"status": "error", "message": "Missing required fields: action, user_email, vdi_name"}, 400

    if action not in ("assign", "revoke"):
        return {"status": "error", "message": f"Unknown action: {action}. Use 'assign' or 'revoke'."}, 400

    project_id = os.environ["GCP_PROJECT_ID"]
    zone       = os.environ["GCP_ZONE"]
    role       = "roles/iap.tunnelResourceAccessor"
    member     = f"user:{user_email}"

    try:
        instances_client = compute_v1.InstancesClient()

        policy = instances_client.get_iam_policy(
            project=project_id,
            zone=zone,
            resource=vdi_name,
        )

        if action == "assign":
            binding_exists = False
            for b in policy.bindings:
                if b.role == role:
                    if member not in b.members:
                        b.members.append(member)
                    binding_exists = True
                    break
            if not binding_exists:
                policy.bindings.append(Binding(role=role, members=[member]))

        elif action == "revoke":
            for b in policy.bindings:
                if b.role == role and member in b.members:
                    b.members.remove(member)

        instances_client.set_iam_policy(
            project=project_id,
            zone=zone,
            resource=vdi_name,
            zone_set_policy_request_resource=ZoneSetPolicyRequest(policy=policy),
        )
        logging.info(f"IAM {action} geslaagd: {user_email} op {vdi_name}")

    except Exception as e:
        logging.error(f"Compute IAM fout: {e}")
        return {"status": "error", "message": f"Compute IAM fout: {str(e)}"}, 500

    try:
        engine = sqlalchemy.create_engine(
            sqlalchemy.engine.url.URL.create(
                drivername="mysql+pymysql",
                username=os.environ["DB_USER"],
                password=os.environ["DB_PASSWORD"],
                host=os.environ["DB_HOST"],
                port=3306,
                database=os.environ["DB_NAME"],
            ),
            pool_pre_ping=True,
        )

        event_data = json.dumps({
            "action":    action,
            "user":      user_email,
            "vdi":       vdi_name,
        })

        with engine.connect() as conn:
            conn.execute(sqlalchemy.text(
                "CREATE TABLE IF NOT EXISTS vdi_logs ("
                "  id INT AUTO_INCREMENT PRIMARY KEY,"
                "  action VARCHAR(50) NOT NULL,"
                "  event_data TEXT,"
                "  created_at DATETIME NOT NULL DEFAULT NOW()"
                ")"
            ))
            conn.execute(
                sqlalchemy.text(
                    "INSERT INTO vdi_logs (action, event_data, created_at) "
                    "VALUES (:action, :event_data, NOW())"
                ),
                {"action": action, "event_data": event_data},
            )
            conn.commit()
        logging.info("Actie gelogd naar Cloud SQL.")

    except Exception as e:
        logging.error(f"Database fout: {e}")
        return {
            "status":  "partial_success",
            "action":  action,
            "user":    user_email,
            "warning": f"IAM actie geslaagd maar DB log mislukt: {str(e)}"
        }, 207

    return {"status": "success", "action": action, "user": user_email}, 200