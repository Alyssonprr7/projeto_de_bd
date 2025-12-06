-- Trigger para Atualizar qtd_users da Plataforma

CREATE OR REPLACE FUNCTION atualizar_qtd_users_plataforma()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Plataforma 
        SET qtd_users = qtd_users + 1
        WHERE nro = NEW.nro_plataforma;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Plataforma 
        SET qtd_users = qtd_users - 1
        WHERE nro = OLD.nro_plataforma;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualizar_qtd_users_plataforma
AFTER INSERT OR DELETE ON PlataformaUsuario
FOR EACH ROW EXECUTE FUNCTION atualizar_qtd_users_plataforma();


-- Trigger para Atualizar qtd_visualizacoes do Canal

CREATE OR REPLACE FUNCTION atualizar_visualizacoes_canal()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Canal 
    SET qtd_visualizacoes = (
        SELECT COALESCE(SUM(visu_total), 0)
        FROM Video 
        WHERE nome_canal = COALESCE(NEW.nome_canal, OLD.nome_canal)
        AND nro_plataforma = COALESCE(NEW.nro_plataforma, OLD.nro_plataforma)
    )
    WHERE nome = COALESCE(NEW.nome_canal, OLD.nome_canal)
    AND nro_plataforma = COALESCE(NEW.nro_plataforma, OLD.nro_plataforma);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualizar_visualizacoes_canal
AFTER INSERT OR UPDATE OR DELETE ON Video
FOR EACH ROW EXECUTE FUNCTION atualizar_visualizacoes_canal();

-- Trigger para Conversão Automática de Valores em Dólar

CREATE OR REPLACE FUNCTION converter_valor_dolar()
RETURNS TRIGGER AS $$
DECLARE
    fator_conversao DECIMAL;
    pais_ddi VARCHAR;
BEGIN
    -- Obter DDI do país da empresa
    SELECT ep.ddi_pais INTO pais_ddi
    FROM EmpresaPais ep
    WHERE ep.nro_empresa = NEW.nro_empresa
    LIMIT 1;
        
    -- Obter fator de conversão
    SELECT c.fator_conver INTO fator_conversao
    FROM Pais p
    JOIN Conversao c ON p.moeda = c.moeda
    WHERE p.DDI = pais_ddi;
        
    -- Armazenar valor convertido em coluna adicional
    NEW.valor_dolar := NEW.valor * fator_conversao;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_converter_patrocinio_dolar
BEFORE INSERT ON Patrocinio
FOR EACH ROW EXECUTE FUNCTION converter_valor_dolar();


-- Trigger para Validação de Streamer no Canal
CREATE OR REPLACE FUNCTION validar_streamer_canal()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM StreamerPais 
        WHERE nick_streamer = NEW.nick_streamer
    ) THEN
        RAISE EXCEPTION 'Usuário % não é um streamer registrado', NEW.nick_streamer;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_streamer_canal
BEFORE INSERT ON Canal
FOR EACH ROW EXECUTE FUNCTION validar_streamer_canal();


-- Trigger para Validação de Doação com Base na Inscrição
CREATE OR REPLACE FUNCTION validar_doacao()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Inscricao i
        JOIN NivelCanal nc ON i.nome_canal = nc.nome_canal 
            AND i.nro_plataforma = nc.nro_plataforma 
            AND i.nivel = nc.nivel
        WHERE i.nick_membro = NEW.nick_usuario
        AND i.nome_canal = NEW.nome_canal
        AND i.nro_plataforma = NEW.nro_plataforma
    ) THEN
        RAISE EXCEPTION 'Usuário não possui inscrição, portanto não pode realizar a doação';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_doacao
BEFORE INSERT ON Doacao
FOR EACH ROW EXECUTE FUNCTION validar_doacao();



-- Trigger para Gerenciar Hierarquia de Comentários
CREATE OR REPLACE FUNCTION gerenciar_hierarquia_comentario()
RETURNS TRIGGER AS $$
BEGIN
    -- Validar se comentário pai existe
    IF NEW.coment_on IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM Comentario 
            WHERE nome_canal = NEW.nome_canal
            AND nro_plataforma = NEW.nro_plataforma
            AND titulo_video = NEW.titulo_video
            AND dataH_video = NEW.dataH_video
            AND seq = NEW.coment_on
        ) THEN
            RAISE EXCEPTION 'Comentário pai não existe';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerenciar_hierarquia_comentario
BEFORE INSERT ON Comentario
FOR EACH ROW EXECUTE FUNCTION gerenciar_hierarquia_comentario();