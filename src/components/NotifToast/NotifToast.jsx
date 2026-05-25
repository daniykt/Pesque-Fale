import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { db } from '../../firebase';
import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  getDoc,
} from 'firebase/firestore';
import { observeAuthState } from '../../auth';
import './NotifToast.css';

// ── Duração do toast em ms (4 s) ──
const TOAST_DURATION = 4000;
// ── Janela de graça ao montar: ignora notifs mais antigas que X ms ──
const GRACE_MS = 2500;

// ── Configuração visual por tipo ──
const TIPO_CONFIG = {
  seguindo:    { icon: 'person_add',  avatarClass: 'seguidor',   tipoClass: 'seguidor'   },
  curtida:     { icon: 'favorite',    avatarClass: 'curtida',    tipoClass: 'curtida'    },
  comentario:  { icon: 'chat_bubble', avatarClass: 'comentario', tipoClass: 'comentario' },
  mensagem:    { icon: 'send',        avatarClass: 'mensagem',   tipoClass: 'mensagem'   },
};

// ── Ações contextuais por tipo
// Campos reais no Firestore (após correção dos arquivos abaixo):
//   seguindo:   { de, deId, para, tipo, createdAt }
//   curtida:    { de, deId, para, tipo, postId, createdAt, lida }
//   comentario: { de, deId, para, tipo, texto, postId, createdAt, lida }
//   mensagem:   { de, deId, para, tipo, texto, chatId, createdAt, lida }
const ACOES_RAPIDAS = {
  seguindo:   [{ label: 'Ver perfil', action: 'perfil',  icon: 'person'      }],
  curtida:    [{ label: 'Ver post',   action: 'post',    icon: 'open_in_new' }],
  comentario: [{ label: 'Responder', action: 'post',    icon: 'reply'       }],
  mensagem:   [{ label: 'Responder', action: 'chat',    icon: 'reply'       }],
};

function iniciais(nome = '') {
  return nome
    .split(' ')
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join('');
}

function gerarTexto(n) {
  switch (n.tipo) {
    case 'seguindo':   return 'começou a seguir você';
    case 'curtida':    return 'curtiu sua publicação';
    case 'comentario': return 'comentou na sua publicação';
    case 'mensagem':   return 'te enviou uma mensagem';
    default:           return 'nova notificação';
  }
}

export default function NotifToast() {
  const navigate  = useNavigate();
  const location  = useLocation();

  const [user, setUser]     = useState(null);
  const [toasts, setToasts] = useState([]);

  const mountedAtRef    = useRef(null);
  const seenIdsRef      = useRef(new Set());
  const timersRef       = useRef({});
  const toastCounterRef = useRef(0);
  // Cache uid → fotoPerfil em memória: evita buscas repetidas para o mesmo remetente
  const fotoCacheRef    = useRef({});

  // Busca a foto do remetente com cache em memória.
  // Retorna null se não tiver foto ou se falhar — nunca bloqueia o toast.
  const fetchFoto = useCallback(async (uid) => {
    if (!uid) return null;
    if (uid in fotoCacheRef.current) return fotoCacheRef.current[uid];
    try {
      const snap = await getDoc(doc(db, 'usuarios', uid));
      const foto = snap.exists() ? snap.data().fotoPerfil || null : null;
      fotoCacheRef.current[uid] = foto;
      return foto;
    } catch {
      fotoCacheRef.current[uid] = null;
      return null;
    }
  }, []);

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

  // ── Remove toast com animação de saída ──
  const remover = useCallback((toastId) => {
    clearTimeout(timersRef.current[toastId]);
    delete timersRef.current[toastId];
    setToasts((prev) =>
      prev.map((t) => (t.toastId === toastId ? { ...t, saindo: true } : t))
    );
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.toastId !== toastId));
    }, 380);
  }, []);

  // ── Agenda fechamento automático ──
  const agendarFechamento = useCallback((toastId) => {
    timersRef.current[toastId] = setTimeout(() => remover(toastId), TOAST_DURATION);
  }, [remover]);

  const pausar  = useCallback((toastId) => clearTimeout(timersRef.current[toastId]), []);
  const retomar = useCallback((toastId) => agendarFechamento(toastId), [agendarFechamento]);

  // 🔔 Listener Firestore — apenas notificações novas
  useEffect(() => {
    if (!user) return;

    mountedAtRef.current = Date.now();

    // Sem orderBy — evita exigir índice composto no Firestore.
    // O toast só reage a 'added' via docChanges(), ordem não importa.
    const q = query(
      collection(db, 'notificacoes'),
      where('para', '==', user.uid)
    );

    const unsub = onSnapshot(q, (snapshot) => {
      const agora = Date.now();

      // Período de graça: popula seenIds sem exibir toasts (evita notifs antigas ao montar)
      if (agora - mountedAtRef.current < GRACE_MS) {
        snapshot.docs.forEach((d) => seenIdsRef.current.add(d.id));
        return;
      }

      snapshot.docChanges().forEach((change) => {
        if (change.type !== 'added') return;

        const notifId = change.doc.id;
        if (seenIdsRef.current.has(notifId)) return;
        seenIdsRef.current.add(notifId);

        const notif = { id: notifId, ...change.doc.data() };
        // Normaliza: aceita tanto de_id (padrão) quanto deId (legado)
        const remetenteId = notif.de_id ?? notif.deId ?? null;

        // ── Suprime o toast se o usuário já estiver na tela de notificações ──
        if (location.pathname.startsWith('/notificacao')) return;

        // ── Suprime o toast se o usuário já estiver na conversa que gerou a notificação ──
        if (notif.tipo === 'mensagem') {
          const chatAtual = location.pathname.startsWith('/chat/')
            ? location.pathname.split('/chat/')[1]
            : null;
          const chatDaNotif =
            notif.chatId ||
            [notif.deId ?? notif.de_id, user.uid].sort().join('_');
          if (chatAtual && chatAtual === chatDaNotif) return;
        }

        const toastId = ++toastCounterRef.current;

        // Busca a foto e só então enfileira o toast — a espera é rápida
        // pois o cache em memória evita round-trips repetidos.
        fetchFoto(remetenteId).then((fotoPerfil) => {
          setToasts((prev) => {
            const base = prev.length >= 3 ? prev.slice(1) : prev;
            return [...base, { toastId, notif, fotoPerfil, saindo: false }];
          });
          setTimeout(() => agendarFechamento(toastId), 50);
        });
      });
    });

    return unsub;
  }, [user, location.pathname, agendarFechamento, fetchFoto]);

  // ── Clique no corpo: vai para /notificacao ──
  const handleClickCorpo = useCallback((toastId) => {
    remover(toastId);
    navigate('/notificacao');
  }, [remover, navigate]);

  // ── Clique na ação contextual ──
  const handleAcao = useCallback((e, toastId, acao, notif) => {
    e.stopPropagation();
    remover(toastId);

    switch (acao) {
      case 'perfil':
        // seguindo → deId = uid de quem passou a seguir
        navigate(notif.deId ? `/perfil/${notif.deId}` : '/notificacao');
        break;

      case 'post':
        // curtida / comentario → deId (dono do post = userId na rota) + postId
        // Rota: /post/:userId/:postId — userId aqui é quem sofreu a ação (notif.para)
        // mas a rota espera o dono do post, que é notif.para (o destinatário da notif)
        if (notif.postId) {
          navigate(`/post/${notif.para}/${notif.postId}`);
        } else {
          navigate('/notificacao');
        }
        break;

      case 'chat':
        // mensagem → chatId salvo diretamente OU derivado de deId + user.uid
        if (notif.chatId) {
          navigate(`/chat/${notif.chatId}`);
        } else if (notif.deId && user?.uid) {
          const chatId = [notif.deId, user.uid].sort().join('_');
          navigate(`/chat/${chatId}`);
        } else {
          navigate('/chat');
        }
        break;

      default:
        navigate('/notificacao');
    }
  }, [remover, navigate, user]);

  if (toasts.length === 0) return null;

  return (
    <div className="notif-toast-stack" aria-live="polite" aria-label="Notificações">
      {toasts.map(({ toastId, notif, fotoPerfil, saindo }) => {
        const cfg   = TIPO_CONFIG[notif.tipo] || TIPO_CONFIG.seguindo;
        const acoes = ACOES_RAPIDAS[notif.tipo] || [];

        return (
          <div
            key={toastId}
            className={`notif-toast ${saindo ? 'notif-toast--saindo' : 'notif-toast--entrando'}`}
            role="alert"
            onClick={() => handleClickCorpo(toastId)}
            onMouseEnter={() => pausar(toastId)}
            onMouseLeave={() => retomar(toastId)}
          >
            {/* Barra de progresso */}
            <div
              className="notif-toast__progress"
              style={{ animationDuration: `${TOAST_DURATION}ms` }}
            />

            {/* Avatar */}
            <div className={`notif-toast__avatar ${cfg.avatarClass}`}>
              {fotoPerfil ? (
                <img
                  src={fotoPerfil}
                  alt={notif.de}
                  className="notif-toast__avatar-img"
                />
              ) : (
                <span className="notif-toast__avatar-iniciais">{iniciais(notif.de)}</span>
              )}
              <span className={`notif-toast__tipo-icon ${cfg.tipoClass}`}>
                <span className="material-symbols-outlined">{cfg.icon}</span>
              </span>
            </div>

            {/* Corpo */}
            <div className="notif-toast__body">
<p className="notif-toast__text">
  <strong>
    {notif.de}
    {notif.de_username && (
      <span style={{ fontWeight: 400, fontSize: "0.85em", marginLeft: "5px" }}>
        @{notif.de_username}
      </span>
    )}
  </strong> {gerarTexto(notif)}
</p>
              {notif.texto && (
                <span className="notif-toast__quote">{notif.texto}</span>
              )}

              {acoes.length > 0 && (
                <div className="notif-toast__acoes">
                  {acoes.map((a) => (
                    <button
                      key={a.action}
                      className={`notif-toast__btn notif-toast__btn--${notif.tipo}`}
                      onClick={(e) => handleAcao(e, toastId, a.action, notif)}
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