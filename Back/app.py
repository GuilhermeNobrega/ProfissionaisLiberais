from flask import Flask, request, render_template, redirect, url_for, session, jsonify
from flask_cors import CORS
from flask import flash
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
        email = request.form['email']
        senha = request.form['senha']

        db = get_db_connection()
        cursor = db.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute("SELECT * FROM usuarios WHERE email = %s", (email,))
        usuario = cursor.fetchone()
        cursor.close()
        db.close()

        if usuario and senha == usuario['senha_hash']:  # use hash real no futuro
            session['usuario_id'] = usuario['usuario_id']
            session['tipo_usuario'] = usuario['tipo_usuario']

            if usuario['tipo_usuario'] == 'cliente':
                return redirect(url_for('cliente_dashboard'))
            else:
                return redirect(url_for('profissional_dashboard'))

        flash("Login inválido")
    return render_template("login.html")

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('home'))  # ou 'login', se preferir

@app.route('/cliente/meu-perfil')
def meu_perfil():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    cliente_id = 1  # Simulação
    cursor.execute("SELECT nome, email, data_cadastro FROM usuarios WHERE usuario_id = %s", (cliente_id,))
    cliente = cursor.fetchone()

    cursor.close()
    db.close()

    return render_template('meu-perfil.html', cliente=cliente)

@app.route('/cliente/editar-perfil')
def editar_perfil():
    # Simule dados do cliente
    cliente = {
        'nome': 'Carlos Vítor',
        'email': 'teste@exemplo.com'
    }
    return render_template('cliente-editar-perfil.html', cliente=cliente)

@app.route('/cliente/alterar-senha')
def alterar_senha():
    return render_template('cliente-alterar-senha.html')

@app.route('/cliente/servicos')
def cliente_servicos():
    return render_template('cliente-servicos.html')

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
        WHERE LOWER(p.profissao) LIKE '%advogado%'
           OR LOWER(p.profissao) LIKE '%advogada%'
           OR LOWER(p.profissao) LIKE '%direito%'
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)

    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-advocacia.html', profissionais=profissionais)


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
        OR LOWER(p.profissao) LIKE '%fiscal%'
        OR LOWER(p.profissao) LIKE '%contador%'
        OR LOWER(p.profissao) LIKE '%contadora%'
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
        WHERE LOWER(p.profissao) LIKE '%engenheir%' 
           OR LOWER(p.profissao) LIKE '%arquiteto%'
           OR LOWER(p.profissao) LIKE '%projetista%'
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
        WHERE LOWER(p.profissao) LIKE '%médic%'
        OR LOWER(p.profissao) LIKE '%enfermeir%'
        OR LOWER(p.profissao) LIKE '%psicolog%'
        OR LOWER(p.profissao) LIKE '%nutricion%'
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """)

    profissionais = cursor.fetchall()
    cursor.close()
    db.close()

    return render_template('servico-saude.html', profissionais=profissionais)

@app.route('/avaliacoes')
def avaliacoes_feitas():
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    cursor.execute("""
        SELECT 
            f.comentario, 
            f.nota, 
            f.data_feedback, 
            p.nome AS nome_profissional, 
            p.area_atuacao, 
            COALESCE(p.foto, 'placeholder.png') AS foto
        FROM feedbacks f
        JOIN profissionais p ON f.profissional_id = p.id
        ORDER BY f.data_feedback DESC
        LIMIT 20
    """)

    avaliacoes = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template('avaliacoes.html', avaliacoes=avaliacoes)


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

@app.route('/cliente-dashboard')
def cliente_dashboard():
    if 'usuario_id' not in session or session.get('tipo_usuario') != 'cliente':
        return redirect(url_for('login'))

    cliente_id = session['usuario_id']

    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    # Dados do cliente
    cursor.execute("""
        SELECT nome, email
        FROM usuarios
        WHERE usuario_id = %s
    """, (cliente_id,))
    cliente_data = cursor.fetchone()

    if not cliente_data:
        flash("Cliente não encontrado.")
        return redirect(url_for('login'))

    cliente = {
        'nome': cliente_data['nome'],
        'email': cliente_data['email']
    }

    # Últimos profissionais avaliados
    cursor.execute("""
        SELECT 
            p.profissional_id, 
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao, 
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil,
            MAX(a.data_avaliacao) AS ultima_avaliacao
        FROM avaliacoes a
        JOIN profissionais p ON a.profissional_id = p.profissional_id
        WHERE a.cliente_id = %s
        GROUP BY p.profissional_id, p.primeiro_nome, p.ultimo_nome, p.profissao, p.foto_perfil
        ORDER BY ultima_avaliacao DESC
        LIMIT 3
    """, (cliente_id,))
    ultimos_profissionais = cursor.fetchall()

    # Sugestões de profissionais (exceto os já avaliados)
    cursor.execute("""
        SELECT 
            p.profissional_id, 
            CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome,
            p.profissao, 
            COALESCE(p.foto_perfil, '/static/imgs/placeholder.png') AS foto_perfil
        FROM profissionais p
        WHERE p.profissional_id NOT IN (
            SELECT profissional_id FROM avaliacoes WHERE cliente_id = %s
        )
        ORDER BY p.media_avaliacao DESC
        LIMIT 3
    """, (cliente_id,))
    recomendados = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template("cliente-dashboard.html", cliente=cliente,
                           ultimos_profissionais=ultimos_profissionais,
                           recomendados=recomendados)





@app.route('/profissional-dashboard')
def profissional_dashboard():
    if 'usuario_id' not in session or session.get('tipo_usuario') != 'profissional':
        return redirect(url_for('login'))

    usuario_id = session['usuario_id']
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    # Buscar dados do profissional vinculado ao usuário logado
    cursor.execute("""
        SELECT p.profissional_id, u.email, p.primeiro_nome, p.ultimo_nome, 
               p.media_avaliacao
        FROM profissionais p
        JOIN usuarios u ON p.usuario_id = u.usuario_id
        WHERE p.usuario_id = %s
    """, (usuario_id,))
    profissional = cursor.fetchone()

    if not profissional:
        flash("Profissional não encontrado.")
        return redirect(url_for('login'))

    profissional_id = profissional['profissional_id']

    # Contar total de avaliações recebidas
    cursor.execute("SELECT COUNT(*) as total FROM feedbacks WHERE profissional_id = %s", (profissional_id,))
    total_avaliacoes = cursor.fetchone()['total']

    # Contar clientes únicos atendidos
    cursor.execute("SELECT COUNT(DISTINCT cliente_id) as total FROM feedbacks WHERE profissional_id = %s", (profissional_id,))
    total_clientes = cursor.fetchone()['total']

    # Últimos feedbacks recebidos (sem campo nota)
    cursor.execute("""
        SELECT f.comentario, f.data_envio, u.nome as cliente_nome
        FROM feedbacks f
        JOIN usuarios u ON f.cliente_id = u.usuario_id
        WHERE f.profissional_id = %s
        ORDER BY f.data_envio DESC
        LIMIT 3
    """, (profissional_id,))
    feedbacks = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        'profissional-dashboard.html',
        profissional=profissional,
        total_avaliacoes=total_avaliacoes,
        total_clientes=total_clientes,
        feedbacks=feedbacks
    )



@app.route("/cliente")
def dashboard_cliente():
    if 'usuario_id' not in session or session.get('tipo_usuario') != 'cliente':
        return redirect(url_for('login'))

    cliente_id = session['usuario_id']
    db = get_db_connection()
    cursor = db.cursor(MySQLdb.cursors.DictCursor)

    # Pega os dados básicos do cliente
    cursor.execute("""
        SELECT nome, email
        FROM usuarios
        WHERE usuario_id = %s
    """, (cliente_id,))
    cliente_data = cursor.fetchone()
    cliente = {
        'nome': cliente_data['nome'],
        'email': cliente_data['email']
    }

    # Busca agendamentos futuros (se desejar mostrar algo)
    cursor.execute("""
        SELECT a.data_horario, a.status, s.nome AS servico, 
               CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS profissional
        FROM agendamentos a
        JOIN profissionais p ON a.profissional_id = p.profissional_id
        LEFT JOIN servicos s ON a.servico_id = s.servico_id
        WHERE a.cliente_id = %s
        ORDER BY a.data_horario ASC
        LIMIT 5
    """, (cliente_id,))
    agendamentos = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template("cliente_dashboard.html", cliente=cliente, agendamentos=agendamentos)

# ------------------------- RODAR A APLICAÇÃO -------------------------

if __name__ == '__main__':
    app.run(debug=True)
