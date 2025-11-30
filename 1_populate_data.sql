CREATE OR REPLACE PROCEDURE popular_banco(IN qtd_base INTEGER DEFAULT 500)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_count INTEGER;
    v_empresas INTEGER;
    v_plataformas INTEGER;
    v_streamers INTEGER;
    v_canais INTEGER;
    v_total_plataformas INTEGER;
    v_total_canais INTEGER;
    v_total_videos INTEGER;
    v_total_comentarios INTEGER;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'POPULAÇÃO DO BANCO - VERSÃO OTIMIZADA';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Quantidade base: %', qtd_base;

    -- Calcular quantidades
    v_empresas := GREATEST(50, qtd_base / 10);
    v_plataformas := GREATEST(8, qtd_base / 100);
    v_streamers := GREATEST(100, qtd_base / 2);
    v_canais := GREATEST(200, qtd_base);

    -- ============================================
    -- NÍVEL 1: CONVERSÃO E PAÍSES
    -- ============================================

    RAISE NOTICE 'Populando Conversao e Pais...';

    INSERT INTO Conversao (moeda, nome, fator_conver) VALUES
                                                          ('USD', 'Dólar Americano', 1.000000),
                                                          ('BRL', 'Real Brasileiro', 5.234000),
                                                          ('EUR', 'Euro', 0.920000),
                                                          ('GBP', 'Libra Esterlina', 0.790000),
                                                          ('JPY', 'Iene Japonês', 149.500000),
                                                          ('CAD', 'Dólar Canadense', 1.360000),
                                                          ('AUD', 'Dólar Australiano', 1.530000),
                                                          ('CNY', 'Yuan Chinês', 7.240000),
                                                          ('KRW', 'Won Sul-Coreano', 1320.000000),
                                                          ('MXN', 'Peso Mexicano', 17.150000)
    ON CONFLICT (moeda) DO NOTHING;

    INSERT INTO Pais (ddi, nome, moeda) VALUES
                                            (1, 'Estados Unidos', 'USD'),
                                            (55, 'Brasil', 'BRL'),
                                            (44, 'Reino Unido', 'GBP'),
                                            (81, 'Japão', 'JPY'),
                                            (49, 'Alemanha', 'EUR'),
                                            (33, 'França', 'EUR'),
                                            (61, 'Austrália', 'AUD'),
                                            (82, 'Coreia do Sul', 'KRW'),
                                            (86, 'China', 'CNY'),
                                            (52, 'México', 'MXN')
    ON CONFLICT (ddi) DO NOTHING;

    -- ============================================
    -- NÍVEL 2: EMPRESAS
    -- ============================================

    RAISE NOTICE 'Populando Empresa (%)...', v_empresas;

    -- Empresas conhecidas (patrocinadoras)
    INSERT INTO Empresa (nome, nome_fantasia) VALUES
                                                  ('Google LLC', 'Google'),
                                                  ('Amazon.com Inc', 'Amazon'),
                                                  ('Meta Platforms Inc', 'Meta'),
                                                  ('Microsoft Corporation', 'Microsoft'),
                                                  ('Twitch Interactive Inc', 'Twitch'),
                                                  ('Red Bull Media House', 'Red Bull'),
                                                  ('Intel Corporation', 'Intel'),
                                                  ('NVIDIA Corporation', 'NVIDIA'),
                                                  ('Riot Games Inc', 'Riot Games'),
                                                  ('Electronic Arts Inc', 'EA Games'),
                                                  ('Samsung Electronics', 'Samsung'),
                                                  ('Sony Interactive', 'Sony'),
                                                  ('Logitech International', 'Logitech'),
                                                  ('Razer Inc', 'Razer'),
                                                  ('Corsair Gaming', 'Corsair'),
                                                  ('Monster Energy', 'Monster'),
                                                  ('GFuel LLC', 'GFuel'),
                                                  ('SteelSeries', 'SteelSeries'),
                                                  ('Secretlab', 'Secretlab'),
                                                  ('HyperX Gaming', 'HyperX')
    ON CONFLICT DO NOTHING;

    -- Empresas extras
    INSERT INTO Empresa (nome, nome_fantasia)
    SELECT 'Empresa_' || i || ' Ltda', 'Empresa_' || i
    FROM generate_series(1, v_empresas) i
    ON CONFLICT DO NOTHING;

    INSERT INTO EmpresaPais (nro_empresa, ddi_pais, id_nacional)
    SELECT e.nro,
           (ARRAY[1, 55, 44, 81, 49, 33, 61, 82, 86, 52])[1 + (e.nro % 10)],
           LPAD((e.nro * 123456)::TEXT, 14, '0')
    FROM Empresa e
    ON CONFLICT DO NOTHING;

    -- ============================================
    -- NÍVEL 3: PLATAFORMAS
    -- ============================================

    RAISE NOTICE 'Populando Plataforma (%)...', v_plataformas;

    -- Plataformas - buscar IDs das empresas dinamicamente
    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'YouTube', 250000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Google'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Google'),
           '2005-02-14'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Google')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'Twitch', 140000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Twitch'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Twitch'),
           '2011-06-06'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Twitch')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'Facebook Gaming', 400000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Meta'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Meta'),
           '2018-06-01'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Meta')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'Kick', 10000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Microsoft'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Microsoft'),
           '2022-12-01'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Microsoft')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'TikTok Live', 500000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Amazon'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Amazon'),
           '2016-09-01'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Amazon')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'Rumble', 80000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Google'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Google'),
           '2013-01-01'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Google')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'Trovo', 20000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Meta'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Meta'),
           '2020-03-01'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Meta')
    ON CONFLICT (nome) DO NOTHING;

    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 'DLive', 5000000,
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Amazon'),
           (SELECT nro FROM Empresa WHERE nome_fantasia = 'Amazon'),
           '2017-09-01'::DATE
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nome_fantasia = 'Amazon')
    ON CONFLICT (nome) DO NOTHING;

    SELECT COUNT(*) INTO v_total_plataformas FROM Plataforma;
    RAISE NOTICE '  -> % plataformas criadas', v_total_plataformas;

    -- ============================================
    -- NÍVEL 4: USUÁRIOS
    -- ============================================

    RAISE NOTICE 'Populando Usuario (%)...', qtd_base;

    INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, pais_residencia)
    SELECT
        'user_' || i,
        'user' || i || '@email.com',
        '1990-01-01'::DATE + (i % 10000) * INTERVAL '1 day',
        '+' || (ARRAY[1, 55, 44, 81, 49])[1 + (i % 5)] || LPAD((i * 12345)::TEXT, 9, '0'),
        'Endereco ' || i,
        (ARRAY[1, 55, 44, 81, 49, 33, 61, 82, 86, 52])[1 + (i % 10)]
    FROM generate_series(1, qtd_base) i
    ON CONFLICT (nick) DO NOTHING;

    RAISE NOTICE '  -> % usuários criados', (SELECT COUNT(*) FROM Usuario);

    -- ============================================
    -- NÍVEL 5: STREAMERS
    -- ============================================

    RAISE NOTICE 'Populando StreamerPais (%)...', v_streamers;

    INSERT INTO StreamerPais (nick_streamer, ddi_pais, nro_passaporte)
    SELECT nick, pais_residencia, 'PASS' || LPAD(ROW_NUMBER() OVER()::TEXT, 9, '0')
    FROM Usuario
    ORDER BY nick
    LIMIT v_streamers
    ON CONFLICT (nick_streamer) DO NOTHING;

    RAISE NOTICE '  -> % streamers criados', (SELECT COUNT(*) FROM StreamerPais);

    -- ============================================
    -- NÍVEL 6: PLATAFORMA-USUARIO
    -- ============================================

    RAISE NOTICE 'Populando PlataformaUsuario...';

    -- Cada usuário em 2-4 plataformas
    INSERT INTO PlataformaUsuario (nro_plataforma, nick_usuario, nro_usuario)
    SELECT p.nro, u.nick, 'U' || p.nro || '_' || u.nick
    FROM Usuario u
             CROSS JOIN Plataforma p
    WHERE ABS(HASHTEXT(u.nick || p.nro::TEXT) % 3) < 2  -- ~66% das combinações
    ON CONFLICT (nro_plataforma, nick_usuario) DO NOTHING;

    RAISE NOTICE '  -> % registros PlataformaUsuario', (SELECT COUNT(*) FROM PlataformaUsuario);

    -- ============================================
    -- NÍVEL 7: CANAIS - DISTRIBUÍDOS POR PLATAFORMA
    -- ============================================

    RAISE NOTICE 'Populando Canal (%)...', v_canais;

    -- Criar canais distribuídos uniformemente entre plataformas
    INSERT INTO Canal (nome, nro_plataforma, tipo, data, descricao, qtd_visualizacoes, nick_streamer)
    SELECT
        s.nick_streamer || '_' || p.nro || '_ch' || ch.n,
        p.nro,
        (ARRAY['privado', 'publico', 'misto'])[1 + ((s.rn + p.nro + ch.n) % 3)],
        '2018-01-01'::DATE + ((s.rn * 17 + p.nro * 31) % 1500) * INTERVAL '1 day',
        (ARRAY['Gaming', 'Tech', 'Music', 'Sports', 'Education', 'Entertainment',
            'Cooking', 'Fitness', 'Art', 'Talk Show'])[1 + ((s.rn + ch.n) % 10)],
        (s.rn * 1000 + p.nro * 500 + ch.n * 100) % 1000000,
        s.nick_streamer
    FROM (
             SELECT nick_streamer, ROW_NUMBER() OVER (ORDER BY nick_streamer) as rn
             FROM StreamerPais
         ) s
             CROSS JOIN Plataforma p
             CROSS JOIN generate_series(1, 3) ch(n)  -- 3 canais por streamer por plataforma
    WHERE s.rn <= v_canais / (v_total_plataformas * 3)  -- Limitar streamers para atingir v_canais
    ON CONFLICT (nome, nro_plataforma) DO NOTHING;

    SELECT COUNT(*) INTO v_total_canais FROM Canal;
    RAISE NOTICE '  -> % canais criados', v_total_canais;

    -- Mostrar distribuição por plataforma
    RAISE NOTICE '  -> Distribuição por plataforma:';
    FOR v_count IN
        SELECT COUNT(*) as cnt FROM Canal GROUP BY nro_plataforma ORDER BY nro_plataforma
        LOOP
            RAISE NOTICE '      - % canais', v_count;
        END LOOP;

    -- ============================================
    -- NÍVEL 8: NÍVEIS DE CANAL (5 níveis cada)
    -- ============================================

    RAISE NOTICE 'Populando NivelCanal...';

    INSERT INTO NivelCanal (nome_canal, nro_plataforma, nivel, valor, gif)
    SELECT
        c.nome,
        c.nro_plataforma,
        n.nivel,
        CASE n.nivel
            WHEN 1 THEN 4.99
            WHEN 2 THEN 9.99
            WHEN 3 THEN 14.99
            WHEN 4 THEN 24.99
            WHEN 5 THEN 49.99
            END,
        'badge_' || n.nivel || '.gif'
    FROM Canal c
             CROSS JOIN generate_series(1, 5) n(nivel)
    ON CONFLICT (nome_canal, nro_plataforma, nivel) DO NOTHING;

    RAISE NOTICE '  -> % níveis criados', (SELECT COUNT(*) FROM NivelCanal);

    -- ============================================
    -- NÍVEL 9: PATROCÍNIOS - MÚLTIPLOS POR CANAL
    -- ============================================

    RAISE NOTICE 'Populando Patrocinio...';

    -- Cada canal recebe 1-5 patrocínios de empresas diferentes
    INSERT INTO Patrocinio (nro_empresa, nome_canal, nro_plataforma, valor)
    SELECT
        e.nro,
        c.nome,
        c.nro_plataforma,
        -- Valor variado: 1000 a 50000 (usando ABS para evitar negativos)
        1000 + ABS((e.nro * 777 + HASHTEXT(c.nome)) % 49000)
    FROM Canal c
             CROSS JOIN LATERAL (
        SELECT nro
        FROM Empresa
        WHERE ABS(HASHTEXT(c.nome || nro::TEXT) % 5) < (1 + ABS(HASHTEXT(c.nome) % 4))  -- 1-4 empresas por canal
        ORDER BY HASHTEXT(c.nome || nro::TEXT)
        LIMIT 5
        ) e
    ON CONFLICT (nro_empresa, nome_canal, nro_plataforma) DO NOTHING;

    RAISE NOTICE '  -> % patrocínios criados', (SELECT COUNT(*) FROM Patrocinio);
    RAISE NOTICE '  -> Canais com patrocínio: %', (SELECT COUNT(DISTINCT (nome_canal, nro_plataforma)) FROM Patrocinio);

    -- ============================================
    -- NÍVEL 10: INSCRIÇÕES - USUÁRIOS EM MÚLTIPLOS CANAIS
    -- ============================================

    RAISE NOTICE 'Populando Inscricao (usuários em múltiplos canais)...';

    -- IMPORTANTE: Cada usuário deve ser membro de VÁRIOS canais (para Query 2)
    -- E cada canal deve ter VÁRIOS membros (para Query 6)
    INSERT INTO Inscricao (nome_canal, nro_plataforma, nick_membro, nivel)
    SELECT
        c.nome,
        c.nro_plataforma,
        u.nick,
        1 + ABS(HASHTEXT(c.nome || u.nick) % 5)  -- Nível 1-5
    FROM Canal c
             CROSS JOIN LATERAL (
        -- Cada canal recebe 10-50 membros
        SELECT nick
        FROM Usuario
        WHERE nick != c.nick_streamer  -- Não pode ser o próprio streamer
        ORDER BY HASHTEXT(c.nome || nick)
        LIMIT 10 + ABS(HASHTEXT(c.nome) % 40)
        ) u
    ON CONFLICT (nome_canal, nro_plataforma, nick_membro) DO NOTHING;

    RAISE NOTICE '  -> % inscrições criadas', (SELECT COUNT(*) FROM Inscricao);
    RAISE NOTICE '  -> Usuários que são membros: %', (SELECT COUNT(DISTINCT nick_membro) FROM Inscricao);
    RAISE NOTICE '  -> Média de canais por usuário: %',
        (SELECT ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT nick_membro), 0), 2) FROM Inscricao);
    RAISE NOTICE '  -> Média de membros por canal: %',
        (SELECT ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT (nome_canal, nro_plataforma)), 0), 2) FROM Inscricao);

    -- ============================================
    -- NÍVEL 11: VÍDEOS - MÚLTIPLOS POR CANAL
    -- ============================================

    RAISE NOTICE 'Populando Video...';

    -- Cada canal tem 5-15 vídeos
    INSERT INTO Video (nome_canal, nro_plataforma, titulo, dataH, tema, duracao, visu_simul, visu_total)
    SELECT
        c.nome,
        c.nro_plataforma,
        (ARRAY['Gameplay', 'Tutorial', 'Review', 'Live', 'Highlights', 'Unboxing',
            'Q&A', 'Vlog', 'Tips', 'Walkthrough'])[1 + (v.n % 10)] || ' #' || v.n,
        c.data + (v.n * 7) * INTERVAL '1 day' + (v.n % 24) * INTERVAL '1 hour',
        c.descricao,
        300 + (v.n * 123) % 7200,
        100 + (v.n * 456) % 10000,
        1000 + (v.n * 789) % 500000
    FROM Canal c
             CROSS JOIN generate_series(1, 5 + ABS(HASHTEXT(c.nome) % 10)) v(n)  -- 5-14 vídeos por canal
    ON CONFLICT (nome_canal, nro_plataforma, titulo, dataH) DO NOTHING;

    SELECT COUNT(*) INTO v_total_videos FROM Video;
    RAISE NOTICE '  -> % vídeos criados', v_total_videos;

    -- ============================================
    -- NÍVEL 12: PARTICIPAÇÕES
    -- ============================================

    RAISE NOTICE 'Populando Participa...';

    -- Dono do canal participa
    INSERT INTO Participa (id_video, nick_streamer)
    SELECT v.id_video, c.nick_streamer
    FROM Video v
             JOIN Canal c ON v.nome_canal = c.nome AND v.nro_plataforma = c.nro_plataforma
    ON CONFLICT (id_video, nick_streamer) DO NOTHING;

    -- Collabs (30% dos vídeos)
    INSERT INTO Participa (id_video, nick_streamer)
    SELECT v.id_video, s.nick_streamer
    FROM Video v
             JOIN Canal c ON v.nome_canal = c.nome AND v.nro_plataforma = c.nro_plataforma
             CROSS JOIN LATERAL (
        SELECT nick_streamer
        FROM StreamerPais
        WHERE nick_streamer != c.nick_streamer
        ORDER BY HASHTEXT(v.id_video::TEXT || nick_streamer)
        LIMIT 1
        ) s
    WHERE v.id_video % 3 = 0
    ON CONFLICT (id_video, nick_streamer) DO NOTHING;

    RAISE NOTICE '  -> % participações', (SELECT COUNT(*) FROM Participa);

    -- ============================================
    -- NÍVEL 13: COMENTÁRIOS - MUITOS POR VÍDEO
    -- ============================================

    RAISE NOTICE 'Populando Comentario...';

    -- Cada vídeo recebe 5-20 comentários
    INSERT INTO Comentario (id_video, nick_usuario, seq, texto, dataH, coment_on)
    SELECT
        v.id_video,
        u.nick,
        ROW_NUMBER() OVER (PARTITION BY v.id_video, u.nick),
        (ARRAY['Ótimo vídeo!', 'Muito bom!', 'Adorei!', 'Parabéns!', 'Incrível!',
            'Top demais!', 'Que show!', 'Sensacional!', 'Continue assim!', 'Perfeito!',
            'Melhor conteúdo!', 'Subscribed!', 'Like!', 'Awesome!', 'Amazing!'])[1 + (u.rn % 15)],
        v.dataH + (u.rn * INTERVAL '1 hour'),
        TRUE
    FROM Video v
             CROSS JOIN LATERAL (
        SELECT nick, ROW_NUMBER() OVER () as rn
        FROM Usuario
        ORDER BY HASHTEXT(v.id_video::TEXT || nick)
        LIMIT 5 + (v.id_video % 15)  -- 5-19 comentários por vídeo
        ) u
    ON CONFLICT (id_video, nick_usuario, seq) DO NOTHING;

    SELECT COUNT(*) INTO v_total_comentarios FROM Comentario;
    RAISE NOTICE '  -> % comentários criados', v_total_comentarios;

    -- ============================================
    -- NÍVEL 14: DOAÇÕES - COM STATUS BALANCEADO
    -- ============================================

    RAISE NOTICE 'Populando Doacao com status balanceado...';

    -- IMPORTANTE: Distribuir status incluindo 'lido' (para Query 4)
    -- Status: 'recusado' (20%), 'recebido' (30%), 'lido' (50%)
    INSERT INTO Doacao (id_comentario, seq_pg, valor, status)
    SELECT
        c.id_comentario,
        1,
        5.00 + (c.id_comentario % 495),  -- 5 a 500
        CASE
            WHEN c.id_comentario % 10 < 2 THEN 'recusado'   -- 20%
            WHEN c.id_comentario % 10 < 5 THEN 'recebido'   -- 30%
            ELSE 'lido'                                      -- 50%
            END
    FROM Comentario c
    WHERE c.id_comentario % 3 < 2  -- ~66% dos comentários têm doação
    ON CONFLICT (id_comentario, seq_pg) DO NOTHING;

    RAISE NOTICE '  -> % doações criadas', (SELECT COUNT(*) FROM Doacao);
    RAISE NOTICE '  -> Status recusado: %', (SELECT COUNT(*) FROM Doacao WHERE status = 'recusado');
    RAISE NOTICE '  -> Status recebido: %', (SELECT COUNT(*) FROM Doacao WHERE status = 'recebido');
    RAISE NOTICE '  -> Status lido: %', (SELECT COUNT(*) FROM Doacao WHERE status = 'lido');
    RAISE NOTICE '  -> Canais com doações: %',
        (SELECT COUNT(DISTINCT (v.nome_canal, v.nro_plataforma))
         FROM Doacao d
                  JOIN Comentario c ON d.id_comentario = c.id_comentario
                  JOIN Video v ON c.id_video = v.id_video);

    -- ============================================
    -- NÍVEL 15: TIPOS DE PAGAMENTO (25% cada)
    -- ============================================

    RAISE NOTICE 'Populando tipos de pagamento...';

    -- Bitcoin (25%)
    INSERT INTO BitCoin (id_doacao, TxID)
    SELECT id_doacao, MD5(id_doacao::TEXT || 'btc')
    FROM Doacao
    WHERE id_doacao % 4 = 0
    ON CONFLICT (id_doacao) DO NOTHING;

    RAISE NOTICE '  -> % Bitcoin', (SELECT COUNT(*) FROM BitCoin);

    -- PayPal (25%)
    INSERT INTO PayPal (id_doacao, IdPayPal)
    SELECT id_doacao, 'PP-' || UPPER(SUBSTRING(MD5(id_doacao::TEXT), 1, 16))
    FROM Doacao
    WHERE id_doacao % 4 = 1
    ON CONFLICT (id_doacao) DO NOTHING;

    RAISE NOTICE '  -> % PayPal', (SELECT COUNT(*) FROM PayPal);

    -- Cartão de Crédito (25%)
    INSERT INTO CartaoCredito (id_doacao, nro, bandeira, dataH)
    SELECT
        id_doacao,
        LPAD((id_doacao * 1234567890123 % 10000000000000000)::TEXT, 16, '0'),
        (ARRAY['Visa', 'Mastercard', 'Elo', 'American Express'])[1 + (id_doacao % 4)],
        NOW() - (id_doacao % 365) * INTERVAL '1 day'
    FROM Doacao
    WHERE id_doacao % 4 = 2
    ON CONFLICT (id_doacao) DO NOTHING;

    RAISE NOTICE '  -> % Cartão', (SELECT COUNT(*) FROM CartaoCredito);

    -- Mecanismo da Plataforma (25%)
    INSERT INTO MecanismoPlat (id_doacao, nro_plataforma, seq_plataforma)
    SELECT
        d.id_doacao,
        v.nro_plataforma,
        d.id_doacao * 1000
    FROM Doacao d
             JOIN Comentario c ON d.id_comentario = c.id_comentario
             JOIN Video v ON c.id_video = v.id_video
    WHERE d.id_doacao % 4 = 3
    ON CONFLICT (id_doacao) DO NOTHING;

    RAISE NOTICE '  -> % MecanismoPlat', (SELECT COUNT(*) FROM MecanismoPlat);

    -- ============================================
    -- ATUALIZAR CONTADORES
    -- ============================================

    RAISE NOTICE 'Atualizando contadores...';

    UPDATE Plataforma p SET qtd_users = (
        SELECT COUNT(DISTINCT nick_usuario)
        FROM PlataformaUsuario pu
        WHERE pu.nro_plataforma = p.nro
    );

    UPDATE Canal c SET qtd_visualizacoes = (
        SELECT COALESCE(SUM(visu_total), 0)
        FROM Video v
        WHERE v.nome_canal = c.nome AND v.nro_plataforma = c.nro_plataforma
    );

    -- ============================================
    -- RESUMO FINAL
    -- ============================================

    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'POPULAÇÃO CONCLUÍDA!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'CONTAGEM DE REGISTROS:';
    RAISE NOTICE '----------------------------------------------';

    SELECT COUNT(*) INTO v_count FROM Conversao;
    RAISE NOTICE 'Conversao:        %', v_count;
    SELECT COUNT(*) INTO v_count FROM Pais;
    RAISE NOTICE 'Pais:             %', v_count;
    SELECT COUNT(*) INTO v_count FROM Empresa;
    RAISE NOTICE 'Empresa:          %', v_count;
    SELECT COUNT(*) INTO v_count FROM EmpresaPais;
    RAISE NOTICE 'EmpresaPais:      %', v_count;
    SELECT COUNT(*) INTO v_count FROM Plataforma;
    RAISE NOTICE 'Plataforma:       %', v_count;
    SELECT COUNT(*) INTO v_count FROM Usuario;
    RAISE NOTICE 'Usuario:          %', v_count;
    SELECT COUNT(*) INTO v_count FROM StreamerPais;
    RAISE NOTICE 'StreamerPais:     %', v_count;
    SELECT COUNT(*) INTO v_count FROM PlataformaUsuario;
    RAISE NOTICE 'PlataformaUsuario:%', v_count;
    SELECT COUNT(*) INTO v_count FROM Canal;
    RAISE NOTICE 'Canal:            %', v_count;
    SELECT COUNT(*) INTO v_count FROM NivelCanal;
    RAISE NOTICE 'NivelCanal:       %', v_count;
    SELECT COUNT(*) INTO v_count FROM Patrocinio;
    RAISE NOTICE 'Patrocinio:       %', v_count;
    SELECT COUNT(*) INTO v_count FROM Inscricao;
    RAISE NOTICE 'Inscricao:        %', v_count;
    SELECT COUNT(*) INTO v_count FROM Video;
    RAISE NOTICE 'Video:            %', v_count;
    SELECT COUNT(*) INTO v_count FROM Participa;
    RAISE NOTICE 'Participa:        %', v_count;
    SELECT COUNT(*) INTO v_count FROM Comentario;
    RAISE NOTICE 'Comentario:       %', v_count;
    SELECT COUNT(*) INTO v_count FROM Doacao;
    RAISE NOTICE 'Doacao:           %', v_count;
    SELECT COUNT(*) INTO v_count FROM BitCoin;
    RAISE NOTICE 'BitCoin:          %', v_count;
    SELECT COUNT(*) INTO v_count FROM PayPal;
    RAISE NOTICE 'PayPal:           %', v_count;
    SELECT COUNT(*) INTO v_count FROM CartaoCredito;
    RAISE NOTICE 'CartaoCredito:    %', v_count;
    SELECT COUNT(*) INTO v_count FROM MecanismoPlat;
    RAISE NOTICE 'MecanismoPlat:    %', v_count;

    RAISE NOTICE '';
    RAISE NOTICE 'MÉTRICAS PARA AS QUERIES:';
    RAISE NOTICE '----------------------------------------------';

    -- Query 2: Usuários membros de múltiplos canais
    RAISE NOTICE '[Q2] Usuários membros de canais: %',
        (SELECT COUNT(DISTINCT nick_membro) FROM Inscricao);
    RAISE NOTICE '[Q2] Média canais por membro: %',
        (SELECT ROUND(AVG(cnt), 2) FROM (SELECT COUNT(*) cnt FROM Inscricao GROUP BY nick_membro) x);

    -- Query 4: Doações lidas
    RAISE NOTICE '[Q4] Doações com status lido: %',
        (SELECT COUNT(*) FROM Doacao WHERE status = 'lido');

    -- Query 5/6: Top canais
    RAISE NOTICE '[Q5] Canais com patrocínio: %',
        (SELECT COUNT(DISTINCT (nome_canal, nro_plataforma)) FROM Patrocinio);
    RAISE NOTICE '[Q6] Canais com membros: %',
        (SELECT COUNT(DISTINCT (nome_canal, nro_plataforma)) FROM Inscricao);

    -- Query 7/8: Canais com doações
    RAISE NOTICE '[Q7/8] Canais com doações: %',
        (SELECT COUNT(DISTINCT (v.nome_canal, v.nro_plataforma))
         FROM Doacao d
                  JOIN Comentario c ON d.id_comentario = c.id_comentario
                  JOIN Video v ON c.id_video = v.id_video);

    RAISE NOTICE '';
    RAISE NOTICE '==============================================';

END;
$$;

ALTER PROCEDURE popular_banco(INTEGER) OWNER TO postgres;

COMMENT ON PROCEDURE popular_banco IS
    'Procedure otimizada para popular o banco de streaming.

    Parâmetro: qtd_base (default 500)

    Garante:
    - Canais distribuídos uniformemente entre plataformas
    - Cada canal com 1-5 patrocínios de empresas diferentes
    - Usuários membros de MÚLTIPLOS canais (Query 2)
    - Doações com 50%% status "lido" (Query 4)
    - Múltiplos vídeos e comentários por canal

    Uso: CALL popular_banco(500);';
    
    
    
CREATE OR REPLACE PROCEDURE limpar_dados()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Limpando todos os dados do banco...';

    DELETE FROM MecanismoPlat;
    DELETE FROM CartaoCredito;
    DELETE FROM PayPal;
    DELETE FROM BitCoin;
    DELETE FROM Doacao;
    DELETE FROM Comentario;
    DELETE FROM Participa;
    DELETE FROM Video;
    DELETE FROM Inscricao;
    DELETE FROM NivelCanal;
    DELETE FROM Patrocinio;
    DELETE FROM Canal;
    DELETE FROM StreamerPais;
    DELETE FROM PlataformaUsuario;
    DELETE FROM Usuario;
    DELETE FROM Plataforma;
    DELETE FROM EmpresaPais;
    DELETE FROM Empresa;
    DELETE FROM Pais;
    DELETE FROM Conversao;

    -- Reset sequences
    ALTER SEQUENCE empresa_nro_seq RESTART WITH 1;
    ALTER SEQUENCE plataforma_nro_seq RESTART WITH 1;
    ALTER SEQUENCE video_id_video_seq RESTART WITH 1;
    ALTER SEQUENCE comentario_id_comentario_seq RESTART WITH 1;
    ALTER SEQUENCE doacao_id_doacao_seq RESTART WITH 1;

    RAISE NOTICE 'Dados limpos com sucesso!';
END;
$$;
