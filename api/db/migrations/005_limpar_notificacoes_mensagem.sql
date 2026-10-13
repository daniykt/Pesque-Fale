-- Migration 005: apaga notificações antigas do tipo 'mensagem'.
--
-- Pareada com a remoção de criarNotificacaoMensagem em
-- src/modules/chat/chat.gateway.js (sub-task 8.4.4) e com o filtro
-- no front (sub-task 8.4.1): mensagens de chat agora têm sua própria
-- aba (Chat) com badge próprio no bottom nav. A aba Alertas passa a
-- mostrar apenas interações sociais (seguir, curtir, comentar).
--
-- Essa limpeza garante que o endpoint GET /notificacoes/nao-lidas
-- pare de contar mensagens antigas que ainda estavam no banco.

DELETE FROM notificacoes WHERE tipo = 'mensagem';
