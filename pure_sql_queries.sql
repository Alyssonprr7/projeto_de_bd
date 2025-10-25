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
    v.nome_canal,
    v.nro_plataforma,
    pl.nome AS nome_plataforma,
    COUNT(d.id_doacao) AS qtd_doacoes,
    SUM(d.valor) AS total_doacoes
FROM Video v
         INNER JOIN Plataforma pl ON v.nro_plataforma = pl.nro
         INNER JOIN Comentario c ON v.id_video = c.id_video
         INNER JOIN Doacao d ON c.id_comentario = d.id_comentario
GROUP BY v.nome_canal, v.nro_plataforma, pl.nome
ORDER BY total_doacoes DESC;

-- Questão 4
SELECT
    v.id_video,
    v.titulo AS titulo_video,
    v.nome_canal,
    v.nro_plataforma,
    pl.nome AS nome_plataforma,
    COUNT(d.id_doacao) AS qtd_doacoes_lidas,
    SUM(d.valor) AS total_doacoes_lidas
FROM Video v
         INNER JOIN Plataforma pl ON v.nro_plataforma = pl.nro
         INNER JOIN Comentario c ON v.id_video = c.id_video
         INNER JOIN Doacao d ON c.id_comentario = d.id_comentario
WHERE d.status = 'lido'
GROUP BY v.id_video, v.titulo, v.nome_canal, v.nro_plataforma, pl.nome
ORDER BY total_doacoes_lidas DESC;

-- Questão 5
SELECT
    c.nome AS nome_canal,
    c.nro_plataforma,
    pl.nome AS nome_plataforma,
    COUNT(p.nro_empresa) AS qtd_patrocinadores,
    SUM(p.valor) AS total_patrocinio
FROM Canal c
         INNER JOIN Plataforma pl ON c.nro_plataforma = pl.nro
         INNER JOIN Patrocinio p ON
    c.nome = p.nome_canal AND
    c.nro_plataforma = p.nro_plataforma
GROUP BY c.nome, c.nro_plataforma, pl.nome
ORDER BY total_patrocinio DESC
LIMIT 10;

-- Questão 6
SELECT
    c.nome AS nome_canal,
    c.nro_plataforma,
    pl.nome AS nome_plataforma,
    COUNT(i.nick_membro) AS qtd_membros,
    SUM(nc.valor) AS receita_mensal_membros
FROM Canal c
         INNER JOIN Plataforma pl ON c.nro_plataforma = pl.nro
         INNER JOIN Inscricao i ON
    c.nome = i.nome_canal AND
    c.nro_plataforma = i.nro_plataforma
         INNER JOIN NivelCanal nc ON
    i.nome_canal = nc.nome_canal AND
    i.nro_plataforma = nc.nro_plataforma AND
    i.nivel = nc.nivel
GROUP BY c.nome, c.nro_plataforma, pl.nome
ORDER BY receita_mensal_membros DESC
LIMIT 10;  -- Substituir 10 por K desejado

-- Questão 7
SELECT
    v.nome_canal,
    v.nro_plataforma,
    pl.nome AS nome_plataforma,
    COUNT(DISTINCT v.id_video) AS qtd_videos_com_doacoes,
    COUNT(d.id_doacao) AS qtd_doacoes,
    SUM(d.valor) AS total_doacoes
FROM Video v
         INNER JOIN Plataforma pl ON v.nro_plataforma = pl.nro
         INNER JOIN Comentario c ON v.id_video = c.id_video
         INNER JOIN Doacao d ON c.id_comentario = d.id_comentario
GROUP BY v.nome_canal, v.nro_plataforma, pl.nome
ORDER BY total_doacoes DESC
LIMIT 10;  -- Substituir 10 por K desejado


-- Questão 8
WITH
-- Receita de Patrocínio por canal
patrocinio_canal AS (
    SELECT
        p.nome_canal,
        p.nro_plataforma,
        SUM(p.valor) AS total_patrocinio
    FROM Patrocinio p
    GROUP BY p.nome_canal, p.nro_plataforma
),
-- Receita de Membros por canal (mensal)
membros_canal AS (
    SELECT
        i.nome_canal,
        i.nro_plataforma,
        SUM(nc.valor) AS total_membros
    FROM Inscricao i
             INNER JOIN NivelCanal nc ON
        i.nome_canal = nc.nome_canal AND
        i.nro_plataforma = nc.nro_plataforma AND
        i.nivel = nc.nivel
    GROUP BY i.nome_canal, i.nro_plataforma
),
-- Receita de Doações por canal
doacoes_canal AS (
    SELECT
        v.nome_canal,
        v.nro_plataforma,
        SUM(d.valor) AS total_doacoes
    FROM Video v
             INNER JOIN Comentario c ON v.id_video = c.id_video
             INNER JOIN Doacao d ON c.id_comentario = d.id_comentario
    GROUP BY v.nome_canal, v.nro_plataforma
)
-- Consolidação final
SELECT
    c.nome AS nome_canal,
    c.nro_plataforma,
    pl.nome AS nome_plataforma,
    COALESCE(pc.total_patrocinio, 0) AS receita_patrocinio,
    COALESCE(mc.total_membros, 0) AS receita_membros_mensal,
    COALESCE(dc.total_doacoes, 0) AS receita_doacoes,
    (COALESCE(pc.total_patrocinio, 0) +
     COALESCE(mc.total_membros, 0) +
     COALESCE(dc.total_doacoes, 0)) AS faturamento_total
FROM Canal c
         INNER JOIN Plataforma pl ON c.nro_plataforma = pl.nro
         LEFT JOIN patrocinio_canal pc ON
    c.nome = pc.nome_canal AND
    c.nro_plataforma = pc.nro_plataforma
         LEFT JOIN membros_canal mc ON
    c.nome = mc.nome_canal AND
    c.nro_plataforma = mc.nro_plataforma
         LEFT JOIN doacoes_canal dc ON
    c.nome = dc.nome_canal AND
    c.nro_plataforma = dc.nro_plataforma
WHERE (COALESCE(pc.total_patrocinio, 0) +
       COALESCE(mc.total_membros, 0) +
       COALESCE(dc.total_doacoes, 0)) > 0
ORDER BY faturamento_total DESC
LIMIT 10;  
