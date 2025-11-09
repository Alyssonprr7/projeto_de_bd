-- Questão 1
SELECT
    e.nro AS nro_empresa,
    e.nome AS nome_empresa,
    c.nome AS nome_canal,
    c.nro_plataforma,
    pl.nome AS nome_plataforma,
    p.valor AS valor_patrocinio
FROM Patrocinio p
         JOIN Empresa e ON p.nro_empresa = e.nro
         JOIN Canal c ON p.nome_canal = c.nome AND p.nro_plataforma = c.nro_plataforma
         JOIN Plataforma pl ON c.nro_plataforma = pl.nro
ORDER BY e.nome, p.valor DESC;

-- Questão 2
SELECT
    u.nick AS nick_usuario,
    COUNT(DISTINCT (i.nome_canal, i.nro_plataforma)) AS qtd_canais_membro,
    SUM(nc.valor) AS valor_mensal_total
FROM Usuario u
         INNER JOIN Inscricao i ON u.nick = i.nick_membro
         INNER JOIN NivelCanal nc ON
            i.nome_canal = nc.nome_canal AND
            i.nro_plataforma = nc.nro_plataforma AND
            i.nivel = nc.nivel
GROUP BY u.nick
ORDER BY valor_mensal_total DESC;

-- Questão 3
SELECT 
    nome_canal,
    nro_plataforma,
    qtd_doacoes,
    total_doacoes
FROM vw_receita_doacoes
ORDER BY total_doacoes DESC;

-- Questão 4
SELECT 
    nome_canal,
    nro_plataforma,
    titulo,
    data_video,
    COUNT(*) as qtd_doacoes_lidas,
    SUM(valor) as total_doacoes_lidas
FROM vw_doacoes_detalhadas
WHERE status = 'lido'
GROUP BY nome_canal, nro_plataforma, titulo, data_video
ORDER BY SUM(valor) DESC;


-- Questão 5
SELECT 
    nome_canal,
    nro_plataforma,
    qtd_patrocinadores,
    total_patrocinio
FROM vw_receita_patrocinio
ORDER BY total_patrocinio DESC
LIMIT 10;

-- Questão 6
SELECT 
    nome_canal,
    nro_plataforma,
    qtd_membros,
    total_membros
FROM vw_receita_membros
ORDER BY total_membros DESC
LIMIT 10; 

-- Questão 7
SELECT 
    nome_canal,
    nro_plataforma,
    qtd_doacoes,
    total_doacoes
FROM vw_receita_doacoes
ORDER BY total_doacoes DESC
LIMIT 10;


-- Questão 8
SELECT 
    nome_canal,
    nro_plataforma,
    nick_streamer,
    nome_plataforma,
    total_patrocinio,
    total_membros,
    total_doacoes,
    faturamento_total,
    data_atualizacao
FROM mv_faturamento_consolidado
ORDER BY faturamento_total DESC
LIMIT 10;
