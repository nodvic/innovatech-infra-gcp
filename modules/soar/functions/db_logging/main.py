import os
import json
import sqlalchemy


def handle_db_logging(request):
    request_json = request.get_json(silent=True)

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

    event_type = request_json.get("event_type", "unknown")
    event_data = json.dumps(request_json.get("event_data", {}))

    with pool.connect() as conn:
        conn.execute(
            sqlalchemy.text(
                "INSERT INTO soar_logs (event_type, event_data, created_at) "
                "VALUES (:event_type, :event_data, NOW())"
            ),
            {"event_type": event_type, "event_data": event_data}
        )
        conn.commit()

    return {"status": "logged", "event_type": event_type}, 200
