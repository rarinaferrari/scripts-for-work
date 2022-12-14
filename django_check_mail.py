
import os
from django.core.mail import send_mail


os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings.config")

send_mail(
    'taiga test',
    'Hey from taiga',
    'taiga@calculate.ru',
    ['aa@calculate.ru'],
    fail_silently=False,
)
