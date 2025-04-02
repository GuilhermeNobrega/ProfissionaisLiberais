#DROP DATABASE bd_prof_liberais_v2;
#DROP TABLE ...;


CREATE DATABASE IF NOT EXISTS bd_prof_liberais_v2;

USE bd_prof_liberais_v2;

-- Tabela para usuários
CREATE TABLE usuarios (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    telefone CHAR(11),
    tipo_usuario ENUM('cliente', 'profissional') NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_email ON usuarios(email);

-- Tabela para profissionais
CREATE TABLE profissionais (
    profissional_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    primeiro_nome VARCHAR(50) NOT NULL,
    ultimo_nome VARCHAR(50) NOT NULL,
    profissao VARCHAR(100) NOT NULL,
    numero_registro VARCHAR(50),
    sub_profissao VARCHAR(255),
    contagem_consultas INT DEFAULT 0,
    media_avaliacao DECIMAL(3,2) DEFAULT 0.0,
    oferece_consulta_online BOOLEAN DEFAULT FALSE,
    redes_sociais JSON,
    descricao TEXT,
    foto_perfil VARCHAR(255),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE
);
CREATE INDEX idx_usuario_id ON profissionais(usuario_id);

-- Tabela para clientes
CREATE TABLE clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE
);

-- Tabela para profissões
CREATE TABLE profissoes (
    profissao_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL,
    descricao TEXT
);

-- Tabela para subprofissões
CREATE TABLE sub_profissoes (
    sub_profissao_id INT AUTO_INCREMENT PRIMARY KEY,
    profissao_id INT,
    nome VARCHAR(100) NOT NULL,
    FOREIGN KEY (profissao_id) REFERENCES profissoes(profissao_id) ON DELETE CASCADE
);

-- Tabela para associação de profissões aos profissionais
CREATE TABLE profissional_profissoes (
    profissional_profissao_id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT NOT NULL,
    profissao_id INT NOT NULL,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE,
    FOREIGN KEY (profissao_id) REFERENCES profissoes(profissao_id) ON DELETE CASCADE
);

-- Tabela de Endereços
CREATE TABLE enderecos (
    endereco_id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT NOT NULL,
    logradouro VARCHAR(255) NOT NULL,
    numero VARCHAR(10),
    complemento VARCHAR(100),
    bairro VARCHAR(100),
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    cep VARCHAR(10),
    pais VARCHAR(50) NOT NULL DEFAULT 'Brasil',
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE
);

-- Tabela para serviços oferecidos
CREATE TABLE servicos (
    servico_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) UNIQUE NOT NULL,
    descricao TEXT,
    valor DECIMAL(10,2)
);

-- Tabela para associação de serviços aos profissionais
CREATE TABLE servicos_profissionais (
    servico_profissional_id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT NOT NULL,
    servico_id INT NOT NULL,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE,
    FOREIGN KEY (servico_id) REFERENCES servicos(servico_id) ON DELETE CASCADE
);

-- Tabela para agendamentos
CREATE TABLE agendamentos (
    agendamento_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    profissional_id INT NOT NULL,
    data_horario DATETIME NOT NULL,
    status ENUM('agendado', 'cancelado', 'concluido') DEFAULT 'agendado',
    observacao TEXT,
    data_agendamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    servico_id INT,
    metodo_pagamento VARCHAR(50),
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id) ON DELETE CASCADE,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE,
    FOREIGN KEY (servico_id) REFERENCES servicos(servico_id) ON DELETE SET NULL
);

-- Tabela para avaliações
CREATE TABLE avaliacoes (
    avaliacao_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    profissional_id INT NOT NULL,
    avaliacao INT CHECK (avaliacao BETWEEN 1 AND 5),
    comentario TEXT,
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    eh_verificado BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id) ON DELETE CASCADE,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE
);

-- Trigger para atualizar a média e o total de avaliações
DELIMITER //
CREATE TRIGGER update_rating AFTER INSERT ON avaliacoes FOR EACH ROW
BEGIN
    UPDATE profissionais SET 
    media_avaliacao = (SELECT AVG(avaliacao) FROM avaliacoes WHERE profissional_id = NEW.profissional_id),
    contagem_consultas = (SELECT COUNT(*) FROM avaliacoes WHERE profissional_id = NEW.profissional_id)
    WHERE profissional_id = NEW.profissional_id;
END;
//
DELIMITER ;

-- Tabela para disponibilidade de horários
CREATE TABLE disponibilidade (
    disponibilidade_id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT,
    horario_disponivel DATETIME NOT NULL,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE
);

-- Tabela para contatos
CREATE TABLE contatos (
    contato_id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT,
    tipo_contato ENUM('telefone', 'email', 'site'),
    valor_contato VARCHAR(255) NOT NULL,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE
);

-- Tabela para educação e certificações
CREATE TABLE educacao_certificacoes (
    educacao_certificacao_id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT,
    instituicao VARCHAR(255) NOT NULL,
    certificado VARCHAR(255),
    ano INT,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE
);


-- 1. VERIFICAR A INTEGRIDADE DO BANCO DE DADOS --
-- 1.1 Verificar se todas as tabelas forma criadas corretamente:
#SHOW Tables;

--  1.2 Verificar a estrutura de cada tabela (exemplos de tabelas p/ verificação):
#DESC usuarios;
#DESC profissionais;
#DESC clientes;

-- 1.3 Verificar se as chaves estrangeiras e índices foram criados corretamente:
#SHOW CREATE TABLE profissionais;

-- 2. POPULAR O BANCO DE DADOS COM DADOS INICIAIS --
-- 2.1 Inserir profissiões:
#INSERT INTO profissoes (nome, descricao) VALUES 
#('Médico', 'Profissional da área da saúde especializado em medicina'),
#('Advogado', 'Profissional da área jurídica que atua na defesa dos direitos dos clientes'),
#('Engenheiro Civil', 'Profissional que projeta e supervisiona construções e obras'),
#('Psicólogo', 'Profissional da área de saúde mental especializado em terapia psicológica');

-- 2.2 Inserir subprofissões:
#INSERT INTO sub_profissoes (profissao_id, nome) VALUES 
#(1, 'Cardiologista'),
#(1, 'Pediatra'),
#(2, 'Tributarista'),
#(2, 'Trabalhista'),
#(3, 'Estrutural'),
#(3, 'Hidráulico'),
#(4, 'Clínico'),
#(4, 'Organizacional');

-- 2.3 Inserir serviços:
#INSERT INTO servicos (nome, descricao, valor) VALUES 
#('Consulta Médica', 'Atendimento médico especializado', 200.00),
#('Assessoria Jurídica', 'Consultoria e assessoria jurídica para empresas', 350.00),
#('Projeto Arquitetônico', 'Elaboração de projetos arquitetônicos e estruturais', 1500.00),
#('Sessão de Psicoterapia', 'Sessão de terapia com profissional certificado', 180.00);

-- 2.4 Inserir usuários:
#INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario) VALUES 
#('joao.silva@email.com', 'hash_da_senha_1', 'João Silva', '11999999999', 'profissional'),
#('maria.souza@email.com', 'hash_da_senha_2', 'Maria Souza', '21988888888', 'cliente'),
#('andre.medico@email.com', 'hash_da_senha_3', 'André Medeiros', '31977777777', 'profissional'),
#('camila.arquiteta@email.com', 'hash_da_senha_4', 'Camila Andrade', '41966666666', 'profissional');

-- 2.5 Inserir profissionais associados aos usuários:
#INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, oferece_consulta_online, descricao) VALUES 
#(1, 'João', 'Silva', 'Advogado', TRUE, 'Especialista em direito empresarial e tributário.'),
#(3, 'André', 'Medeiros', 'Médico', FALSE, 'Médico cardiologista com mais de 10 anos de experiência.'),
#(4, 'Camila', 'Andrade', 'Engenheiro Civil', TRUE, 'Arquiteta e engenheira civil com foco em projetos modernos.');

-- 2.6 Inserir clientes:
#INSERT INTO clientes (usuario_id) VALUES 
#(2);

-- VERIFICAÇÃO DE REGISTROS INSERIDOS ACIMA:
#SELECT * FROM profissoes;
#SELECT * FROM usuarios;
#SELECT * FROM profissionais;

-- 3. CRIAR VIEWS E STORED PROCEDURES --
-- 3.1 - Criar uma View para Listar Profissionais e suas Profissões:
#CREATE VIEW vw_profissionais AS 
#SELECT p.profissional_id, CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS nome_completo, p.profissao, p.media_avaliacao, p.oferece_consulta_online 
#FROM profissionais p;
-- Testar a View:
#SELECT * FROM vw_profissionais;

-- 3.2 - Criar uma View para Listar Agendamentos com Detalhes:
#CREATE VIEW vw_agendamentos AS 
#SELECT a.agendamento_id, 
#       c.usuario_id AS cliente_id, 
#       u.nome AS cliente_nome, 
#       p.usuario_id AS profissional_id, 
#       CONCAT(p.primeiro_nome, ' ', p.ultimo_nome) AS profissional_nome, 
#       s.nome AS servico, 
#       a.data_horario, 
#       a.status 
#FROM agendamentos a
#JOIN clientes c ON a.cliente_id = c.cliente_id
#JOIN usuarios u ON c.usuario_id = u.usuario_id
#JOIN profissionais p ON a.profissional_id = p.profissional_id
#LEFT JOIN servicos s ON a.servico_id = s.servico_id;
-- Testar a View:
#SELECT * FROM vw_agendamentos;

-- 3.3 - Criar um Stored Procedure para Cadastrar um Novo Profissional:
DELIMITER //

#CREATE PROCEDURE sp_inserir_profissional(
#    IN p_usuario_id INT,
#    IN p_primeiro_nome VARCHAR(50),
#    IN p_ultimo_nome VARCHAR(50),
#    IN p_profissao VARCHAR(100),
#    IN p_oferece_consulta_online BOOLEAN,
#    IN p_descricao TEXT
#)
#BEGIN
#    INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, oferece_consulta_online, descricao) 
#    VALUES (p_usuario_id, p_primeiro_nome, p_ultimo_nome, p_profissao, p_oferece_consulta_online, p_descricao);
#END;
//

DELIMITER ;

-- Testar a Procedure:
#CALL sp_inserir_profissional(5, 'Carlos', 'Ferreira', 'Psicólogo', TRUE, 'Especialista em terapia cognitivo-comportamental.');
-- Verificar se foi inserido:
#SELECT * FROM profissionais WHERE primeiro_nome = 'Carlos';

-- Exemplo de inserção de dados para teste:
-- 1: Verifique os usuários existentes
#SELECT * FROM usuarios;

-- 2: Insira um usuário antes de inserir o profissional
#INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario) VALUES 
#('carlos.ferreira@email.com', 'hash_da_senha_5', 'Carlos Ferreira', '11955555555', 'profissional');

-- 3: Recuperação do usuario_id gerado acima:
#SELECT usuario_id FROM usuarios WHERE email = 'carlos.ferreira@email.com';

-- 4: Insira o profissional com o usuario_id correto:
#CALL sp_inserir_profissional(5, 'Carlos', 'Ferreira', 'Psicólogo', TRUE, 'Especialista em terapia cognitivo-comportamental.');

-- 5: Verificar a inserção correta:
#SELECT * FROM profissionais WHERE primeiro_nome = 'Carlos';

-- 3.4 - Criar um Stored Procedure para Agendar um Serviço:
#DELIMITER //

#CREATE PROCEDURE sp_agendar_servico(
#    IN p_cliente_id INT,
#    IN p_profissional_id INT,
#    IN p_data_horario DATETIME,
#    IN p_servico_id INT,
#    IN p_metodo_pagamento VARCHAR(50)
#)
#BEGIN
#    INSERT INTO agendamentos (cliente_id, profissional_id, data_horario, servico_id, metodo_pagamento) 
#    VALUES (p_cliente_id, p_profissional_id, p_data_horario, p_servico_id, p_metodo_pagamento);
#END;
#//

#DELIMITER ;

-- Testar a Procedure:
#CALL sp_agendar_servico(1, 2, '2025-04-10 15:00:00', 1, 'Cartão de Crédito');
-- Verificação da inserção:
#SELECT * FROM agendamentos WHERE data_horario = '2025-04-10 15:00:00';

-- 4. IMPLEMENTAR TESTES
-- 4.1 - Testando a inserção de Dados:
-- Teste 1: Inserir um novo usuário e conferir se foi criado
#INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario) 
#VALUES ('joana.silva@email.com', 'hash_da_senha', 'Joana Silva', '11988887777', 'cliente');
#SELECT * FROM usuarios WHERE email = 'joana.silva@email.com';
-- Teste 2: Inserir um profissional e conferir se está na tabela
#CALL sp_inserir_profissional(2, 'Marcos', 'Almeida', 'Nutricionista', TRUE, 'Atendimento especializado em nutrição esportiva.');
#SELECT * FROM profissionais WHERE primeiro_nome = 'Marcos';
-- Teste 3: Agendar um serviço e conferir se está na tabela
#CALL sp_agendar_servico(1, 2, '2025-04-15 10:00:00', 1, 'Pix');
#SELECT * FROM agendamentos WHERE data_horario = '2025-04-15 10:00:00';

-- 4.2 - Testado atualizações:
-- Teste 4: Atualizar um telefone de usuário
#UPDATE usuarios SET telefone = '11977776666' WHERE email = 'joana.silva@email.com';
#SELECT * FROM usuarios WHERE email = 'joana.silva@email.com';
-- Teste 5: Atualizar a média de avaliação de um profissional
#INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario) 
#VALUES (1, 2, 5, 'Ótimo atendimento!');
#SELECT * FROM profissionais WHERE profissional_id = 2;

-- 4.3 - Testando exclusões:
-- Teste 6: Excluir um usuário e verificar se os dados associados foram deletados
#DELETE FROM usuarios WHERE email = 'joana.silva@email.com';
#SELECT * FROM usuarios WHERE email = 'joana.silva@email.com';
#SELECT * FROM clientes WHERE usuario_id = 2;

-- 4.4 - Testando consultas avançadas
-- Teste 7: Visualizar profissionais
#SELECT * FROM vw_profissionais;
-- Teste 8: Visualizar agendamentos
#SELECT * FROM vw_agendamentos;

-- 5. CRIAÇÃO DE ÍNDICES E OTIMIZAÇÕES:
-- 5.1 - Verificar consultas lentas
#SHOW STATUS LIKE 'Last_query_cost';
-- Se houver consultas lentas, podemos otimizá-las com EXPLAIN:
#EXPLAIN SELECT * FROM profissionais WHERE profissao = 'Psicólogo';

-- 5.2 - Criar índices para melhorar o desempenho
-- índice para pesquisar usuários por e-mail (já criado)
#CREATE INDEX idx_email ON usuarios(email);
-- índice para profissionais buscarem por profissão
#CREATE INDEX idx_profissao ON profissionais(profissao);
-- índice para melhorar a performance em agendamentos
#CREATE INDEX idx_agendamento_data ON agendamentos(data_horario);
-- índice para otimizar as avaliações
#CREATE INDEX idx_avaliacoes_profissional ON avaliacoes(profissional_id);

-- 5.3 - Normalização e ajustes de tabelas
-- não há necessidade até o momento --
-- 5.4 - Testar a perfomance das consultas
#EXPLAIN SELECT * FROM profissionais WHERE profissao = 'Psicólogo';
