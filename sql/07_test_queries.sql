-- 1
SELECT * FROM fn_canais_patrocinados();          -- todos
SELECT * FROM fn_canais_patrocinados(3);         -- filtrar por nro_empresa = 3

-- 2
SELECT * FROM fn_usuario_membros();              -- todos
SELECT * FROM fn_usuario_membros('user_12');    -- filtrar por nick

-- 3
SELECT * FROM fn_canais_doacoes();               -- todos
SELECT * FROM fn_canais_doacoes('Canal_X', NULL);-- por nome do canal
SELECT * FROM fn_canais_doacoes(NULL, 2);        -- por plataforma

-- 4
SELECT * FROM fn_doacoes_lidas_por_video();      -- todos vídeos
SELECT * FROM fn_doacoes_lidas_por_video(1234);  -- filtrar por id_video

-- 5
SELECT * FROM fn_top_patrocinio();               -- top 10 padrão
SELECT * FROM fn_top_patrocinio(5);              -- top 5

-- 6
SELECT * FROM fn_top_membros(15);                -- top 15

-- 7
SELECT * FROM fn_top_doacoes(20);                -- top 20

-- 8
SELECT * FROM fn_top_faturamento(10);            -- top 10
