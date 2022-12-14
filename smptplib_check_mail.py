
import smtplib

a = smtplib.SMTP('mail.spb.calculate.ru',25)
a.sendmail('support@calculate.ru', 'aa@calculate.ru', 'testtaiga')
