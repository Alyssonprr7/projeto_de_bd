-- Consulta 1
SELECT * FROM fn_canais_patrocinados(); -- todos
SELECT * FROM fn_canais_patrocinados(143); -- filtrar por nro_empresa

-- Consulta 2
SELECT * FROM fn_usuario_membros(); -- todos
SELECT * FROM fn_usuario_membros('user_271'); -- filtrar por nick_usuario

-- Consulta 3
SELECT * FROM fn_canais_doacoes(); -- todos
SELECT * FROM fn_canais_doacoes('user_1_3_ch1'); -- filtrar por nome do canal

-- Consulta 4
SELECT * FROM fn_doacoes_lidas_por_video();  -- todo
SELECT * FROM fn_doacoes_lidas_por_video(296); -- filtrar por id_video

-- Consulta 5
SELECT * FROM fn_top_k('patrocinio'); -- tipo de receita sendo patrocínio
SELECT * FROM fn_top_k('patrocinio', 3); -- top 3

-- Consulta 6
SELECT * FROM fn_top_k('membros'); -- tipo de receita sendo membros (top)
SELECT * FROM fn_top_k('membros', 3); -- top 3

-- Consulta 7
SELECT * FROM fn_top_k('doacoes'); -- tipo de receita sendo doacoes
SELECT * FROM fn_top_k('doacoes', 3); -- top 3

-- Consulta 8
SELECT * FROM fn_top_k(); -- considera as 3 fontes de receita: patrocínio, membros e doações
SELECT * FROM fn_top_k('', 3); -- top 3
