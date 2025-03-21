#DROP DATABASE bd_prof_liberais_v2;
#DROP TABLE ...;


CREATE DATABASE IF NOT EXISTS bd_prof_liberais_v2;

USE bd_prof_liberais_v2;

-- Tabela para usuários
CREATE TABLE usuarios (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL, ///////QUESTIONAR PROFISSIONAL DE 2 ÁREAS COM MESMO EMAIL/////////
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
