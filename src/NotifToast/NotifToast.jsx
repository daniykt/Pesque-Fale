import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { db } from '../../firebase';
import {
  collection,
  query,
  where,
  onSnapshot,
  orderBy,
  limit,
} from 'firebase/firestore';
import { observeAuthState } from '../../auth';
import './NotifToast.css';

// ── Duração do toast em ms (4 s) ──
const TOAST_DURATION = 4000;
// ── Quanto tempo após montar ignoramos notifs antigas (ms) ──
const GRACE_MS = 2000;

// ── Ícone e cor por tipo ──
const TIPO_CONFIG = {
  seguindo:    { icon: 'person_add',  label: 'Novo seguidor',   avatarClass: 'seguidor',   tipoClass: 'seguidor'   },
  curtida:     { icon: 'favorite',    label: 'Curtiu sua post', avatarClass: 'curtida',    tipoClass: 'curtida'    },
  comentario:  { icon: 'chat_bubble', label: 'Comentou',        avatarClass: 'comentario', tipoClass: 'comentario' },
  mensagem:    { icon: 'send',        label: 'Nova mensagem',   avatarClass: 'mensagem',   tipoClass: 'mensagem'   },
};

// ── Ações rápidas por tipo ──
const ACOES_RAPIDAS = {
  seguindo: [
    { label: 'Ver perfil', action: 'perfil', icon: 'person' },
  ],
  curtida: [
    { label: 'Ver post', action: 'post', icon: 'open_in_new' },
  ],
  comentario: [
    { label: 'Responder', action: 'post', icon: 'reply' },
  ],
  mensagem: [
    { label: 'Responder', action: 'chat', icon: 'reply' },
  ],
};

function iniciais(nome = '') {
  return nome
    .split(' ')
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join('');
}

export default function NotifToast() {
  const navigate    = useNavigate();
  const location    = useLocation();
  const [user, setUser]     = useState(null);
  const [toasts, setToasts] = useState([]);   // array de { id, notif, saidoMs }

  // Controla quando o componente montou (para ignorar notifs antigas)
  const mountedAtRef    = useRef(null);
  // IDs já vistos para não re-exibir
  const seenIdsRef      = useRef(new Set());
  // timers de auto-fechamento: { [toastId]: timeoutId }
  const timersRef       = useRef({});
  // id incrementável para chave única
  const toastCounterRef = useRef(0);

  // 🔐 Auth
  useEffect(() => {
    const unsub = observeAuthState((u) => {
      setUser(u);
      if (!u) {
        setToasts([]);
        seenIdsRef.current.clear();
        Object.values(timersRef.current).forEach(clearTimeout);
        timersRef.current = {};
      }
    });
    return unsub;
  }, []);

  // ── Remove toast pelo ID interno ──
  const remover = useCallback((toastId) => {
    clearTimeout(timersRef.current[toastId]);
    delete timersRef.current[toastId];
    // marca como "saindo" para animar saída
    setToasts((prev) =>
      prev.map((t) => (t.toastId === toastId ? { ...t, saindo: true } : t))
    );
    // remove do DOM depois da animação
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.toastId !== toastId));
    }, 380);
  }, []);

  // ── Agenda auto-fechamento ──
  const agendarFechamento = useCallback((toastId) => {
    timersRef.current[toastId] = setTimeout(() => remover(toastId), TOAST_DURATION);
  }, [remover]);

  // ── Pausar timer ao hover ──
  const pausar = useCallback((toastId) => {
    clearTimeout(timersRef.current[toastId]);
  }, []);

  const retomar = useCallback((toastId) => {
    agendarFechamento(toastId);
  }, [agendarFechamento]);

  // 🔔 Listener Firestore
  useEffect(() => {
    if (!user) return;

    mountedAtRef.current = Date.now();

    const q = query(
      collection(db, 'notificacoes'),
      where('para', '==', user.uid),
      orderBy('createdAt', 'desc'),
      limit(20)
    );

    const unsub = onSnapshot(q, (snapshot) => {
      // Ignora durante o período de graça (evita exibir notifs antigas ao montar)
      const agora = Date.now();
      if (agora - mountedAtRef.current < GRACE_MS) {
        snapshot.docs.forEach((d) => seenIdsRef.current.add(d.id));
        return;
      }

      snapshot.docChanges().forEach((change) => {
        if (change.type !== 'added') return;
        const notifId = change.doc.id;

        // Já vimos?
        if (seenIdsRef.current.has(notifId)) return;
        seenIdsRef.current.add(notifId);

        const notif = { id: notifId, ...change.doc.data() };

        // Suprime se estiver na tela de notificação
        if (location.pathname.startsWith('/notificacao')) return;

        const toastId = ++toastCounterRef.current;
        setToasts((prev) => {
          // Máximo de 3 toasts visíveis ao mesmo tempo
          const novos = prev.length >= 3 ? prev.slice(1) : prev;
          return [...novos, { toastId, notif, saindo: false }];
        });
        // agenda fechamento num próximo tick (depois de setToasts)
        setTimeout(() => agendarFechamento(toastId), 50);
      });
    });

    return unsub;
  }, [user, location.pathname, agendarFechamento]);

  // Se não há toasts, nada a renderizar
  if (toasts.length === 0) return null;

  return (
    <div className="notif-toast-stack" aria-live="polite" aria-label="Notificações">
      {toasts.map(({ toastId, notif, saindo }) => {
        const cfg     = TIPO_CONFIG[notif.tipo] || TIPO_CONFIG.seguindo;
        const acoes   = ACOES_RAPIDAS[notif.tipo] || [];

        const handleClick = () => {
          remover(toastId);
          navigate('/notificacao');
        };

        const handleAcao = (e, acao) => {
          e.stopPropagation();
          remover(toastId);
          switch (acao) {
            case 'perfil':
              if (notif.deId) navigate(`/perfil/${notif.deId}`);
              else navigate('/notificacao');
              break;
            case 'post':
              if (notif.postId && notif.deId) navigate(`/post/${notif.deId}/${notif.postId}`);
              else navigate('/notificacao');
              break;
            case 'chat':
              if (notif.chatId) navigate(`/chat/${notif.chatId}`);
              else navigate('/chat');
              break;
            default:
              navigate('/notificacao');
          }
        };

        return (
          <div
            key={toastId}
            className={`notif-toast ${saindo ? 'notif-toast--saindo' : 'notif-toast--entrando'}`}
            role="alert"
            onClick={handleClick}
            onMouseEnter={() => pausar(toastId)}
            onMouseLeave={() => retomar(toastId)}
          >
            {/* Barra de progresso */}
            <div className="notif-toast__progress" style={{ animationDuration: `${TOAST_DURATION}ms` }} />

            {/* Avatar */}
            <div className={`notif-toast__avatar ${cfg.avatarClass}`}>
              {iniciais(notif.de)}
              <span className={`notif-toast__tipo-icon ${cfg.tipoClass}`}>
                <span className="material-symbols-outlined">{cfg.icon}</span>
              </span>
            </div>

            {/* Corpo */}
            <div className="notif-toast__body">
              <p className="notif-toast__text">
                <strong>{notif.de}</strong>{' '}
                {gerarTexto(notif)}
              </p>
              {notif.texto && (
                <span className="notif-toast__quote">{notif.texto}</span>
              )}

              {/* Ações rápidas */}
              {acoes.length > 0 && (
                <div className="notif-toast__acoes">
                  {acoes.map((a) => (
                    <button
                      key={a.action}
                      className={`notif-toast__btn notif-toast__btn--${notif.tipo}`}
                      onClick={(e) => handleAcao(e, a.action)}
                    >
                      <span className="material-symbols-outlined">{a.icon}</span>
                      {a.label}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Fechar */}
            <button
              className="notif-toast__close"
              onClick={(e) => { e.stopPropagation(); remover(toastId); }}
              aria-label="Fechar notificação"
            >
              <span className="material-symbols-outlined">close</span>
            </button>
          </div>
        );
      })}
    </div>
  );
}

function gerarTexto(n) {
  switch (n.tipo) {
    case 'seguindo':    return 'começou a seguir você';
    case 'curtida':     return 'curtiu sua publicação';
    case 'comentario':  return 'comentou na sua publicação';
    case 'mensagem':    return 'te enviou uma mensagem';
    default:            return 'nova notificação';
  }
}