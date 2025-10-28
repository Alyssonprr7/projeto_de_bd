-- =====================================================
-- 06_functions.sql
-- Funções para responder as 8 consultas obrigatórias
-- =====================================================

/* =========================================
   Função Questão 1
   - Filtrar por empresa (opcional)
   ========================================= */
CREATE OR REPLACE FUNCTION fn_canais_patrocinados(f_empresa INT DEFAULT NULL)
RETURNS TABLE(
    nro_empresa INT,
    nome_empresa TEXT,
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    valor_patrocinio NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.nro,
        e.nome,
        c.nome,
        c.nro_plataforma,
        pl.nome,
        p.valor
    FROM Patrocinio p
    JOIN Empresa e ON p.nro_empresa = e.nro
    JOIN Canal c ON p.nome_canal = c.nome AND p.nro_plataforma = c.nro_plataforma
    JOIN Plataforma pl ON c.nro_plataforma = pl.nro
    WHERE f_empresa IS NULL OR e.nro = f_empresa
    ORDER BY e.nome, p.valor DESC;
END;
$$;


-- =========================================
-- Função Questão 2
-- - Filtrar por usuário (opcional)
-- Retorna número de canais onde o usuário é membro e soma do valor mensal
-- =========================================
CREATE OR REPLACE FUNCTION fn_usuario_membros(f_nick TEXT DEFAULT NULL)
RETURNS TABLE(
    nick_usuario TEXT,
    qtd_canais_membro BIGINT,
    valor_mensal_total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.nick,
        COUNT(DISTINCT (i.nome_canal, i.nro_plataforma))::BIGINT,
        COALESCE(SUM(nc.valor), 0)::NUMERIC
    FROM Usuario u
    JOIN Inscricao i ON u.nick = i.nick_membro
    JOIN NivelCanal nc ON i.nome_canal = nc.nome_canal
        AND i.nro_plataforma = nc.nro_plataforma
        AND i.nivel = nc.nivel
    WHERE f_nick IS NULL OR u.nick = f_nick
    GROUP BY u.nick
    ORDER BY valor_mensal_total DESC;
END;
$$;


-- =========================================
-- Função Questão 3
-- - Filtrar por canal (opcional): fornecer nome e/ou nro_plataforma
-- =========================================
CREATE OR REPLACE FUNCTION fn_canais_doacoes(
    f_nome_canal TEXT DEFAULT NULL,
    f_nro_plataforma INT DEFAULT NULL
)
RETURNS TABLE(
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    qtd_doacoes BIGINT,
    total_doacoes NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.nome_canal,
        v.nro_plataforma,
        pl.nome,
        COUNT(d.id_doacao)::BIGINT,
        COALESCE(SUM(d.valor),0)::NUMERIC
    FROM Video v
    JOIN Plataforma pl ON v.nro_plataforma = pl.nro
    JOIN Comentario c ON v.id_video = c.id_video
    JOIN Doacao d ON c.id_comentario = d.id_comentario
    WHERE (f_nome_canal IS NULL OR v.nome_canal = f_nome_canal)
      AND (f_nro_plataforma IS NULL OR v.nro_plataforma = f_nro_plataforma)
    GROUP BY v.nome_canal, v.nro_plataforma, pl.nome
    ORDER BY total_doacoes DESC;
END;
$$;


-- =========================================
-- Função Questão 4
-- - Soma das doações geradas por comentários que foram lidos por vídeo
-- - Filtrar por id_video (opcional)
-- =========================================
CREATE OR REPLACE FUNCTION fn_doacoes_lidas_por_video(f_id_video BIGINT DEFAULT NULL)
RETURNS TABLE(
    id_video BIGINT,
    titulo_video TEXT,
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    qtd_doacoes_lidas BIGINT,
    total_doacoes_lidas NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id_video,
        v.titulo,
        v.nome_canal,
        v.nro_plataforma,
        pl.nome,
        COUNT(d.id_doacao)::BIGINT,
        COALESCE(SUM(d.valor),0)::NUMERIC
    FROM Video v
    JOIN Plataforma pl ON v.nro_plataforma = pl.nro
    JOIN Comentario c ON v.id_video = c.id_video
    JOIN Doacao d ON c.id_comentario = d.id_comentario
    WHERE d.status = 'lido'
      AND (f_id_video IS NULL OR v.id_video = f_id_video)
    GROUP BY v.id_video, v.titulo, v.nome_canal, v.nro_plataforma, pl.nome
    ORDER BY total_doacoes_lidas DESC;
END;
$$;


-- =========================================
-- Função Questão 5
-- - Top k canais por patrocínio
-- =========================================
CREATE OR REPLACE FUNCTION fn_top_patrocinio(k INT DEFAULT 10)
RETURNS TABLE(
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    qtd_patrocinadores BIGINT,
    total_patrocinio NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.nome,
        c.nro_plataforma,
        pl.nome,
        COUNT(p.nro_empresa)::BIGINT,
        COALESCE(SUM(p.valor),0)::NUMERIC
    FROM Canal c
    JOIN Plataforma pl ON c.nro_plataforma = pl.nro
    JOIN Patrocinio p ON c.nome = p.nome_canal AND c.nro_plataforma = p.nro_plataforma
    GROUP BY c.nome, c.nro_plataforma, pl.nome
    ORDER BY total_patrocinio DESC
    LIMIT GREATEST(1, COALESCE(k,10));
END;
$$;


-- =========================================
-- Função Questão 6
-- - Top k canais por receita de membros
-- =========================================
CREATE OR REPLACE FUNCTION fn_top_membros(k INT DEFAULT 10)
RETURNS TABLE(
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    qtd_membros BIGINT,
    receita_mensal_membros NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.nome,
        c.nro_plataforma,
        pl.nome,
        COUNT(i.nick_membro)::BIGINT,
        COALESCE(SUM(nc.valor),0)::NUMERIC
    FROM Canal c
    JOIN Plataforma pl ON c.nro_plataforma = pl.nro
    JOIN Inscricao i ON c.nome = i.nome_canal AND c.nro_plataforma = i.nro_plataforma
    JOIN NivelCanal nc ON i.nome_canal = nc.nome_canal AND i.nro_plataforma = nc.nro_plataforma AND i.nivel = nc.nivel
    GROUP BY c.nome, c.nro_plataforma, pl.nome
    ORDER BY receita_mensal_membros DESC
    LIMIT GREATEST(1, COALESCE(k,10));
END;
$$;


-- =========================================
-- Função Questão 7
-- - Top k canais que mais receberam doações (todos os vídeos)
-- =========================================
CREATE OR REPLACE FUNCTION fn_top_doacoes(k INT DEFAULT 10)
RETURNS TABLE(
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    qtd_videos_com_doacoes BIGINT,
    qtd_doacoes BIGINT,
    total_doacoes NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.nome_canal,
        v.nro_plataforma,
        pl.nome,
        COUNT(DISTINCT v.id_video)::BIGINT,
        COUNT(d.id_doacao)::BIGINT,
        COALESCE(SUM(d.valor),0)::NUMERIC
    FROM Video v
    JOIN Plataforma pl ON v.nro_plataforma = pl.nro
    JOIN Comentario c ON v.id_video = c.id_video
    JOIN Doacao d ON c.id_comentario = d.id_comentario
    GROUP BY v.nome_canal, v.nro_plataforma, pl.nome
    ORDER BY total_doacoes DESC
    LIMIT GREATEST(1, COALESCE(k,10));
END;
$$;


-- =========================================
-- Função Questão 8
-- - Top k canais por faturamento total (patrocínio + membros + doações)
-- =========================================
CREATE OR REPLACE FUNCTION fn_top_faturamento(k INT DEFAULT 10)
RETURNS TABLE(
    nome_canal TEXT,
    nro_plataforma INT,
    nome_plataforma TEXT,
    receita_patrocinio NUMERIC,
    receita_membros_mensal NUMERIC,
    receita_doacoes NUMERIC,
    faturamento_total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH
    patrocinio_canal AS (
        SELECT p.nome_canal, p.nro_plataforma, SUM(p.valor) AS total_patrocinio
        FROM Patrocinio p
        GROUP BY p.nome_canal, p.nro_plataforma
    ),
    membros_canal AS (
        SELECT i.nome_canal, i.nro_plataforma, SUM(nc.valor) AS total_membros
        FROM Inscricao i
        JOIN NivelCanal nc ON i.nome_canal = nc.nome_canal AND i.nro_plataforma = nc.nro_plataforma AND i.nivel = nc.nivel
        GROUP BY i.nome_canal, i.nro_plataforma
    ),
    doacoes_canal AS (
        SELECT v.nome_canal, v.nro_plataforma, SUM(d.valor) AS total_doacoes
        FROM Video v
        JOIN Comentario c ON v.id_video = c.id_video
        JOIN Doacao d ON c.id_comentario = d.id_comentario
        GROUP BY v.nome_canal, v.nro_plataforma
    )
    SELECT
        c.nome,
        c.nro_plataforma,
        pl.nome,
        COALESCE(pc.total_patrocinio, 0)::NUMERIC,
        COALESCE(mc.total_membros, 0)::NUMERIC,
        COALESCE(dc.total_doacoes, 0)::NUMERIC,
        (COALESCE(pc.total_patrocinio, 0) + COALESCE(mc.total_membros, 0) + COALESCE(dc.total_doacoes, 0))::NUMERIC
    FROM Canal c
    JOIN Plataforma pl ON c.nro_plataforma = pl.nro
    LEFT JOIN patrocinio_canal pc ON c.nome = pc.nome_canal AND c.nro_plataforma = pc.nro_plataforma
    LEFT JOIN membros_canal mc ON c.nome = mc.nome_canal AND c.nro_plataforma = mc.nro_plataforma
    LEFT JOIN doacoes_canal dc ON c.nome = dc.nome_canal AND c.nro_plataforma = dc.nro_plataforma
    WHERE (COALESCE(pc.total_patrocinio, 0) + COALESCE(mc.total_membros, 0) + COALESCE(dc.total_doacoes, 0)) > 0
    ORDER BY faturamento_total DESC
    LIMIT GREATEST(1, COALESCE(k,10));
END;
$$;
