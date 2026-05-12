import React, { useEffect, useRef, useState } from "react";
import Layout from "../../components/sidebar/layout";
import "./notificacao.css";

import { db } from "../../firebase";
import {
  collection,
  query,
  where,
  onSnapshot,
  deleteDoc,
  doc,
  updateDoc,
  writeBatch,
  arrayUnion,
  arrayRemove,
  serverTimestamp,
  addDoc,
} from "firebase/firestore";

import { observeAuthState } from "../../auth";

const TEMPO_ARQUIVAR_MS = 5 * 60 * 1000;

const TIPOS = [
  { key: "todas",      label: "Todas",        icon: "notifications" },
  { key: "seguindo",   label: "Seguidores",   icon: "person_add" },
  { key: "curtida",    label: "Curtidas",     icon: "favorite" },
  { key: "comentario", label: "Comentários",  icon: "chat_bubble" },
  { key: "mensagem",   label: "Mensagens",    icon: "send" },
  { key: "arquivadas", label: "Arquivadas",   icon: "archive" },
];

export default function Notificacao() {
  const [user, setUser] = useState(null);
  const [notificacoes, setNotificacoes] = useState([]);
  const [arquivadas, setArquivadas] = useState([]);
  const [filtro, setFiltro] = useState("todas");

  const timersRef = useRef({});

  // Auth
  useEffect(() => {
    const unsubscribe = observeAuthState((u) => {
      setUser(u);
      if (!u) {
        setArquivadas([]);
        Object.values(timersRef.current).forEach(clearTimeout);
        timersRef.current = {};
      }
    });
    return unsubscribe;
  }, []);

  // Firestore realtime
  useEffect(() => {
    if (!user) return;
    // Sem orderBy — evita exigir índice composto no Firestore.
    // A ordenação é feita localmente abaixo, após receber os dados.
    const q = query(
      collection(db, "notificacoes"),
      where("para", "==", user.uid)
    );
    const unsub = onSnapshot(q, (snapshot) => {
      setNotificacoes((prev) => {
        const localMap = Object.fromEntries(prev.map((n) => [n.id, n]));
        const docs = snapshot.docs.map((d) => {
          const remoto = { id: d.id, ...d.data() };
          const local = localMap[d.id];
          if (local?.lida && !remoto.lida) return { ...remoto, lida: true };
          return remoto;
        });
        // Ordenação local por createdAt desc — evita índice composto no Firestore
        return docs.sort((a, b) => {
          const ta = a.createdAt?.seconds ?? 0;
          const tb = b.createdAt?.seconds ?? 0;
          return tb - ta;
        });
      });
    });
    return unsub;
  }, [user]);

  // Arquivamento automático
  useEffect(() => {
    notificacoes.forEach((n) => {
      if (
        n.lida &&
        !timersRef.current[n.id] &&
        !arquivadas.find((a) => a.id === n.id)
      ) {
        timersRef.current[n.id] = setTimeout(() => arquivar(n), TEMPO_ARQUIVAR_MS);
      }
      if (!n.lida && timersRef.current[n.id]) {
        clearTimeout(timersRef.current[n.id]);
        delete timersRef.current[n.id];
      }
    });
  }, [notificacoes]);

  const arquivar = async (notif) => {
    setArquivadas((prev) => {
      if (prev.find((a) => a.id === notif.id)) return prev;
      return [notif, ...prev];
    });
    setNotificacoes((prev) => prev.filter((n) => n.id !== notif.id));
    delete timersRef.current[notif.id];
    try {
      await deleteDoc(doc(db, "notificacoes", notif.id));
    } catch (e) {
      console.error("[arquivar] erro:", e);
    }
  };

  const excluirNotificacao = async (id) => {
    clearTimeout(timersRef.current[id]);
    delete timersRef.current[id];
    setNotificacoes((prev) => prev.filter((n) => n.id !== id));
    await deleteDoc(doc(db, "notificacoes", id));
  };

  const excluirArquivada = (id) => {
    setArquivadas((prev) => prev.filter((a) => a.id !== id));
  };

  const marcarComoLida = async (id, lida) => {
    if (lida) return;
    setNotificacoes((prev) =>
      prev.map((n) => (n.id === id ? { ...n, lida: true } : n))
    );
    await updateDoc(doc(db, "notificacoes", id), { lida: true });
  };

  const marcarTodasComoLidas = async () => {
    if (!user) return;
    const naoLidas = notificacoes.filter((n) => !n.lida);
    if (naoLidas.length === 0) return;
    setNotificacoes((prev) => prev.map((n) => ({ ...n, lida: true })));
    const batch = writeBatch(db);
    naoLidas.forEach((n) => batch.update(doc(db, "notificacoes", n.id), { lida: true }));
    await batch.commit();
  };

  // ── AÇÕES DA SOLICITAÇÃO ──
  // Aceitar = adiciona A nos seguidores de B + chat liberado automaticamente
  const aceitarSeguidor = async (notif) => {
    if (!notif) return;
    try {
      // Adiciona A nos seguidores de B
      await updateDoc(doc(db, "usuarios", notif.para), {
        seguidores: arrayUnion(notif.de_id),
      });
      // Notifica A — aceito como seguidor, chat liberado automaticamente
      await addDoc(collection(db, "notificacoes"), {
        tipo: "solicitacao_aceita_seguidor",
        de: user?.displayName || "Usuário",
        de_id: notif.para,
        para: notif.de_id,
        lida: false,
        createdAt: serverTimestamp(),
      });
      await deleteDoc(doc(db, "notificacoes", notif.id));
      setNotificacoes((prev) => prev.filter((n) => n.id !== notif.id));
    } catch (e) {
      console.error("Erro ao aceitar:", e);
    }
  };

  const recusarSolicitacao = async (notif) => {
    if (!notif) return;
    try {
      // Remove B do array "seguindo" de A — A não segue mais B
      await updateDoc(doc(db, "usuarios", notif.de_id), {
        seguindo: arrayRemove(notif.para),
      });
      // Notifica A de que foi recusado
      await addDoc(collection(db, "notificacoes"), {
        tipo: "solicitacao_recusada",
        de: user?.displayName || "Usuário",
        de_id: notif.para,   // B (quem recusou)
        para: notif.de_id,   // A (quem pediu)
        lida: false,
        createdAt: serverTimestamp(),
      });
      await deleteDoc(doc(db, "notificacoes", notif.id));
      setNotificacoes((prev) => prev.filter((n) => n.id !== notif.id));
    } catch (e) {
      console.error("Erro ao recusar:", e);
    }
  };

  // ── FUNÇÕES AUXILIARES ──
  const isHoje = (timestamp) => {
    if (!timestamp) return false;
    const data = new Date(timestamp.seconds * 1000);
    const agora = new Date();
    return (
      data.getDate() === agora.getDate() &&
      data.getMonth() === agora.getMonth() &&
      data.getFullYear() === agora.getFullYear()
    );
  };

  const tempoRelativo = (timestamp) => {
    if (!timestamp) return "";
    const agora = new Date();
    const data = new Date(timestamp.seconds * 1000);
    const diff = Math.floor((agora - data) / 1000);
    if (diff < 60) return "agora";
    if (diff < 3600) return `há ${Math.floor(diff / 60)} min`;
    if (diff < 86400) return `há ${Math.floor(diff / 3600)} h`;
    if (diff < 2592000) return `há ${Math.floor(diff / 86400)} dias`;
    return data.toLocaleDateString();
  };

  const renderTexto = (n) => {
    switch (n.tipo) {
      case "seguindo":
        return <><strong>{n.de}</strong> começou a seguir você</>;
      case "curtida":
        return <><strong>{n.de}</strong> curtiu sua publicação</>;
      case "comentario":
        return (
          <>
            <strong>{n.de}</strong> comentou na sua publicação
            {n.texto && <span className="notif-quote">"{n.texto}"</span>}
          </>
        );
      case "mensagem":
        return (
          <>
            <strong>{n.de}</strong> te enviou uma mensagem
            {n.texto && <span className="notif-quote">"{n.texto}"</span>}
          </>
        );
      case "solicitacao_seguir":
        return <><strong>{n.de}</strong> quer te seguir</>;
      case "solicitacao_aceita_seguidor":
        return <><strong>{n.de}</strong> aceitou sua solicitação — agora vocês podem conversar no chat</>;
      case "solicitacao_recusada":
        return <><strong>{n.de}</strong> recusou sua solicitação de seguir</>;
      default:
        return "Nova notificação";
    }
  };

  const avatarClass = (tipo) => {
    const map = {
      seguindo: "seguidor",
      curtida: "curtida",
      comentario: "comentario",
      mensagem: "mensagem",
      solicitacao_seguir: "seguidor",
      solicitacao_aceita_seguidor: "seguidor",
      solicitacao_aceita_chat: "seguidor",
      solicitacao_recusada: "seguidor",
    };
    return map[tipo] || "seguidor";
  };

  const iniciais = (nome = "") =>
    nome.split(" ").slice(0, 2).map((p) => p[0]?.toUpperCase()).join("");

  const contarNaoLidas = (tipo) => {
    const base = notificacoes.filter((n) => !n.lida);
    if (tipo === "todas") return base.length;
    if (tipo === "arquivadas") return 0;
    // Incluir todos os tipos de seguidores
    if (tipo === "seguindo") {
      return base.filter((n) =>
        ["seguindo", "solicitacao_seguir", "solicitacao_aceita_seguidor", "solicitacao_aceita_chat", "solicitacao_recusada"].includes(n.tipo)
      ).length;
    }
    return base.filter((n) => n.tipo === tipo).length;
  };

  // ── FILTRO ──
  const filtrarNotificacoes = () => {
    if (filtro === "arquivadas") return [];
    if (filtro === "todas") return notificacoes;
    if (filtro === "seguindo") {
      return notificacoes.filter((n) =>
        ["seguindo", "solicitacao_seguir", "solicitacao_aceita_seguidor", "solicitacao_aceita_chat", "solicitacao_recusada"].includes(n.tipo)
      );
    }
    return notificacoes.filter((n) => n.tipo === filtro);
  };

  const notifFiltradas = filtrarNotificacoes();
  const hoje = notifFiltradas.filter((n) => isHoje(n.createdAt));
  const anteriores = notifFiltradas.filter((n) => !isHoje(n.createdAt));
  const estaEmArquivadas = filtro === "arquivadas";

  useEffect(() => {
    return () => Object.values(timersRef.current).forEach(clearTimeout);
  }, []);

  return (
    <Layout>
      <div className="notif-wrapper">
        {/* Abas */}
        <div className="notif-header">
          <div className="notif-tabs">
            {TIPOS.map((t) => {
              const count = contarNaoLidas(t.key);
              const isArq = t.key === "arquivadas";
              return (
                <button
                  key={t.key}
                  className={`notif-tab ${filtro === t.key ? "active" : ""} ${isArq ? "tab-arquivadas" : ""}`}
                  onClick={() => setFiltro(t.key)}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 16 }}>
                    {t.icon}
                  </span>
                  {t.label}
                  {isArq && arquivadas.length > 0 && (
                    <span className="tab-badge tab-badge--arquivo">{arquivadas.length}</span>
                  )}
                  {!isArq && count > 0 && (
                    <span className="tab-badge">{count}</span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Lista */}
        <div className="container-notificacoes">
          {!estaEmArquivadas && (
            <>
              {hoje.length > 0 && (
                <>
                  <span className="section-label">Hoje</span>
                  <div className="notif-section">
                    {hoje.map((n) => (
                      <CardNotificacao
                        key={n.id}
                        n={n}
                        avatarClass={avatarClass}
                        iniciais={iniciais}
                        renderTexto={renderTexto}
                        tempoRelativo={tempoRelativo}
                        onLida={marcarComoLida}
                        onExcluir={excluirNotificacao}
                        timersRef={timersRef}
                        tempoArquivarMs={TEMPO_ARQUIVAR_MS}
                        onAceitarSeguidor={aceitarSeguidor}
                        onRecusar={recusarSolicitacao}
                      />
                    ))}
                  </div>
                </>
              )}
              {anteriores.length > 0 && (
                <>
                  <span className="section-label" style={{ marginTop: 8 }}>Anteriores</span>
                  <div className="notif-section">
                    {anteriores.map((n) => (
                      <CardNotificacao
                        key={n.id}
                        n={n}
                        avatarClass={avatarClass}
                        iniciais={iniciais}
                        renderTexto={renderTexto}
                        tempoRelativo={tempoRelativo}
                        onLida={marcarComoLida}
                        onExcluir={excluirNotificacao}
                        timersRef={timersRef}
                        tempoArquivarMs={TEMPO_ARQUIVAR_MS}
                        onAceitarSeguidor={aceitarSeguidor}
                        onRecusar={recusarSolicitacao}
                      />
                    ))}
                  </div>
                </>
              )}
              {notifFiltradas.length === 0 && (
                <div className="vazio">
                  <span className="material-symbols-outlined">notifications_off</span>
                  Nenhuma notificação aqui
                </div>
              )}
            </>
          )}
          {estaEmArquivadas && (
            <>
              <div className="arquivo-aviso">
                <span className="material-symbols-outlined">info</span>
                As notificações arquivadas somem quando você sair da conta.
              </div>
              {arquivadas.length > 0 ? (
                <div className="notif-section">
                  {arquivadas.map((n) => (
                    <CardNotificacao
                      key={n.id}
                      n={{ ...n, lida: true }}
                      avatarClass={avatarClass}
                      iniciais={iniciais}
                      renderTexto={renderTexto}
                      tempoRelativo={tempoRelativo}
                      onLida={() => {}}
                      onExcluir={excluirArquivada}
                      isArquivada
                    />
                  ))}
                </div>
              ) : (
                <div className="vazio">
                  <span className="material-symbols-outlined">inventory_2</span>
                  Nenhuma notificação arquivada
                </div>
              )}
            </>
          )}
        </div>
      </div>
      {!estaEmArquivadas && (
        <button className="fab-marcar" onClick={marcarTodasComoLidas}>
          <span className="material-symbols-outlined">done_all</span>
          Marcar todas como lidas
        </button>
      )}
    </Layout>
  );
}

// Componente CardNotificacao
function CardNotificacao({
  n,
  avatarClass,
  iniciais,
  renderTexto,
  tempoRelativo,
  onLida,
  onExcluir,
  timersRef,
  tempoArquivarMs,
  isArquivada = false,
  onAceitarSeguidor,
  onRecusar,
}) {
  const tipoClass = avatarClass(n.tipo);
  const [segundosRestantes, setSegundosRestantes] = useState(null);
  const isSolicitacao = n.tipo === "solicitacao_seguir";

  useEffect(() => {
    if (!n.lida || isArquivada || !timersRef) return;
    if (!timersRef.current[n.id]) return;
    const totalSeg = Math.floor(tempoArquivarMs / 1000);
    setSegundosRestantes(totalSeg);
    const interval = setInterval(() => {
      setSegundosRestantes((prev) => {
        if (prev === null || prev <= 1) {
          clearInterval(interval);
          return null;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [n.lida, n.id]);

  const formatarContagem = (seg) => {
    if (seg === null) return null;
    const m = Math.floor(seg / 60);
    const s = seg % 60;
    return m > 0 ? `${m}m ${s}s` : `${s}s`;
  };

  return (
    <div
      className={`notif-card ${n.lida ? "lida" : "nao-lida"} ${isArquivada ? "arquivada" : ""}`}
      onClick={() => onLida(n.id, n.lida)}
    >
      <div className={`notif-avatar ${tipoClass}`}>
        {iniciais(n.de)}
        <span className={`tipo-icon ${tipoClass}`}>
          <span className="material-symbols-outlined">{tipoIcone(n.tipo)}</span>
        </span>
      </div>
      <div className="notif-content">
        <p className="notif-text">{renderTexto(n)}</p>
        <div className="notif-meta">
          {!n.lida && <span className="dot-unread" />}
          <span className="notif-time">{tempoRelativo(n.createdAt)}</span>
          {n.lida && !isArquivada && segundosRestantes !== null && (
            <span className="notif-arquivando">
              <span className="material-symbols-outlined" style={{ fontSize: 11 }}>
                schedule
              </span>
              arquivando em {formatarContagem(segundosRestantes)}
            </span>
          )}
        </div>
        {isSolicitacao && !isArquivada && (
          <div className="notif-toast__acoes" style={{ marginTop: 8 }}>
            <button
              className="notif-toast__btn notif-toast__btn--seguindo"
              onClick={(e) => { e.stopPropagation(); onAceitarSeguidor(n); }}
            >
              <span className="material-symbols-outlined">person_add</span>
              Aceitar
            </button>
            <button
              className="notif-toast__btn notif-toast__btn--curtida"
              onClick={(e) => { e.stopPropagation(); onRecusar(n); }}
            >
              <span className="material-symbols-outlined">close</span>
              Recusar
            </button>
          </div>
        )}
      </div>
      <div className="notif-actions">
        <button
          className="btn-excluir"
          onClick={(e) => { e.stopPropagation(); onExcluir(n.id); }}
          title="Remover"
        >
          <span className="material-symbols-outlined">close</span>
        </button>
      </div>
    </div>
  );
}

function tipoIcone(tipo) {
  switch (tipo) {
    case "seguindo": return "person_add";
    case "curtida": return "favorite";
    case "comentario": return "chat_bubble";
    case "mensagem": return "send";
    case "solicitacao_seguir": return "person_add";
    case "solicitacao_aceita_seguidor": return "person_add";
    case "solicitacao_aceita_chat": return "chat";
    case "solicitacao_recusada": return "person_remove";
    default: return "notifications";
  }
}