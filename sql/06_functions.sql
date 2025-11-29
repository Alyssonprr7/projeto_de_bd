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
    nome_empresa VARCHAR(200),
    nome_canal VARCHAR(100),
    nro_plataforma INT,
    nome_plataforma VARCHAR(200),
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
CREATE OR REPLACE FUNCTION fn_usuario_membros(f_nick VARCHAR(50) DEFAULT NULL)
RETURNS TABLE(
    nick_usuario  VARCHAR(50),
    qtd_canais_membro BIGINT,
    valor_mensal_total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.nick_usuario,
        v.qtd_canais_assinados,
        v.valor_fatura_mensal
    FROM vw_assinaturas_usuario v
    WHERE f_nick IS NULL OR v.nick_usuario = f_nick
    ORDER BY v.valor_fatura_mensal DESC;
END;
$$;



-- =========================================
-- Função Questão 3
-- - Filtrar por canal
-- =========================================
CREATE OR REPLACE FUNCTION fn_canais_doacoes(
    f_nome_canal VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE(
    nome_canal VARCHAR(100),
    nro_plataforma INT,
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
        v.qtd_doacoes,
        v.total_doacoes
    FROM vw_receita_doacoes v
    WHERE (f_nome_canal IS NULL OR v.nome_canal = f_nome_canal)
    ORDER BY v.total_doacoes DESC;
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
    titulo_video VARCHAR(300),
    nome_canal VARCHAR(100),
    nro_plataforma INT,
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
        COUNT(*) FILTER (WHERE d.status = 'lido'),
        SUM(d.valor) FILTER (WHERE d.status = 'lido')
    FROM Video v
	    JOIN Comentario c ON v.id_video = c.id_video
	    JOIN Doacao d ON c.id_comentario = d.id_comentario
    WHERE (f_id_video IS NULL OR v.id_video = f_id_video)
	AND (d.status='lido')
    GROUP BY v.id_video, v.titulo, v.nome_canal, v.nro_plataforma
    ORDER BY SUM(d.valor) DESC;
END;
$$;


-- =========================================
-- Função Questões 5, 6, 7 e 8
-- - Top k canais por faturamento total (patrocínio + membros + doações) e separados por tipo
-- =========================================

CREATE OR REPLACE FUNCTION fn_top_k(
    p_tipo TEXT DEFAULT 'faturamento',
    p_k INT DEFAULT 10
)
RETURNS TABLE(
    nome_canal VARCHAR(100),
    nro_plataforma INT,
    qtd_patrocinadores BIGINT,
    total_patrocinio NUMERIC,
    qtd_membros BIGINT,
    receita_membros_mensal NUMERIC,
    qtd_doacoes BIGINT,
    total_doacoes NUMERIC,
    faturamento_total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mv.nome_canal,
        mv.nro_plataforma,
        mv.qtd_patrocinadores,
        mv.total_patrocinio,
        mv.qtd_membros,
        mv.total_membros AS receita_membros_mensal,
        mv.qtd_doacoes,
        mv.total_doacoes,
        mv.faturamento_total
    FROM mv_faturamento_consolidado mv
    WHERE
        CASE lower(p_tipo)
            WHEN 'patrocinio' THEN mv.total_patrocinio > 0
            WHEN 'membros'     THEN mv.total_membros > 0
            WHEN 'doacoes'     THEN mv.total_doacoes > 0
            ELSE mv.faturamento_total > 0
        END
    ORDER BY
        CASE lower(p_tipo)
            WHEN 'patrocinio' THEN mv.total_patrocinio
            WHEN 'membros'     THEN mv.total_membros
            WHEN 'doacoes'     THEN mv.total_doacoes
            ELSE mv.faturamento_total
        END DESC
    LIMIT GREATEST(1, COALESCE(p_k, 10));
END;
$$;

-- Escolhemos usar fn_top_k para consultar a
-- mv_faturamento_consolidado, porque ela agrega todas as receitas do sistema
-- (patrocínios, membros e doações).

-- Isso elimina a necessidade de múltiplos JOINs e reagrupamentos dentro da
-- função, reduzindo significativamente o custo de execução e evitando
-- processamento redundante.

-- A MV é atualizada duas vezes ao dia, o que mantém o relatório atualizado
-- ao mesmo tempo em que garante alta performance nas consultas analíticas.