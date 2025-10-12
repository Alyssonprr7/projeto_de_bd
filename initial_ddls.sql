-- ============================================
-- PROJETO DE BANCO DE DADOS - STREAMERS
-- Disciplina: Projeto de Banco de Dados 2025/2
-- Prof. Marcos Bedo
-- ============================================

-- Criação do banco de dados
DROP DATABASE IF EXISTS streamers_db;
CREATE DATABASE streamers_db
    WITH 
    ENCODING = 'UTF8'
    TEMPLATE = template0;

-- Conectar ao banco de dados criado
\c streamers_db


-- Dropping tables if they exist (for recreating the schema)
DROP TABLE IF EXISTS MecanismoPlat CASCADE;
DROP TABLE IF EXISTS CartaoCredito CASCADE;
DROP TABLE IF EXISTS PayPal CASCADE;
DROP TABLE IF EXISTS BitCoin CASCADE;
DROP TABLE IF EXISTS Doacao CASCADE;
DROP TABLE IF EXISTS Comentario CASCADE;
DROP TABLE IF EXISTS Participa CASCADE;
DROP TABLE IF EXISTS Video CASCADE;
DROP TABLE IF EXISTS Inscricao CASCADE;
DROP TABLE IF EXISTS NivelCanal CASCADE;
DROP TABLE IF EXISTS Patrocinio CASCADE;
DROP TABLE IF EXISTS Canal CASCADE;
DROP TABLE IF EXISTS StreamerPais CASCADE;
DROP TABLE IF EXISTS PlataformaUsuario CASCADE;
DROP TABLE IF EXISTS Usuario CASCADE;
DROP TABLE IF EXISTS Plataforma CASCADE;
DROP TABLE IF EXISTS Empresa CASCADE;
DROP TABLE IF EXISTS Pais CASCADE;
DROP TABLE IF EXISTS Conversao CASCADE;

-- ============================================
-- TABELAS BASE
-- ============================================

-- Tabela de Conversão de Moedas
CREATE TABLE Conversao (
    moeda VARCHAR(10) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    fator_conver DECIMAL(15, 6) NOT NULL CHECK (fator_conver > 0)
);

-- Tabela de Países
CREATE TABLE Pais (
    ddi INTEGER PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    moeda VARCHAR(10) NOT NULL,
    FOREIGN KEY (moeda) REFERENCES Conversao(moeda)
);

-- Tabela de Empresas
-- Nota: EmpresaPais foi incorporada aqui conforme decisão de normalização
CREATE TABLE Empresa (
    nro SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nome_fantasia VARCHAR(200),
    id_nacional VARCHAR(50),
    pais_origem INTEGER,
    FOREIGN KEY (pais_origem) REFERENCES Pais(ddi)
);

-- Tabela de Plataformas
CREATE TABLE Plataforma (
    nro SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    qtd_users INTEGER DEFAULT 0 CHECK (qtd_users >= 0),
    empresa_fund INTEGER NOT NULL,
    empresa_respo INTEGER NOT NULL,
    data_fund DATE NOT NULL,
    FOREIGN KEY (empresa_fund) REFERENCES Empresa(nro),
    FOREIGN KEY (empresa_respo) REFERENCES Empresa(nro)
);

-- Tabela de Usuários
CREATE TABLE Usuario (
    nick VARCHAR(50) PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,
    data_nasc DATE NOT NULL,
    telefone VARCHAR(20),
    end_postal VARCHAR(200),
    pais_residencia INTEGER NOT NULL,
    FOREIGN KEY (pais_residencia) REFERENCES Pais(ddi)
);

-- Tabela associativa Plataforma-Usuario
CREATE TABLE PlataformaUsuario (
    nro_plataforma INTEGER,
    nick_usuario VARCHAR(50),
    nro_usuario VARCHAR(100) NOT NULL,
    PRIMARY KEY (nro_plataforma, nick_usuario),
    FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro) ON DELETE CASCADE,
    FOREIGN KEY (nick_usuario) REFERENCES Usuario(nick) ON DELETE CASCADE
);

-- Tabela de Streamers (especialização de Usuario)
CREATE TABLE StreamerPais (
    nick_streamer VARCHAR(50) PRIMARY KEY,
    ddi_pais INTEGER NOT NULL,
    nro_passaporte VARCHAR(50) NOT NULL,
    FOREIGN KEY (nick_streamer) REFERENCES Usuario(nick) ON DELETE CASCADE,
    FOREIGN KEY (ddi_pais) REFERENCES Pais(ddi),
    UNIQUE (ddi_pais, nro_passaporte)
);

-- ============================================
-- TABELAS DE CANAIS E RELACIONAMENTOS
-- ============================================

-- Tabela de Canais
CREATE TABLE Canal (
    nome VARCHAR(100),
    nro_plataforma INTEGER,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('privado', 'publico', 'misto')),
    data DATE NOT NULL,
    descricao TEXT,
    qtd_visualizacoes INTEGER DEFAULT 0 CHECK (qtd_visualizacoes >= 0),
    nick_streamer VARCHAR(50) NOT NULL,
    PRIMARY KEY (nome, nro_plataforma),
    FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro) ON DELETE CASCADE,
    FOREIGN KEY (nick_streamer) REFERENCES StreamerPais(nick_streamer)
);

-- Tabela de Patrocínios
CREATE TABLE Patrocinio (
    nro_empresa INTEGER,
    nome_canal VARCHAR(100),
    nro_plataforma INTEGER,
    valor DECIMAL(15, 2) NOT NULL CHECK (valor > 0),
    PRIMARY KEY (nro_empresa, nome_canal, nro_plataforma),
    FOREIGN KEY (nro_empresa) REFERENCES Empresa(nro) ON DELETE CASCADE,
    FOREIGN KEY (nome_canal, nro_plataforma) REFERENCES Canal(nome, nro_plataforma) ON DELETE CASCADE
);

-- Tabela de Níveis de Canal
CREATE TABLE NivelCanal (
    nome_canal VARCHAR(100),
    nro_plataforma INTEGER,
    nivel INTEGER CHECK (nivel BETWEEN 1 AND 5),
    valor DECIMAL(10, 2) NOT NULL CHECK (valor > 0),
    gif VARCHAR(500),
    PRIMARY KEY (nome_canal, nro_plataforma, nivel),
    FOREIGN KEY (nome_canal, nro_plataforma) REFERENCES Canal(nome, nro_plataforma) ON DELETE CASCADE
);

-- Tabela de Inscrições (membros)
CREATE TABLE Inscricao (
    nome_canal VARCHAR(100),
    nro_plataforma INTEGER,
    nick_membro VARCHAR(50),
    nivel INTEGER,
    PRIMARY KEY (nome_canal, nro_plataforma, nick_membro),
    FOREIGN KEY (nome_canal, nro_plataforma, nivel) 
        REFERENCES NivelCanal(nome_canal, nro_plataforma, nivel) ON DELETE CASCADE,
    FOREIGN KEY (nick_membro) REFERENCES Usuario(nick) ON DELETE CASCADE
);

-- ============================================
-- TABELAS DE VÍDEOS E INTERAÇÕES
-- ============================================

-- Tabela de Vídeos
-- Nota: Adicionado id_video como surrogate key conforme decisão de normalização
CREATE TABLE Video (
    id_video SERIAL PRIMARY KEY,
    nome_canal VARCHAR(100) NOT NULL,
    nro_plataforma INTEGER NOT NULL,
    titulo VARCHAR(300) NOT NULL,
    dataH TIMESTAMP NOT NULL,
    tema VARCHAR(100),
    duracao INTEGER CHECK (duracao > 0),
    visu_simul INTEGER DEFAULT 0 CHECK (visu_simul >= 0),
    visu_total INTEGER DEFAULT 0 CHECK (visu_total >= 0),
    FOREIGN KEY (nome_canal, nro_plataforma) REFERENCES Canal(nome, nro_plataforma) ON DELETE CASCADE,
    UNIQUE (nome_canal, nro_plataforma, titulo, dataH)
);

-- Tabela de Participações de Streamers em Vídeos
CREATE TABLE Participa (
    id_video INTEGER,
    nick_streamer VARCHAR(50),
    PRIMARY KEY (id_video, nick_streamer),
    FOREIGN KEY (id_video) REFERENCES Video(id_video) ON DELETE CASCADE,
    FOREIGN KEY (nick_streamer) REFERENCES StreamerPais(nick_streamer) ON DELETE CASCADE
);

-- Tabela de Comentários
-- Nota: Adicionado id_comentario como surrogate key conforme decisão de normalização
CREATE TABLE Comentario (
    id_comentario SERIAL PRIMARY KEY,
    id_video INTEGER NOT NULL,
    nick_usuario VARCHAR(50) NOT NULL,
    seq INTEGER NOT NULL,
    texto TEXT NOT NULL,
    dataH TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    coment_on BOOLEAN NOT NULL,
    FOREIGN KEY (id_video) REFERENCES Video(id_video) ON DELETE CASCADE,
    FOREIGN KEY (nick_usuario) REFERENCES Usuario(nick) ON DELETE CASCADE,
    UNIQUE (id_video, nick_usuario, seq)
);

-- ============================================
-- TABELAS DE DOAÇÕES (HIERARQUIA)
-- ============================================

-- Tabela de Doações (superclasse)
-- Nota: Adicionado id_doacao como surrogate key conforme decisão de normalização
CREATE TABLE Doacao (
    id_doacao SERIAL PRIMARY KEY,
    id_comentario INTEGER NOT NULL,
    seq_pg INTEGER NOT NULL,
    valor DECIMAL(15, 2) NOT NULL CHECK (valor > 0),
    status VARCHAR(10) NOT NULL CHECK (status IN ('recusado', 'recebido', 'lido')),
    FOREIGN KEY (id_comentario) REFERENCES Comentario(id_comentario) ON DELETE CASCADE,
    UNIQUE (id_comentario, seq_pg)
);

-- Tabela de Doações via Bitcoin (subclasse)
CREATE TABLE BitCoin (
    id_doacao INTEGER PRIMARY KEY,
    TxID VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (id_doacao) REFERENCES Doacao(id_doacao) ON DELETE CASCADE
);

-- Tabela de Doações via PayPal (subclasse)
CREATE TABLE PayPal (
    id_doacao INTEGER PRIMARY KEY,
    IdPayPal VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (id_doacao) REFERENCES Doacao(id_doacao) ON DELETE CASCADE
);

-- Tabela de Doações via Cartão de Crédito (subclasse)
CREATE TABLE CartaoCredito (
    id_doacao INTEGER PRIMARY KEY,
    nro VARCHAR(20) NOT NULL,
    bandeira VARCHAR(50) NOT NULL,
    dataH TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_doacao) REFERENCES Doacao(id_doacao) ON DELETE CASCADE
);

-- Tabela de Doações via Mecanismo da Plataforma (subclasse)
CREATE TABLE MecanismoPlat (
    id_doacao INTEGER PRIMARY KEY,
    nro_plataforma INTEGER NOT NULL,
    seq_plataforma INTEGER NOT NULL,
    FOREIGN KEY (id_doacao) REFERENCES Doacao(id_doacao) ON DELETE CASCADE,
    FOREIGN KEY (nro_plataforma) REFERENCES Plataforma(nro) ON DELETE CASCADE,
    UNIQUE (nro_plataforma, seq_plataforma)
);
