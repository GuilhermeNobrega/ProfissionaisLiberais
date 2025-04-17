from flask import Flask, request, jsonify, render_template, redirect, url_for, session
from flask_cors import CORS
import MySQLdb
from config import Config

app = Flask(__name__)
app.secret_key = 'sua_chave_secreta'  # Troque por algo seguro em produção
CORS(app)

# Conexão com o banco
def get_db_connection():
    return MySQLdb.connect(
        host=Config.MYSQL_HOST,
        user=Config.MYSQL_USER,
        passwd=Config.MYSQL_PASSWORD,
        db=Config.MYSQL_DB,
        charset='utf8mb4'
    )

# Página inicial
@app.route('/')
def home():
    return render_template('index.html')

# Página de login
@app.route('/login')
def login_page():
    return render_template('login.html')

@app.route('/profissionais')
def pagina_profissionais():
    return render_template('profissionais.html')


# Rota de login
@app.route('/api/login', methods=['POST'])
def login():
    email = request.form['email']
    senha = request.form['senha']

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT usuario_id, senha_hash, tipo_usuario FROM usuarios WHERE email = %s", (email,))
    user = cursor.fetchone()
    cursor.close()
    db.close()

    if user and senha == user[1]:  # Aqui seria ideal usar hash (como bcrypt)
        session['usuario_id'] = user[0]
        session['tipo_usuario'] = user[2]
        return redirect(url_for('home'))
    return "Credenciais inválidas", 401

# Rota de cadastro
@app.route('/api/cadastro', methods=['POST'])
def cadastro():
    dados = request.form
    email = dados.get('email')
    senha = dados.get('senha')
    nome = dados.get('nome')
    telefone = dados.get('telefone')
    tipo_usuario = dados.get('tipo_usuario')  # 'cliente' ou 'profissional'

    if not all([email, senha, nome, tipo_usuario]):
        return "Dados incompletos", 400

    db = get_db_connection()
    cursor = db.cursor()
    try:
        cursor.execute("""
            INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
            VALUES (%s, %s, %s, %s, %s)
        """, (email, senha, nome, telefone, tipo_usuario))
        usuario_id = cursor.lastrowid

        if tipo_usuario == 'cliente':
            cursor.execute("INSERT INTO clientes (usuario_id) VALUES (%s)", (usuario_id,))
        elif tipo_usuario == 'profissional':
            cursor.execute("INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao) VALUES (%s, %s, %s, %s)",
                           (usuario_id, nome.split()[0], nome.split()[-1], ''))  # profissão pode ser preenchida depois

        db.commit()
    except Exception as e:
        db.rollback()
        return f"Erro ao cadastrar: {str(e)}", 500
    finally:
        cursor.close()
        db.close()

    return redirect(url_for('login_page'))

# Listar profissionais (exibição pública)
@app.route('/api/profissionais', methods=['GET'])
def listar_profissionais():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute("""
        SELECT p.profissional_id, u.nome, p.profissao, p.descricao, p.media_avaliacao
        FROM profissionais p
        JOIN usuarios u ON u.usuario_id = p.usuario_id
    """)
    profissionais = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(profissionais)

if __name__ == '__main__':
    app.run(debug=True)