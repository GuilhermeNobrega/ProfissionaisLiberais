from flask import Flask, request, render_template, redirect, url_for, session, jsonify
from flask_cors import CORS
import MySQLdb
from config import Config
from enviarEmail import enviar_email_contato

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

# ------------------------- SERVIÇO POR PROFISSÃO -------------------------
@app.route('/servico-advocacia.html')
def servico_advocacia():
    return render_template('servico-advocacia.html')

@app.route('/servico-contabilidade.html')
def servico_contabilidade():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)
    
    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil,
            p.media_avaliacao
        FROM profissionais p
        WHERE LOWER(p.profissao) LIKE '%conta%'
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)
    
    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-contabilidade.html', profissionais=profissionais)


@app.route('/servico-engenharia.html')
def servico_engenharia():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)
    
    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil,
            p.media_avaliacao
        FROM profissionais p
        WHERE LOWER(p.profissao) LIKE '%engenhe%'  -- ajuste para área desejada
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)
    
    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-engenharia.html', profissionais=profissionais)


@app.route('/servico-ti.html')
def servico_ti():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil,
            p.media_avaliacao
        FROM profissionais p
        WHERE LOWER(p.profissao) LIKE '%ti%'
        OR LOWER(p.profissao) LIKE '%tecnologia%'
        OR LOWER(p.profissao) LIKE '%desenvolvedor%'
        OR LOWER(p.profissao) LIKE '%desenvolvedora%'
        OR LOWER(p.profissao) LIKE '%Analista de Sistemas%'
        OR LOWER(p.profissao) LIKE '%Especialista em Segurança da Informação%'

        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)

    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-ti.html', profissionais=profissionais)


@app.route('/servico-saude.html')
def servico_saude():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil,
            p.media_avaliacao
        FROM profissionais p
        WHERE LOWER(p.profissao) LIKE '%psic%' 
            OR LOWER(p.profissao) LIKE '%terapeu%' 
            OR LOWER(p.profissao) LIKE '%clínic%' 
            OR LOWER(p.profissao) LIKE '%nutric%'
            OR LOWER(p.profissao) LIKE '%médic%'
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)

    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-saude.html', profissionais=profissionais)


@app.route('/servico-educacao.html')
def servico_educacao():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil,
            p.media_avaliacao
        FROM profissionais p
        WHERE LOWER(p.profissao) LIKE '%educa%' 
           OR LOWER(p.profissao) LIKE '%professor%'
           OR LOWER(p.profissao) LIKE '%peda%'
           OR LOWER(p.profissao) LIKE '%orientador%'
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)

    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-educacao.html', profissionais=profissionais)

# ------------------------- OUTRAS PÁGINAS -------------------------

@app.route('/profissionais')
def pagina_profissionais():
    return render_template('profissionais.html')

@app.route('/feedbacks/<int:prof_id>')
def feedbacks_profissional(prof_id):
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    # Busca o profissional
    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil
        FROM profissionais p
        WHERE p.profissional_id = %s
    """, (prof_id,))
    profissional = cursor.fetchone()

    if not profissional:
        cursor.close()
        db.close()
        return "Profissional não encontrado", 404

    # Busca os comentários do profissional
    cursor.execute("""
        SELECT comentario FROM avaliacoes
        WHERE profissional_id = %s
        ORDER BY data_avaliacao DESC
    """, (prof_id,))
    comentarios = [row['comentario'] for row in cursor.fetchall()]
    profissional['comentarios'] = comentarios

    cursor.close()
    db.close()

    return render_template('feedbacks.html', profissional=profissional)


@app.route('/validacao', methods=['GET', 'POST'])
def validacao():
    return render_template('validacao.html')

# ------------------------- LISTAGEM DE PROFISSIONAIS -------------------------

@app.route('/profissionais-top')
def profissionais_top():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)
    
    cursor.execute("""
        SELECT 
            p.profissional_id,
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao,
            p.media_avaliacao,
            COALESCE(p.foto_perfil, '') AS foto_perfil
        FROM profissionais p
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)
    
    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    # Se não houver foto, adiciona uma padrão
    for prof in profissionais:
        if not prof['foto_perfil']:
            prof['foto_perfil'] = '/static/imgs/placeholder.png'

    return jsonify(profissionais)





@app.route('/enviar-contato', methods=['POST'])
def enviar_contato():
    nome = request.form.get('nome')
    email = request.form.get('email')
    servico = request.form.get('servico')
    mensagem = request.form.get('mensagem')

    sucesso = enviar_email_contato(nome, email, servico, mensagem)

    if sucesso:
        session['mensagem_sucesso'] = "Mensagem enviada com sucesso! Verifique seu e-mail."
    else:
        session['mensagem_sucesso'] = "Erro ao enviar o e-mail. Tente novamente mais tarde."

    return redirect(url_for('home'))
# ------------------------- RODAR A APLICAÇÃO -------------------------

if __name__ == '__main__':
    app.run(debug=True)
