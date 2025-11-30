-- ============================================================
-- ÍNDICE 1 (parcial) - Doacao: acelerar agregações por status
-- Utilização: vw_receita_doacoes, fn_doacoes_lidas_por_video, fn_canais_doacoes,
--            fn_top_doacoes, fn_top_faturamento
-- Objetivo: index scan apenas nas doações relevantes (recebido ou lido)
-- Justificativa: a maioria das análises considera apenas doações com status
--                'recebido' e 'lido' (ou separa 'lido'), então um índice
--                parcial reduz muito o custo de leitura e permite index-only scans.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_doacao_recv_lido_cover
    ON Doacao USING BTREE (id_comentario)
    INCLUDE (valor, status)
    WHERE status IN ('recebido', 'lido');


-- ============================================================
-- ÍNDICE 2 - Comentario: acelerar busca de comentários por vídeo
-- Utilização: vw_doacoes_detalhadas, vw_receita_doacoes, funções de doações (Q3/Q4/Q7)
-- Objetivo: localizar rapidamente os id_comentario de um dado id_video
-- Justificativa: evita seq scans em Comentario ao buscar todos os comentários
--                de um vídeo e melhora o join para Doacao.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_comentario_por_video
    ON Comentario USING BTREE (id_video, id_comentario);


-- ============================================================
-- ÍNDICE 3 (cobridor) - Video: acelerar agregações/joins por canal
-- Utilização: vw_receita_doacoes (agregação por canal), mv_faturamento_consolidado,
--            fn_canais_doacoes, fn_top_doacoes, fn_top_faturamento
-- Objetivo: permitir index-only scans quando o planner precisa agrupar/ler
--           meta do vídeo (id_video/titulo) por canal
-- Justificativa: as queries agrupam por (nome_canal, nro_plataforma). Incluir
--                id_video e titulo torna o índice cobridor em muitos planos.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_video_por_canal_cover
    ON Video USING BTREE (nome_canal, nro_plataforma)
    INCLUDE (id_video, titulo);


-- ============================================================
-- ÍNDICE 4 (cobridor) - Patrocinio: acelerar agregações por canal
-- Utilização: vw_receita_patrocinio, fn_canais_patrocinados, fn_top_patrocinio, fn_top_faturamento
-- Objetivo: index-only scans para COUNT/SUM de patrocínios por canal
-- Justificativa: Agrupamentos por (nome_canal, nro_plataforma) são críticos;
--                incluir 'valor' (e 'nro_empresa' para contagem) evita fetchs.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_patrocinio_por_canal_cover
    ON Patrocinio USING BTREE (nome_canal, nro_plataforma)
    INCLUDE (valor, nro_empresa);


-- ============================================================
-- ÍNDICE 5 - Inscricao: acelerar lookup/agrupamento por usuário
-- Utilização: fn_usuario_membros (Q2), vw_assinaturas_usuario
-- Objetivo: localizar rapidamente todas as inscrições de um usuário (nick_membro)
-- Justificativa: PK de Inscricao tem (nome_canal, nro_plataforma, nick_membro) — 
--                não é eficiente para buscas por nick_membro isolado; esse índice
--                reduz custo quando filtramos por usuário.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_inscricao_por_membro
    ON Inscricao USING BTREE (nick_membro)
    INCLUDE (nome_canal, nro_plataforma, nivel);