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
    nick_usuario,
    qtd_canais_assinados AS qtd_canais_membro,
    valor_fatura_mensal AS valor_mensal_total
FROM vw_assinaturas_usuario
ORDER BY valor_fatura_mensal DESC;

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
    v.nome_canal,
    v.nro_plataforma,
    v.titulo,
    v.dataH as data_video,
    COUNT(*) as qtd_doacoes_lidas,
    SUM(valor) as total_doacoes_lidas
FROM Video v
         INNER JOIN Comentario c ON v.id_video = c.id_video
         INNER JOIN Doacao d ON c.id_comentario = d.id_comentario
WHERE d.status = 'lido'
GROUP BY v.nome_canal, v.nro_plataforma, v.titulo, v.dataH
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
    qtd_videos_com_doacoes,
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
