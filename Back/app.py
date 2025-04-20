from flask import Flask, request, render_template, redirect, url_for, session, jsonify
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

# ------------------------- PáGINAS PRINCIPAIS -------------------------
@app.route('/')
def home():
    mensagem = session.pop('mensagem_sucesso', None)
    return render_template('index.html', mensagem=mensagem)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email'].strip().lower()
        senha = request.form['senha']

        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute("SELECT usuario_id, senha_hash, tipo_usuario FROM usuarios WHERE email = %s", (email,))
        user = cursor.fetchone()
        cursor.close()
        db.close()

        if user and senha == user[1]:
            session['usuario_id'] = user[0]
            session['tipo_usuario'] = user[2]
            session['mensagem_sucesso'] = "Login realizado com sucesso!"
            return redirect(url_for('home'))

        return render_template('login.html', erro="Credenciais inválidas")

    return render_template('login.html')




@app.route('/cadastro', methods=['GET', 'POST'])
def cadastro():
    if request.method == 'POST':
        dados = request.form
        email = dados.get('email')
        senha = dados.get('senha')
        nome = dados.get('nome')
        telefone = dados.get('telefone')
        tipo_usuario = dados.get('tipo_usuario')

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
                               (usuario_id, nome.split()[0], nome.split()[-1], ''))

            db.commit()
        except Exception as e:
            db.rollback()
            return f"Erro ao cadastrar: {str(e)}", 500
        finally:
            cursor.close()
            db.close()

        return redirect(url_for('login'))

    return render_template('cadastro.html')

# ------------------------- REGISTRO POR PROFISSÃO -------------------------

@app.route('/registro-advocacia', methods=['GET', 'POST'])
def registro_advocacia():
    if request.method == 'POST':
        nome = request.form['nome_completo']
        email = request.form['email']
        telefone = request.form['telefone']
        oab = request.form['oab']
        especialidade = request.form['especialidade']
        experiencia = request.form['experiencia']

        print(f"Advogado cadastrado: {nome}, {especialidade}")
        return redirect(url_for('home'))

    return render_template('registro-advocacia.html')

@app.route('/registro-contabilidade', methods=['GET', 'POST'])
def registro_contabilidade():
    if request.method == 'POST':
        nome = request.form['nome_completo']
        email = request.form['email']
        telefone = request.form['telefone']
        crc = request.form['crc']
        especialidade = request.form['especialidade']
        experiencia = request.form['experiencia']

        print(f"Contador cadastrado: {nome}, {especialidade}")
        return redirect(url_for('home'))

    return render_template('registro-contabilidade.html')

@app.route('/registro-engenharia', methods=['GET', 'POST'])
def registro_engenharia():
    if request.method == 'POST':
        nome = request.form['nome_completo']
        email = request.form['email']
        telefone = request.form['telefone']
        crea = request.form['crea']
        especialidade = request.form['especialidade']
        experiencia = request.form['experiencia']

        print(f"Engenheiro cadastrado: {nome}, {especialidade}")
        return redirect(url_for('home'))

    return render_template('registro-engenharia.html')

@app.route('/registro-ti', methods=['GET', 'POST'])
def registro_ti():
    if request.method == 'POST':
        nome = request.form['nome_completo']
        email = request.form['email']
        telefone = request.form['telefone']
        especialidade = request.form['especialidade']
        experiencia = request.form['experiencia']

        print(f"Profissional de TI cadastrado: {nome}, {especialidade}")
        return redirect(url_for('home'))

    return render_template('registro-ti.html')

# ------------------------- OUTRAS PÁGINAS -------------------------

@app.route('/profissionais')
def pagina_profissionais():
    return render_template('profissionais.html')

@app.route('/feedbacks')
def feedbacks():
    return render_template('feedbacks.html')

@app.route('/validacao', methods=['GET', 'POST'])
def validacao():
    return render_template('validacao.html')

# ------------------------- LISTAGEM DE PROFISSIONAIS -------------------------

@app.route('/profissionais-json')
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

# ------------------------- RODAR A APLICAÇÃO -------------------------

if __name__ == '__main__':
    app.run(debug=True)
