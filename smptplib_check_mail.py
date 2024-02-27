
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


email_host = '<server>'
email_port = 587
email_user = 'taiga-sender@obit.local'
email_password = '<password>'


sender_email = 'taiga-sender@local'
receiver_email = 'stankevich@obit.ru'

subject = 'Taiga Test'
body = 'Hey from Taiga'

message = MIMEMultipart()
message['From'] = sender_email
message['To'] = receiver_email
message['Subject'] = subject

message.attach(MIMEText(body, 'plain'))


try:
    with smtplib.SMTP(email_host, email_port) as server:
        server.starttls()
        server.login(email_user, email_password)
        text = message.as_string()
        server.sendmail(sender_email, receiver_email, text)
    print('Письмо успешно отправлено!')
except Exception as e:
    print(f'Ошибка отправки письма: {e}')
