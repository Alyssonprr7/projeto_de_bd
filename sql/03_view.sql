-- --------------------------------------------------------------------------------
-- VIEW 1: vw_assinaturas_usuario (VIRTUAL)
-- Objetivo: Consolidar os gastos recorrentes (mensais) de cada usuário.
-- Justificativa: Abstrai o cálculo financeiro de mensalidade. Em vez de o desenvolvedor
-- ter que buscar o valor de cada nível em cada canal, ele consulta apenas "quanto esse user gasta".
-- --------------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_assinaturas_usuario AS
SELECT
    i.nick_membro as nick_usuario,
    u.pais_residencia,
    COUNT(DISTINCT i.nome_canal || i.nro_plataforma) as qtd_canais_assinados,
    SUM(nc.valor) as valor_fatura_mensal,
    ROUND(AVG(nc.valor), 2) as media_gasto_por_canal -- Informação não solicitada mas que pode ser útil no futuro da empresa
FROM Inscricao i
         INNER JOIN Usuario u ON i.nick_membro = u.nick
         INNER JOIN NivelCanal nc ON
    i.nome_canal = nc.nome_canal AND
    i.nro_plataforma = nc.nro_plataforma AND
    i.nivel = nc.nivel
GROUP BY i.nick_membro, u.pais_residencia;

COMMENT ON VIEW vw_assinaturas_usuario IS
    'View analítica que consolida a carteira de assinaturas dos usuários, calculando o comprometimento mensal financeiro (MRR por usuário).';

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
    v.nome_canal,
    v.nro_plataforma,
    COUNT(DISTINCT v.id_video) AS qtd_videos_com_doacoes,
    COUNT(*) as qtd_doacoes,
    COUNT(CASE WHEN status = 'lido' THEN 1 END) as qtd_doacoes_lidas,
    COUNT(CASE WHEN status = 'recebido' THEN 1 END) as qtd_doacoes_recebidas,
    SUM(CASE WHEN status = 'lido' THEN valor ELSE 0 END) as total_doacoes_lidas,
    SUM(CASE WHEN status IN ('recebido', 'lido') THEN valor ELSE 0 END) as total_doacoes
FROM Video v
INNER JOIN Comentario c ON v.id_video = c.id_video
INNER JOIN Doacao d ON c.id_comentario = d.id_comentario
GROUP by v.nro_plataforma, v.nome_canal;

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
    Atualizada 2x ao dia (5h e 15h em UTC) para dashboards executivos e análises gerenciais.';


-- --------------------------------------------------------------------------------
-- Refresh da View Materializada
-- --------------------------------------------------------------------------------
REFRESH MATERIALIZED VIEW mv_faturamento_consolidado;