CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE publicacoes ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

CREATE TABLE IF NOT EXISTS curtidas (
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  publicacao_id UUID NOT NULL REFERENCES publicacoes(id) ON DELETE CASCADE,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (usuario_id, publicacao_id)
);
CREATE INDEX IF NOT EXISTS curtidas_publicacao_idx ON curtidas(publicacao_id);

CREATE OR REPLACE FUNCTION atualizar_curtidas_count() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE publicacoes SET curtidas_count = curtidas_count + 1 WHERE id = NEW.publicacao_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE publicacoes SET curtidas_count = GREATEST(curtidas_count - 1, 0) WHERE id = OLD.publicacao_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_curtidas_count ON curtidas;
CREATE TRIGGER trg_curtidas_count
AFTER INSERT OR DELETE ON curtidas
FOR EACH ROW EXECUTE FUNCTION atualizar_curtidas_count();

CREATE TABLE IF NOT EXISTS comentarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  publicacao_id UUID NOT NULL REFERENCES publicacoes(id) ON DELETE CASCADE,
  autor_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  texto TEXT NOT NULL CHECK (char_length(texto) BETWEEN 1 AND 500),
  criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS comentarios_publicacao_idx ON comentarios(publicacao_id, criado_em DESC);

CREATE OR REPLACE FUNCTION atualizar_comentarios_count() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE publicacoes SET comentarios_count = comentarios_count + 1 WHERE id = NEW.publicacao_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE publicacoes SET comentarios_count = GREATEST(comentarios_count - 1, 0) WHERE id = OLD.publicacao_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_comentarios_count ON comentarios;
CREATE TRIGGER trg_comentarios_count
AFTER INSERT OR DELETE ON comentarios
FOR EACH ROW EXECUTE FUNCTION atualizar_comentarios_count();
