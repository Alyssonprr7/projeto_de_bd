--Trigger para manter Plataforma.qtd_users atualizada
CREATE OR REPLACE FUNCTION trg_atualizar_qtd_users()
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

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.nro_plataforma IS DISTINCT FROM NEW.nro_plataforma THEN
            UPDATE Plataforma SET qtd_users = qtd_users - 1 WHERE nro = OLD.nro_plataforma;
            UPDATE Plataforma SET qtd_users = qtd_users + 1 WHERE nro = NEW.nro_plataforma;
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_atualizar_qtd_users
AFTER INSERT OR DELETE OR UPDATE ON PlataformaUsuario
FOR EACH ROW EXECUTE FUNCTION trg_atualizar_qtd_users();

--Trigger para manter Canal.qtd_visualizacoes atualizada
CREATE OR REPLACE FUNCTION trg_atualizar_visualizacoes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.visu_total <> OLD.visu_total THEN
        UPDATE Canal
        SET qtd_visualizacoes = qtd_visualizacoes + (NEW.visu_total - OLD.visu_total)
        WHERE nome = NEW.nome_canal
        AND nro_plataforma = NEW.nro_plataforma;

    ELSIF TG_OP = 'INSERT' THEN
     -- Adiciona visualizações do novo vídeo
        UPDATE Canal
        SET qtd_visualizacoes = qtd_visualizacoes + NEW.visu_total
        WHERE nome = NEW.nome_canal AND nro_plataforma = NEW.nro_plataforma;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_atualizar_visualizacoes
AFTER UPDATE OF visu_total ON Video
FOR EACH ROW EXECUTE FUNCTION trg_atualizar_visualizacoes();

CREATE TRIGGER tg_atualizar_visualizacoes_insert
AFTER INSERT ON Video
FOR EACH ROW EXECUTE FUNCTION trg_atualizar_visualizacoes();


--Trigger para garantir que patrocínios vigentes existam

CREATE OR REPLACE FUNCTION trg_patrocinio_unico()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Patrocinio
    WHERE nro_empresa = NEW.nro_empresa
      AND nome_canal = NEW.nome_canal
      AND nro_plataforma = NEW.nro_plataforma;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_patrocinio_unico
BEFORE INSERT ON Patrocinio
FOR EACH ROW EXECUTE FUNCTION trg_patrocinio_unico();


--Trigger para garantir que membros vigentes existam

CREATE OR REPLACE FUNCTION trg_inscricao_unica()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Inscricao
    WHERE nome_canal = NEW.nome_canal
      AND nro_plataforma = NEW.nro_plataforma
      AND nick_membro = NEW.nick_membro;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_inscricao_unica
BEFORE INSERT ON Inscricao
FOR EACH ROW EXECUTE FUNCTION trg_inscricao_unica();

--Trigger para gerar seq dos comentários
CREATE OR REPLACE FUNCTION trg_comentario_seq()
RETURNS TRIGGER AS $$
DECLARE
    maxseq INTEGER;
BEGIN
    SELECT COALESCE(MAX(seq), 0) INTO maxseq
    FROM Comentario
    WHERE nome_canal = NEW.nome_canal
      AND nro_plataforma = NEW.nro_plataforma
      AND titulo_video = NEW.titulo_video
      AND dataH_video = NEW.dataH_video;

    NEW.seq := maxseq + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_comentario_seq
BEFORE INSERT ON Comentario
FOR EACH ROW EXECUTE FUNCTION trg_comentario_seq();

--Trigger para seq_pg das doações
CREATE OR REPLACE FUNCTION trg_doacao_seqpg()
RETURNS TRIGGER AS $$
DECLARE
    maxseq INTEGER;
BEGIN
    SELECT COALESCE(MAX(seq_pg), 0) INTO maxseq
    FROM Doacao
    WHERE nome_canal = NEW.nome_canal
      AND nro_plataforma = NEW.nro_plataforma
      AND titulo_video = NEW.titulo_video
      AND dataH_video = NEW.dataH_video
      AND nick_usuario = NEW.nick_usuario
      AND seq_comentario = NEW.seq_comentario;

    NEW.seq_pg := maxseq + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_doacao_seqpg
BEFORE INSERT ON Doacao
FOR EACH ROW EXECUTE FUNCTION trg_doacao_seqpg();

--Trigger para validar subtipo de doação
CREATE OR REPLACE FUNCTION trg_validar_doacao_subtipo()
RETURNS TRIGGER AS $$
DECLARE
    existe INT;
BEGIN
    SELECT COUNT(*) INTO existe
    FROM Doacao
    WHERE nome_canal = NEW.nome_canal
      AND nro_plataforma = NEW.nro_plataforma
      AND titulo_video = NEW.titulo_video
      AND dataH_video = NEW.dataH_video
      AND nick_usuario = NEW.nick_usuario
      AND seq_comentario = NEW.seq_comentario
      AND seq_pg = NEW.seq_doacao;

    IF existe = 0 THEN
        RAISE EXCEPTION 'Doação base não existe. Subtipo inválido.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_bitcoin
BEFORE INSERT ON BitCoin
FOR EACH ROW EXECUTE FUNCTION trg_validar_doacao_subtipo();

CREATE TRIGGER tg_validar_paypal
BEFORE INSERT ON PayPal
FOR EACH ROW EXECUTE FUNCTION trg_validar_doacao_subtipo();

CREATE TRIGGER tg_validar_cartao
BEFORE INSERT ON CartaoCredito
FOR EACH ROW EXECUTE FUNCTION trg_validar_doacao_subtipo();

CREATE TRIGGER tg_validar_mecanismo
BEFORE INSERT ON MecanismoPlat
FOR EACH ROW EXECUTE FUNCTION trg_validar_doacao_subtipo();
