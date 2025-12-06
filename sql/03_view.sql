-- --------------------------------------------------------------------------------
-- VIEW 1: vw_doacoes_detalhadas (VIRTUAL)
-- Objetivo: Encapsular a lógica de JOIN entre Video, Comentario e Doacao
-- Utilizada nas consultas: 3, 4, 7 e como base para vw_receita_doacoes
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_doacoes_detalhadas AS
SELECT 
    v.id_video,
    v.nome_canal,
    v.nro_plataforma,
    v.titulo,
    v.dataH as data_video,
    v.tema,
    v.duracao,
    v.visu_simul,
    v.visu_total,
    c.id_comentario,
    c.nick_usuario,
    c.seq as seq_comentario,
    c.dataH as data_comentario,
    c.texto as texto_comentario,
    c.coment_on,
    d.seq_pg as seq_doacao,
    d.valor,
    d.status
FROM Video v
INNER JOIN Comentario c ON v.id_video = c.id_video
INNER JOIN Doacao d ON c.id_comentario = d.id_comentario;

COMMENT ON VIEW vw_doacoes_detalhadas IS 
'View virtual que consolida informações de vídeos, comentários e doações. 
Utiliza identificadores artificiais para simplificar JOINs.';


-- --------------------------------------------------------------------------------
-- VIEW 2: vw_receita_patrocinio (VIRTUAL)
-- Objetivo: Agregar receita proveniente de patrocínios por canal
-- Utilizada nas consultas: 1, 5, 8
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_receita_patrocinio AS
SELECT
    p.nome_canal,
    p.nro_plataforma,
    COUNT(DISTINCT p.nro_empresa) as qtd_patrocinadores,
    SUM(p.valor) as total_patrocinio
FROM Patrocinio p
GROUP BY p.nome_canal, p.nro_plataforma;

COMMENT ON VIEW vw_receita_patrocinio IS
    'View virtual que agrega receitas de patrocínios por canal. 
    Utilizada para análises de patrocínio e como componente da view consolidada.';

-- --------------------------------------------------------------------------------
-- VIEW 3: vw_receita_membros (VIRTUAL)
-- Objetivo: Agregar receita mensal proveniente de membros inscritos por canal
-- Utilizada nas consultas: 2, 6, 8
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_receita_membros AS
SELECT
    i.nome_canal,
    i.nro_plataforma,
    COUNT(i.nick_membro) as qtd_membros,
    SUM(nc.valor) as total_membros
FROM Inscricao i
         INNER JOIN NivelCanal nc ON
    i.nome_canal = nc.nome_canal AND
    i.nro_plataforma = nc.nro_plataforma AND
    i.nivel = nc.nivel
GROUP BY i.nome_canal, i.nro_plataforma;

COMMENT ON VIEW vw_receita_membros IS
    'View virtual que agrega receitas mensais de membros por canal. 
    Calcula o valor total considerando os níveis de assinatura de cada membro.';

-- --------------------------------------------------------------------------------
-- VIEW 4: vw_receita_doacoes (VIRTUAL)
-- Objetivo: Agregar receita proveniente de doações por canal
-- Utilizada nas consultas: 3, 4, 7, 8
-- --------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_receita_doacoes AS
SELECT
    nome_canal,
    nro_plataforma,
    COUNT(*) as qtd_doacoes,
    COUNT(CASE WHEN status = 'lido' THEN 1 END) as qtd_doacoes_lidas,
    COUNT(CASE WHEN status = 'recebido' THEN 1 END) as qtd_doacoes_recebidas,
    SUM(CASE WHEN status = 'lido' THEN valor ELSE 0 END) as total_doacoes_lidas,
    SUM(CASE WHEN status IN ('recebido', 'lido') THEN valor ELSE 0 END) as total_doacoes
FROM vw_doacoes_detalhadas
GROUP BY nome_canal, nro_plataforma; 

COMMENT ON VIEW vw_receita_doacoes IS
    'View virtual que agrega receitas de doações por canal. 
    Separa doações por status (lido, recebido, recusado) para análises detalhadas.';
    
    
    
    
    
-- --------------------------------------------------------------------------------
-- VIEW 5: mv_faturamento_consolidado (MATERIALIZADA)
-- Objetivo: Consolidar todas as fontes de receita dos canais em um snapshot
-- Utilizada na consulta: 8 (dashboard executivo)
-- Atualização: 2x ao dia (08h00 e 20h00)
-- --------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_faturamento_consolidado AS
SELECT
    c.nome as nome_canal,
    c.nro_plataforma,
    c.nick_streamer,
    c.tipo as tipo_canal,
    c.data as data_criacao_canal,
    pl.nome as nome_plataforma,
    pl.qtd_users as qtd_usuarios_plataforma,
    -- Métricas de Patrocínio
    COALESCE(pat.qtd_patrocinadores, 0) as qtd_patrocinadores,
    COALESCE(pat.total_patrocinio, 0) as total_patrocinio,
    -- Métricas de Membros
    COALESCE(memb.qtd_membros, 0) as qtd_membros,
    COALESCE(memb.total_membros, 0) as total_membros,
    -- Métricas de Doações
    COALESCE(doac.qtd_doacoes, 0) as qtd_doacoes,
    COALESCE(doac.qtd_doacoes_lidas, 0) as qtd_doacoes_lidas,
    COALESCE(doac.qtd_doacoes_recebidas, 0) as qtd_doacoes_recebidas,
    COALESCE(doac.total_doacoes_lidas, 0) as total_doacoes_lidas,
    COALESCE(doac.total_doacoes, 0) as total_doacoes,
    -- Faturamento Consolidado
    (COALESCE(pat.total_patrocinio, 0) +
     COALESCE(memb.total_membros, 0) +
     COALESCE(doac.total_doacoes, 0)) as faturamento_total,
    -- Metadata
    CURRENT_TIMESTAMP as data_atualizacao
FROM Canal c
         INNER JOIN Plataforma pl ON c.nro_plataforma = pl.nro
         LEFT JOIN vw_receita_patrocinio pat ON
    c.nome = pat.nome_canal AND
    c.nro_plataforma = pat.nro_plataforma
         LEFT JOIN vw_receita_membros memb ON
    c.nome = memb.nome_canal AND
    c.nro_plataforma = memb.nro_plataforma
         LEFT JOIN vw_receita_doacoes doac ON
    c.nome = doac.nome_canal AND
    c.nro_plataforma = doac.nro_plataforma
WITH DATA -- Já popula os dados na criação;

COMMENT ON MATERIALIZED VIEW mv_faturamento_consolidado IS
    'View materializada que consolida todas as fontes de receita dos canais.
    Atualizada 2x ao dia (08h e 20h) para dashboards executivos e análises gerenciais.';
    
    
-- --------------------------------------------------------------------------------
-- Refresh da View Materializada
-- --------------------------------------------------------------------------------
REFRESH MATERIALIZED VIEW mv_faturamento_consolidado;