import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


def handle_email(request):
    request_json = request.get_json(silent=True)

    subject = request_json.get("subject", "Innovatech Security Alert")
    body = request_json.get("body", "An alert has been triggered.")

    msg = MIMEMultipart()
    msg["From"] = os.environ.get("SENDER_EMAIL")
    msg["To"] = os.environ.get("ALERT_EMAIL")
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "html"))

    server = smtplib.SMTP(
        os.environ.get("SMTP_SERVER"),
        int(os.environ.get("SMTP_PORT"))
    )
    server.starttls()
    server.sendmail(msg["From"], msg["To"], msg.as_string())
    server.quit()

    return {"status": "email_sent", "to": msg["To"]}, 200
