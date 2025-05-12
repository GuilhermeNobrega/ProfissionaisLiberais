import smtplib, ssl
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def enviar_email_contato(nome, email_destino, servico, mensagem_usuario):
    remetente = 'profissionaisliberais53@gmail.com'
    senha_app = os.environ.get('SENHA_APP_EMAIL', '').replace('"', '')


    if not senha_app:
        print("Senha do app não encontrada! Use: set SENHA_APP_EMAIL=\"sua senha com espaços\"")
        return False

    mensagem = MIMEMultipart("alternative")
    mensagem["Subject"] = "Confirmação de contato - ProfissionaisLib"
    mensagem["From"] = remetente
    mensagem["To"] = email_destino

    texto = f"""
Olá {nome},

Recebemos sua mensagem sobre o serviço de {servico}.

Mensagem enviada:
{mensagem_usuario}

Em breve nossa equipe entrará em contato.

Atenciosamente,
Equipe ProfissionaisLiberais
"""
    mensagem.attach(MIMEText(texto, "plain"))

    try:
        context = ssl.create_default_context()
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
            server.login(remetente, senha_app)
            server.sendmail(remetente, email_destino, mensagem.as_string())
        print("✅ E-mail enviado com sucesso!")
        return True
    except Exception as e:
        print("❌ Erro ao enviar e-mail:", e)
        return False
