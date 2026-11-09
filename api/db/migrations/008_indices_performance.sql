-- 008 — Índices para as consultas frequentes sem índice (Task 10.4.4, #276).
-- Idempotente: IF NOT EXISTS. Sem CONCURRENTLY porque o migrate.js roda cada
-- migration numa transação (tabelas pequenas, o lock é instantâneo).

-- Feed "Para você": ORDER BY criado_em DESC sem filtro.
CREATE INDEX IF NOT EXISTS publicacoes_criado_em_idx
  ON public.publicacoes USING btree (criado_em DESC);

-- Seguidores de um usuário: contagem, lista ordenada e notificação ao publicar.
CREATE INDEX IF NOT EXISTS usuario_seguidores_seguido_id_criado_em_idx
  ON public.usuario_seguidores USING btree (seguido_id, criado_em DESC);

-- Avaliações de um ponto: lista ordenada e contagem.
CREATE INDEX IF NOT EXISTS avaliacoes_ponto_id_criado_em_idx
  ON public.avaliacoes USING btree (ponto_id, criado_em DESC);

-- Lista de conversas: o lado participante_b não é coberto pela UNIQUE (a, b).
CREATE INDEX IF NOT EXISTS chats_participante_b_idx
  ON public.chats USING btree (participante_b);
