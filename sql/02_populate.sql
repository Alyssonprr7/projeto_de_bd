-- ============================================
-- PROCEDURE PARA POPULAR O BANCO DE DADOS
-- Volume: 100-1000 tuplas por tabela
-- ============================================

CREATE OR REPLACE PROCEDURE popular_banco(qtd_base INTEGER DEFAULT 500)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INTEGER;
    v_empresas INTEGER;
    v_plataformas INTEGER;
    v_streamers INTEGER;
    v_canais INTEGER;
BEGIN
    RAISE NOTICE 'Iniciando população do banco com quantidade base: %', qtd_base;
    RAISE NOTICE 'Objetivo: 100-1000 tuplas por tabela';
    
    -- Calcular quantidades proporcionais
    v_empresas := GREATEST(100, qtd_base / 5);
    v_plataformas := GREATEST(10, qtd_base / 50);
    
    -- ============================================
    -- NÍVEL 1: TABELAS BASE
    -- ============================================
    
    RAISE NOTICE 'Populando Conversao...';
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
        ('MXN', 'Peso Mexicano', 17.150000),
        ('INR', 'Rúpia Indiana', 83.120000),
        ('CHF', 'Franco Suíço', 0.880000),
        ('SEK', 'Coroa Sueca', 10.890000),
        ('NZD', 'Dólar Neozelandês', 1.650000),
        ('ARS', 'Peso Argentino', 350.500000)
    ON CONFLICT (moeda) DO NOTHING;
    
    RAISE NOTICE 'Populando Pais...';
    INSERT INTO Pais (ddi, nome, moeda) VALUES
        (1, 'Estados Unidos', 'USD'),
        (55, 'Brasil', 'BRL'),
        (44, 'Reino Unido', 'GBP'),
        (81, 'Japão', 'JPY'),
        (49, 'Alemanha', 'EUR'),
        (33, 'França', 'EUR'),
        (34, 'Espanha', 'EUR'),
        (39, 'Itália', 'EUR'),
        (61, 'Austrália', 'AUD'),
        (82, 'Coreia do Sul', 'KRW'),
        (86, 'China', 'CNY'),
        (52, 'México', 'MXN'),
        (91, 'Índia', 'INR'),
        (41, 'Suíça', 'CHF'),
        (46, 'Suécia', 'SEK'),
        (64, 'Nova Zelândia', 'NZD'),
        (54, 'Argentina', 'ARS')
    ON CONFLICT (ddi) DO NOTHING;
    
    -- ============================================
    -- NÍVEL 2: EMPRESAS (100-1000)
    -- ============================================
    
    RAISE NOTICE 'Populando Empresa (% empresas)...', v_empresas;
    
    -- Primeiro inserir empresas base conhecidas
    INSERT INTO Empresa (nome, nome_fantasia) VALUES
        ('Google LLC', 'Google'),
        ('Amazon.com Inc', 'Amazon'),
        ('Meta Platforms Inc', 'Meta'),
        ('Microsoft Corporation', 'Microsoft'),
        ('Twitch Interactive Inc', 'Twitch'),
        ('ByteDance Ltd', 'TikTok'),
        ('Kick Streaming', 'Kick'),
        ('Red Bull Media House', 'Red Bull'),
        ('Intel Corporation', 'Intel'),
        ('NVIDIA Corporation', 'NVIDIA'),
        ('Riot Games Inc', 'Riot Games'),
        ('Electronic Arts Inc', 'EA Games'),
        ('Ubisoft Entertainment', 'Ubisoft'),
        ('Samsung Electronics', 'Samsung'),
        ('Sony Interactive', 'Sony')
    ON CONFLICT DO NOTHING;
    
    -- Depois gerar empresas artificiais até atingir a quantidade desejada
    INSERT INTO Empresa (nome, nome_fantasia)
    SELECT 
        'Empresa ' || i || ' Ltda',
        'Empresa ' || i
    FROM generate_series(1, v_empresas - 15) i
    ON CONFLICT DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> Total de empresas: %', (SELECT COUNT(*) FROM Empresa);
    
    RAISE NOTICE 'Populando EmpresaPais...';
    INSERT INTO EmpresaPais (nro_empresa, ddi_pais, id_nacional)
    SELECT 
        e.nro,
        (ARRAY[1, 55, 44, 81, 49, 33, 34, 39, 61, 82, 86, 52, 91, 41, 46, 64, 54])[1 + (RANDOM() * 16)::INTEGER],
        LPAD((e.nro::bigint * 12345678)::TEXT, 14, '0')
    FROM Empresa e
    ON CONFLICT DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % registros em EmpresaPais', v_count;
    
    -- ============================================
    -- NÍVEL 3: PLATAFORMAS (100-200)
    -- ============================================
    
    RAISE NOTICE 'Populando Plataforma (% plataformas)...', v_plataformas;
    
    -- Plataformas reais primeiro
    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 
        plat.nome,
        0,
        plat.empresa_fund,
        plat.empresa_respo,
        plat.data_fund
    FROM (VALUES
        ('YouTube', 1, 1, '2005-02-14'::DATE),
        ('Twitch', 5, 5, '2011-06-06'::DATE),
        ('Facebook Gaming', 3, 3, '2018-06-01'::DATE),
        ('Kick', 7, 7, '2022-12-01'::DATE),
        ('TikTok Live', 6, 6, '2016-09-01'::DATE)
    ) AS plat(nome, empresa_fund, empresa_respo, data_fund)
    WHERE EXISTS (SELECT 1 FROM Empresa WHERE nro = plat.empresa_fund)
    ON CONFLICT (nome) DO NOTHING;
    
    -- Plataformas artificiais
    INSERT INTO Plataforma (nome, qtd_users, empresa_fund, empresa_respo, data_fund)
    SELECT 
        'Platform_' || i,
        0,
        (SELECT nro FROM Empresa ORDER BY RANDOM() LIMIT 1),
        (SELECT nro FROM Empresa ORDER BY RANDOM() LIMIT 1),
        ('2010-01-01'::DATE + (RANDOM() * 365 * 13)::INTEGER * INTERVAL '1 day')::DATE
    FROM generate_series(1, v_plataformas - 5) i
    ON CONFLICT (nome) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> Total de plataformas: %', (SELECT COUNT(*) FROM Plataforma);
    
    -- ============================================
    -- NÍVEL 4: USUARIOS (qtd_base = 100-1000)
    -- ============================================
    
    RAISE NOTICE 'Populando Usuario (% usuários)...', qtd_base;
    INSERT INTO Usuario (nick, email, data_nasc, telefone, end_postal, pais_residencia)
    SELECT 
        'user_' || i,
        'user' || i || '@email.com',
        ('1985-01-01'::DATE + (RANDOM() * 365 * 30)::INTEGER * INTERVAL '1 day')::DATE,
        '+' || (ARRAY[1, 55, 44, 81, 49, 33, 34, 39, 61, 82, 86, 52])[1 + (RANDOM() * 11)::INTEGER]::TEXT 
            || LPAD((RANDOM() * 1000000000)::BIGINT::TEXT, 9, '0'),
        'Rua ' || (RANDOM() * 1000)::INTEGER || ', Apt ' || (RANDOM() * 100)::INTEGER,
        (ARRAY[1, 55, 44, 81, 49, 33, 34, 39, 61, 82, 86, 52, 91, 41, 46, 64, 54])[1 + (RANDOM() * 16)::INTEGER]
    FROM generate_series(1, qtd_base) i
    ON CONFLICT (nick) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % usuários criados', v_count;
    
    -- ============================================
    -- NÍVEL 5: STREAMERS (50% dos usuários)
    -- ============================================
    
    v_streamers := qtd_base / 2;
    RAISE NOTICE 'Populando StreamerPais (% streamers)...', v_streamers;
    
    INSERT INTO StreamerPais (nick_streamer, ddi_pais, nro_passaporte)
    SELECT 
        u.nick,
        u.pais_residencia,
        'PASS' || LPAD((ROW_NUMBER() OVER ())::TEXT, 9, '0')
    FROM Usuario u
    ORDER BY RANDOM()
    LIMIT v_streamers
    ON CONFLICT (nick_streamer) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % streamers criados', v_count;
    
    -- ============================================
    -- NÍVEL 6: PLATAFORMA-USUARIO (100-1000+)
    -- ============================================
    
    RAISE NOTICE 'Populando PlataformaUsuario...';
    INSERT INTO PlataformaUsuario (nro_plataforma, nick_usuario, nro_usuario)
    SELECT 
        p.nro,
        u.nick,
        'USR_' || p.nro || '_' || (ROW_NUMBER() OVER (PARTITION BY p.nro))
    FROM Plataforma p
    CROSS JOIN LATERAL (
        SELECT nick FROM Usuario ORDER BY RANDOM() LIMIT GREATEST(100, qtd_base / 5)
    ) u
    ON CONFLICT (nro_plataforma, nick_usuario) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % registros de usuários em plataformas', v_count;
    
    -- ============================================
    -- NÍVEL 7: CANAIS (100-1000)
    -- ============================================
    
    v_canais := GREATEST(100, qtd_base);
    RAISE NOTICE 'Populando Canal (% canais)...', v_canais;
    
    INSERT INTO Canal (nome, nro_plataforma, tipo, data, descricao, qtd_visualizacoes, nick_streamer)
    SELECT 
        s.nick_streamer || '_' || p.nome || '_' || sub.num,
        p.nro,
        (ARRAY['privado', 'publico', 'misto'])[1 + (RANDOM() * 2)::INTEGER],
        ('2015-01-01'::DATE + (RANDOM() * 365 * 8)::INTEGER * INTERVAL '1 day')::DATE,
        'Canal de ' || (ARRAY['Gaming', 'Tech Review', 'Tutorial', 'Music', 'Talk Show', 'Sports', 
                              'Cooking', 'Fitness', 'Education', 'News'])[1 + (RANDOM() * 9)::INTEGER],
        0,
        s.nick_streamer
    FROM StreamerPais s
    CROSS JOIN Plataforma p
    CROSS JOIN generate_series(1, GREATEST(1, v_canais / (SELECT COUNT(*) FROM StreamerPais) / (SELECT COUNT(*) FROM Plataforma) + 1)) sub(num)
    WHERE (s.nick_streamer || '_' || p.nome || '_' || sub.num) IS NOT NULL
    LIMIT v_canais
    ON CONFLICT (nome, nro_plataforma) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % canais criados', v_count;
    
    -- ============================================
    -- NÍVEL 8: NIVEIS DE CANAL (5 por canal)
    -- ============================================
    
    RAISE NOTICE 'Populando NivelCanal (5 níveis por canal)...';
    INSERT INTO NivelCanal (nome_canal, nro_plataforma, nivel, valor, gif)
    SELECT 
        c.nome,
        c.nro_plataforma,
        n.nivel,
        n.nivel * (4.99 + RANDOM() * 10),
        'badge_level_' || n.nivel || '.gif'
    FROM Canal c
    CROSS JOIN (SELECT generate_series(1, 5) AS nivel) n
    ON CONFLICT (nome_canal, nro_plataforma, nivel) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % níveis de canal criados', v_count;
    
    -- ============================================
    -- NÍVEL 9: PATROCINIOS (100-1000)
    -- ============================================
    
    RAISE NOTICE 'Populando Patrocinio (objetivo: % patrocínios)...', GREATEST(100, qtd_base / 2);
    INSERT INTO Patrocinio (nro_empresa, nome_canal, nro_plataforma, valor)
    SELECT DISTINCT ON (e.nro, c.nome, c.nro_plataforma)
        e.nro,
        c.nome,
        c.nro_plataforma,
        (1000 + RANDOM() * 50000)::NUMERIC(15,2)
    FROM Empresa e
    CROSS JOIN LATERAL (
        SELECT nome, nro_plataforma 
        FROM Canal 
        ORDER BY RANDOM() 
        LIMIT GREATEST(1, qtd_base / (SELECT COUNT(*) FROM Empresa) / 2)
    ) c
    LIMIT GREATEST(100, qtd_base / 2)
    ON CONFLICT (nro_empresa, nome_canal, nro_plataforma) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % patrocínios criados', v_count;
    
    -- ============================================
    -- NÍVEL 10: INSCRICOES (100-1000)
    -- ============================================
    
    RAISE NOTICE 'Populando Inscricao (objetivo: % inscrições)...', GREATEST(100, qtd_base);
    INSERT INTO Inscricao (nome_canal, nro_plataforma, nick_membro, nivel)
    SELECT DISTINCT ON (c.nome, c.nro_plataforma, u.nick)
        c.nome,
        c.nro_plataforma,
        u.nick,
        1 + (RANDOM() * 4)::INTEGER
    FROM Canal c
    CROSS JOIN LATERAL (
        SELECT nick 
        FROM Usuario 
        ORDER BY RANDOM() 
        LIMIT GREATEST(1, qtd_base / (SELECT COUNT(*) FROM Canal))
    ) u
    WHERE EXISTS (
        SELECT 1 FROM NivelCanal nc 
        WHERE nc.nome_canal = c.nome 
        AND nc.nro_plataforma = c.nro_plataforma
    )
    LIMIT GREATEST(100, qtd_base)
    ON CONFLICT (nome_canal, nro_plataforma, nick_membro) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % inscrições de membros criadas', v_count;
    
    -- ============================================
    -- NÍVEL 11: VIDEOS (300-3000)
    -- ============================================
    
    RAISE NOTICE 'Populando Video (objetivo: % vídeos)...', qtd_base * 3;
    INSERT INTO Video (nome_canal, nro_plataforma, titulo, dataH, tema, duracao, visu_simul, visu_total)
    SELECT 
        c.nome,
        c.nro_plataforma,
        (ARRAY['Gameplay', 'Tutorial', 'Review', 'Live', 'Highlights', 'Unboxing', 'Q&A', 'Vlog',
               'Tips', 'Guide', 'Walkthrough', 'Reaction', 'Analysis', 'Commentary'])[1 + (RANDOM() * 13)::INTEGER] 
            || ' ' || (ARRAY['Part', 'Episode', 'Vol', '#'])[1 + (RANDOM() * 3)::INTEGER]
            || ' ' || v.num,
        c.data + (RANDOM() * 365 * 3)::INTEGER * INTERVAL '1 day' + (RANDOM() * 24)::INTEGER * INTERVAL '1 hour',
        (ARRAY['Gaming', 'Technology', 'Music', 'Sports', 'Education', 'Entertainment', 
               'News', 'Comedy', 'Science', 'Art'])[1 + (RANDOM() * 9)::INTEGER],
        (300 + RANDOM() * 7200)::INTEGER,
        (10 + RANDOM() * 10000)::INTEGER,
        (100 + RANDOM() * 1000000)::INTEGER
    FROM Canal c
    CROSS JOIN generate_series(1, GREATEST(3, (qtd_base * 3) / (SELECT COUNT(*) FROM Canal))) v(num)
    LIMIT qtd_base * 3
    ON CONFLICT (nome_canal, nro_plataforma, titulo, dataH) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % vídeos criados', v_count;
    
    -- ============================================
    -- NÍVEL 12: PARTICIPA (100-1000)
    -- ============================================
    
    RAISE NOTICE 'Populando Participa (objetivo: % participações)...', GREATEST(100, qtd_base);
    INSERT INTO Participa (id_video, nick_streamer)
    SELECT DISTINCT ON (v.id_video, s.nick_streamer)
        v.id_video,
        s.nick_streamer
    FROM Video v
    CROSS JOIN LATERAL (
        SELECT nick_streamer 
        FROM StreamerPais 
        ORDER BY RANDOM() 
        LIMIT 1 + (RANDOM() * 3)::INTEGER
    ) s
    LIMIT GREATEST(100, qtd_base)
    ON CONFLICT (id_video, nick_streamer) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % participações em vídeos', v_count;
    
    -- ============================================
    -- NÍVEL 13: COMENTARIOS (200-2000)
    -- ============================================
    
    RAISE NOTICE 'Populando Comentario (objetivo: % comentários)...', qtd_base * 2;
    INSERT INTO Comentario (id_video, nick_usuario, seq, texto, dataH, coment_on)
    SELECT 
        v.id_video,
        u.nick,
        ROW_NUMBER() OVER (PARTITION BY v.id_video, u.nick ORDER BY RANDOM()),
        (ARRAY['Ótimo vídeo!', 'Muito bom!', 'Adorei o conteúdo', 'Parabéns!', 'Incrível!', 
               'Top demais', 'Que show!', 'Sensacional', 'Conteúdo de qualidade', 'Continue assim!',
               'Melhor canal!', 'Subscribed!', 'Like merecido', 'Awesome!', 'Perfect!'])[1 + (RANDOM() * 14)::INTEGER],
        v.dataH + (RANDOM() * 30)::INTEGER * INTERVAL '1 day',
        RANDOM() < 0.7
    FROM Video v
    CROSS JOIN LATERAL (
        SELECT nick 
        FROM Usuario 
        ORDER BY RANDOM() 
        LIMIT GREATEST(1, (qtd_base * 2) / (SELECT COUNT(*) FROM Video))
    ) u
    LIMIT qtd_base * 2
    ON CONFLICT (id_video, nick_usuario, seq) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % comentários criados', v_count;
    
    -- ============================================
    -- NÍVEL 14: DOACOES (100-1000)
    -- ============================================
    
    RAISE NOTICE 'Populando Doacao (objetivo: % doações)...', GREATEST(100, qtd_base);
    INSERT INTO Doacao (id_comentario, seq_pg, valor, status)
    SELECT 
        c.id_comentario,
        1,
        (5.0 + RANDOM() * 495)::NUMERIC(15,2),
        (ARRAY['recusado', 'recebido', 'lido'])[1 + (RANDOM() * 4)::INTEGER]
    FROM Comentario c
    ORDER BY RANDOM()
    LIMIT GREATEST(100, qtd_base)
    ON CONFLICT (id_comentario, seq_pg) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % doações criadas', v_count;
    
    -- ============================================
    -- NÍVEL 15: ESPECIALIZACOES DE DOACAO
    -- ============================================
    
    RAISE NOTICE 'Populando especializações de Doacao...';
    
    -- BitCoin (25%)
    INSERT INTO BitCoin (id_doacao, TxID)
    SELECT 
        d.id_doacao,
        MD5(RANDOM()::TEXT || d.id_doacao::TEXT)
    FROM Doacao d
    WHERE RANDOM() < 0.25
    ON CONFLICT (id_doacao) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % doações Bitcoin', v_count;
    
    -- PayPal (25%)
    INSERT INTO PayPal (id_doacao, IdPayPal)
    SELECT 
        d.id_doacao,
        'PAYPAL-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 17))
    FROM Doacao d
    WHERE NOT EXISTS (SELECT 1 FROM BitCoin b WHERE b.id_doacao = d.id_doacao)
        AND RANDOM() < 0.33
    ON CONFLICT (id_doacao) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % doações PayPal', v_count;
    
    -- CartaoCredito (25%)
    INSERT INTO CartaoCredito (id_doacao, nro, bandeira, dataH)
    SELECT 
        d.id_doacao,
        LPAD((RANDOM() * 9999999999999999::BIGINT)::TEXT, 16, '0'),
        (ARRAY['Visa', 'Mastercard', 'American Express', 'Elo'])[1 + (RANDOM() * 3)::INTEGER],
        NOW() - (RANDOM() * 365)::INTEGER * INTERVAL '1 day'
    FROM Doacao d
    WHERE NOT EXISTS (SELECT 1 FROM BitCoin b WHERE b.id_doacao = d.id_doacao)
        AND NOT EXISTS (SELECT 1 FROM PayPal p WHERE p.id_doacao = d.id_doacao)
        AND RANDOM() < 0.5
    ON CONFLICT (id_doacao) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % doações Cartão de Crédito', v_count;
    
    -- MecanismoPlat (restante ~25%)
    INSERT INTO MecanismoPlat (id_doacao, nro_plataforma, seq_plataforma)
    SELECT 
        d.id_doacao,
        (SELECT nro FROM Plataforma ORDER BY RANDOM() LIMIT 1),
        (RANDOM() * 1000000)::INTEGER
    FROM Doacao d
    WHERE NOT EXISTS (SELECT 1 FROM BitCoin b WHERE b.id_doacao = d.id_doacao)
        AND NOT EXISTS (SELECT 1 FROM PayPal p WHERE p.id_doacao = d.id_doacao)
        AND NOT EXISTS (SELECT 1 FROM CartaoCredito cc WHERE cc.id_doacao = d.id_doacao)
    ON CONFLICT (id_doacao) DO NOTHING;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> % doações via Mecanismo da Plataforma', v_count;
    
    -- ============================================
    -- RESUMO FINAL
    -- ============================================
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'POPULAÇÃO CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Resumo de registros criados:';
    RAISE NOTICE '----------------------------------------';
    
    SELECT COUNT(*) INTO v_count FROM Conversao;
    RAISE NOTICE 'Conversao: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Pais;
    RAISE NOTICE 'Pais: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Empresa;
    RAISE NOTICE 'Empresa: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM EmpresaPais;
    RAISE NOTICE 'EmpresaPais: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Plataforma;
    RAISE NOTICE 'Plataforma: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Usuario;
    RAISE NOTICE 'Usuario: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM StreamerPais;
    RAISE NOTICE 'StreamerPais: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM PlataformaUsuario;
    RAISE NOTICE 'PlataformaUsuario: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Canal;
    RAISE NOTICE 'Canal: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM NivelCanal;
    RAISE NOTICE 'NivelCanal: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Patrocinio;
    RAISE NOTICE 'Patrocinio: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Inscricao;
    RAISE NOTICE 'Inscricao: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Video;
    RAISE NOTICE 'Video: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Participa;
    RAISE NOTICE 'Participa: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Comentario;
    RAISE NOTICE 'Comentario: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM Doacao;
    RAISE NOTICE 'Doacao: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM BitCoin;
    RAISE NOTICE 'BitCoin: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM PayPal;
    RAISE NOTICE 'PayPal: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM CartaoCredito;
    RAISE NOTICE 'CartaoCredito: %', v_count;
    
    SELECT COUNT(*) INTO v_count FROM MecanismoPlat;
    RAISE NOTICE 'MecanismoPlat: %', v_count;
    
    RAISE NOTICE '========================================';
    
END;
