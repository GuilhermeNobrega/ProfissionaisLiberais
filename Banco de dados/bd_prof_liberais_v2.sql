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

CREATE TABLE feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    profissional_id INT NOT NULL,
    comentario TEXT NOT NULL,
    data_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id) ON DELETE CASCADE
);

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



INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES ('mariana.costa@email.com', '123456', 'Mariana Costa', '11999999998', 'profissional');
SELECT * FROM usuarios;
SELECT usuario_id FROM usuarios WHERE email = 'mariana.costa@email.com';

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, descricao, media_avaliacao)
VALUES (12, 'Mariana', 'Costa', 'Contadora', 'Contadora experiente em planejamento financeiro e fiscal.', 4.9);
select * from avaliacoes;


INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES 
('ana.souza@email.com', '123456', 'Ana Souza', '11999999999', 'profissional'),
('carlos.lima@email.com', '123456', 'Carlos Lima', '11999999998', 'profissional'),
('maria.oliveira@email.com', '123456', 'Maria Oliveira', '11999999997', 'profissional');


SELECT usuario_id, nome FROM usuarios WHERE tipo_usuario = 'profissional';

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES 
(13, 'Ana', 'Souza', 'Advogada Trabalhista', 4.9, 'https://randomuser.me/api/portraits/women/65.jpg'),
(14, 'Carlos', 'Lima', 'Advogado Empresarial', 4.8, 'https://randomuser.me/api/portraits/men/65.jpg'),
(15, 'Maria', 'Oliveira', 'Advogada Civil', 5.0, 'https://randomuser.me/api/portraits/women/66.jpg');

SELECT * FROM clientes;

-- Ana Souza (profissional_id = 10)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario) VALUES
(1, 10, 5, 'Excelente profissional!'),
(1, 10, 4, 'Muito atenciosa e competente.'),
(1, 10, 5, 'Recomendo fortemente!'),

-- Carlos Lima (profissional_id = 11)
(1, 11, 5, 'Profissional muito qualificado.'),
(1, 11, 4, 'Entrega no prazo com excelência.'),
(1, 11, 5, 'Trabalho impecável!'),

-- Maria Oliveira (profissional_id = 12)
(1, 12, 5, 'Atendimento exemplar.'),
(1, 12, 5, 'Muito dedicada e experiente.'),
(1, 12, 5, 'Excelente advogada!');

SELECT * FROM avaliacoes;
select * from usuarios;

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES 
('lucas.almeida@email.com', '123456', 'Lucas Almeida', '11999999888', 'profissional'),
('fernanda.santos@email.com', '123456', 'Fernanda Santos', '11999999777', 'profissional');

SELECT usuario_id, nome FROM usuarios WHERE email IN ('lucas.almeida@email.com', 'fernanda.santos@email.com');

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil, descricao)
VALUES
(16, 'Lucas', 'Almeida', 'Contador', 4.7, 'https://randomuser.me/api/portraits/men/50.jpg', 'Especialista em tributos e contabilidade empresarial.'),
(17, 'Fernanda', 'Santos', 'Contadora', 4.9, 'https://randomuser.me/api/portraits/women/51.jpg', 'Experiência em contabilidade fiscal e financeira.');

SELECT profissional_id, primeiro_nome, ultimo_nome FROM profissionais WHERE usuario_id IN (16, 17);

INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario)
VALUES
(1, 13, 5, 'Serviço impecável.'),
(1, 13, 4, 'Muito ágil e prestativo.'),
(1, 13, 5, 'Ótimo contador, recomendo!'),
(1, 14, 5, 'Excelente profissional.'),
(1, 14, 5, 'Me ajudou com toda parte fiscal.'),
(1, 14, 4, 'Atendimento muito bom.');

SELECT 
    profissional_id, CONCAT(primeiro_nome, ' ', ultimo_nome) AS nome, profissao, foto_perfil, media_avaliacao
FROM profissionais
WHERE LOWER(profissao) LIKE '%conta%';

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES ('bruno.martins@email.com', '123456', 'Bruno Martins', '11988888888', 'profissional');

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES ('juliana.silva@email.com', '123456', 'Juliana Silva', '11977777777', 'profissional');

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES ('carlos.menezes@email.com', '123456', 'Carlos Menezes', '11966666666', 'profissional');


INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES
(18, 'Bruno', 'Martins', 'Engenheiro Civil', 4.9, 'https://randomuser.me/api/portraits/men/52.jpg'),
(19, 'Juliana', 'Silva', 'Engenheira Ambiental', 4.8, 'https://randomuser.me/api/portraits/women/52.jpg'),
(20, 'Carlos', 'Menezes', 'Engenheiro Elétrico', 5.0, 'https://randomuser.me/api/portraits/men/53.jpg');
SELECT * FROM profissionais WHERE usuario_id IN (18, 19, 20);


-- Bruno Martins (por exemplo, profissional_id = 15)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario) VALUES
(1, 15, 5, 'Muito competente e experiente.'),
(1, 15, 4, 'Atendeu dentro do prazo e com qualidade.'),
(1, 15, 5, 'Engenheiro excelente!');

-- Juliana Silva (profissional_id = 16)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario) VALUES
(1, 16, 5, 'Profissional dedicada.'),
(1, 16, 4, 'Demonstrou grande conhecimento.'),
(1, 16, 5, 'Trabalho impecável!');

-- Carlos Menezes (profissional_id = 17)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario) VALUES
(1, 17, 5, 'Atendimento exemplar.'),
(1, 17, 5, 'Muito experiente e prestativo.'),
(1, 17, 5, 'Excelente engenheiro!');

-- Inserir usuários da área de T.I.
INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario)
VALUES
('ana.dev@email.com', '123456', 'Ana Dev', '11988880001', 'profissional'),
('lucas.sys@email.com', '123456', 'Lucas Silva', '11988880002', 'profissional'),
('camila.software@email.com', '123456', 'Camila Souza', '11988880003', 'profissional');

SELECT usuario_id, nome FROM usuarios WHERE tipo_usuario = 'profissional';

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES
(21, 'Ana', 'Dev', 'Desenvolvedora Full Stack', 4.9, 'https://randomuser.me/api/portraits/women/60.jpg'),
(22, 'Lucas', 'Silva', 'Analista de Sistemas', 4.8, 'https://randomuser.me/api/portraits/men/61.jpg'),
(23, 'Camila', 'Souza', 'Especialista em Segurança da Informação', 5.0, 'https://randomuser.me/api/portraits/women/62.jpg');

SELECT profissional_id, primeiro_nome, ultimo_nome FROM profissionais ORDER BY profissional_id DESC LIMIT 3;


-- Ana Dev (profissional_id = 18)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario)
VALUES
(1, 18, 5, 'Excelente desenvolvedora!'),
(1, 18, 4, 'Muito rápida e eficiente.'),
(1, 18, 5, 'Entregou antes do prazo!');

-- Lucas Silva (profissional_id = 19)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario)
VALUES
(1, 19, 5, 'Ótimo analista de sistemas.'),
(1, 19, 5, 'Identificou o problema rapidamente.'),
(1, 19, 4, 'Muito dedicado.');

-- Camila Souza (profissional_id = 20)
INSERT INTO avaliacoes (cliente_id, profissional_id, avaliacao, comentario)
VALUES
(1, 20, 5, 'Especialista excelente em segurança.'),
(1, 20, 5, 'Implementou soluções eficazes.'),
(1, 20, 5, 'Recomendo fortemente!');


INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario, data_cadastro) 
VALUES ('mariana.psico@email.com', '123456', 'Mariana Ribeiro', '11991112222', 'profissional', '2025-06-05 01:13:36');

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario, data_cadastro) 
VALUES ('pedro.terapeuta@email.com', '123456', 'Pedro Azevedo', '11992223333', 'profissional', '2025-06-05 01:13:36');

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario, data_cadastro) 
VALUES ('ana.clinica@email.com', '123456', 'Ana Martins', '11993334444', 'profissional', '2025-06-05 01:13:36');

SELECT usuario_id, nome FROM usuarios ORDER BY usuario_id DESC LIMIT 3;

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES (24, 'Mariana', 'Ribeiro', 'Psicóloga', 4.9, 'https://randomuser.me/api/portraits/women/41.jpg');

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES (25, 'Pedro', 'Azevedo', 'Terapeuta Ocupacional', 4.8, 'https://randomuser.me/api/portraits/men/41.jpg');

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES (26, 'Ana', 'Martins', 'Médica Clínica Geral', 5.0, 'https://randomuser.me/api/portraits/women/42.jpg');


-- Inserção de usuários da Educação
INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario, data_cadastro)
VALUES ('paula.machado@email.com', '123456', 'Paula Machado', '11988887777', 'profissional', '2025-06-05 01:19:45');

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario, data_cadastro)
VALUES ('leandro.ramos@email.com', '123456', 'Leandro Ramos', '11977776666', 'profissional', '2025-06-05 01:19:45');

INSERT INTO usuarios (email, senha_hash, nome, telefone, tipo_usuario, data_cadastro)
VALUES ('renata.alves@email.com', '123456', 'Renata Alves', '11966665555', 'profissional', '2025-06-05 01:19:45');

-- Inserção dos profissionais da Educação
INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES (27, 'Paula', 'Machado', 'Professora de Língua Portuguesa', 4.8, 'https://randomuser.me/api/portraits/women/62.jpg');

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES (28, 'Leandro', 'Ramos', 'Orientador Educacional', 4.7, 'https://randomuser.me/api/portraits/men/62.jpg');

INSERT INTO profissionais (usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao, foto_perfil)
VALUES (29, 'Renata', 'Alves', 'Pedagoga', 4.9, 'https://randomuser.me/api/portraits/women/63.jpg');

select * from usuarios;
SHOW COLUMNS FROM feedbacks;
DESCRIBE usuarios;
select * from profissionais;
INSERT INTO usuarios (email, senha_hash, tipo_usuario, nome, telefone)
VALUES ('engenheiro@exemplo.com', '123456', 'profissional', 'Lucas Engenheiro', '11999999999');
select * from profissionais;
SELECT usuario_id FROM usuarios WHERE email = 'engenheiro@exemplo.com';
INSERT INTO profissionais (
    usuario_id, primeiro_nome, ultimo_nome, profissao, media_avaliacao
) VALUES (
    30, 'Lucas', 'Engenheiro', 'Engenheiro Civil', 5.0
);

DESCRIBE feedbacks;


CREATE TABLE mensagens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    profissional_id INT NOT NULL,
    texto TEXT NOT NULL,
    resposta TEXT,
    data_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_resposta DATETIME,
    FOREIGN KEY (cliente_id) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (profissional_id) REFERENCES profissionais(profissional_id)
);


SELECT DISTINCT profissao FROM profissionais;

SELECT * FROM mensagens ORDER BY id DESC;
