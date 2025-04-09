from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from config import Config
import os

# Define o caminho do frontend
frontend_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../Front/Projeto'))

app = Flask(__name__, static_folder=frontend_path, static_url_path='/')
CORS(app)

# Configuração do banco de dados
db_config = {
    'host': Config.MYSQL_HOST,
    'user': Config.MYSQL_USER,
    'password': Config.MYSQL_PASSWORD,
    'database': Config.MYSQL_DB
}

# Rota para a URL raiz (serve o index.html automaticamente)
@app.route('/')
def index():
    return app.send_static_file('index.html')

# Rota de teste
@app.route('/api/test', methods=['GET'])
def test():
    return jsonify({"message": "Backend is working!"})

# Rota para registrar usuários
@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    name = data.get('name')
    email = data.get('email')
    profession = data.get('profession')

    if not name or not email or not profession:
        return jsonify({"message": "Todos os campos são obrigatórios!"}), 400

    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()
        query = "INSERT INTO users (name, email, profession) VALUES (%s, %s, %s)"
        cursor.execute(query, (name, email, profession))
        connection.commit()
        cursor.close()
        connection.close()
        return jsonify({"message": "Usuário registrado com sucesso!"}), 201
    except mysql.connector.Error as e:
        return jsonify({"message": "Erro ao registrar o usuário.", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
