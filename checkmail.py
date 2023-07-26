import smtplib
import logging
from email.mime.text import MIMEText

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

smtp_server = 'mail.dvpsrf.space'
smtp_port = 587  # Используем порт 587 для SMTP Submission

sender = 'user1@dvpsrf.space'
recipient = 'user2@dvpsrf.space'
message_text = "Test email from Python."

msg = MIMEText(message_text)
msg['Subject'] = 'Test Email'
msg['From'] = sender
msg['To'] = recipient

try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()

    # server.login('username', 'password')

    server.sendmail(sender, recipient, msg.as_string())
    logging.info("Test email sent successfully.")
except Exception as e:
    logging.error(f"Error sending test email: {e}")
finally:
    server.quit()

