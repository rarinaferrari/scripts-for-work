import smtplib
from email.mime.text import MIMEText

smtp_server = 'mail.dvpsrf.space'
smtp_port = 25

from_email = 'user1@dvpsrf.space'
to_email = 'user2@dvpsrf.space'

subject = 'Test Email'
body = 'This is a test email sent from Python.'

msg = MIMEText(body)
msg['Subject'] = subject
msg['From'] = from_email
msg['To'] = to_email

try:
    smtp = smtplib.SMTP(smtp_server, smtp_port)
    smtp.sendmail(from_email, to_email, msg.as_string())
    smtp.quit()

    print("Test email sent successfully.")
except Exception as e:
    print("Error sending test email:", e)
