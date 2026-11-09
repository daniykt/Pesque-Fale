-- de_volta: snapshot do momento do follow. Fica true quando o destinatário da
-- notificação já seguia o autor no instante em que foi seguido (seguir de volta).
-- Não é recalculado na leitura.
ALTER TABLE notificacoes ADD COLUMN IF NOT EXISTS de_volta BOOLEAN NOT NULL DEFAULT false;
