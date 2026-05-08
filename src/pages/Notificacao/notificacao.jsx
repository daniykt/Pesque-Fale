import React, { useEffect, useRef, useState } from "react";
import Layout from "../../components/sidebar/layout";
import "./notificacao.css";

import { db } from "../../firebase";
import {
  collection,
  query,
  where,
  onSnapshot,
  orderBy,
  deleteDoc,
  doc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

import { observeAuthState } from "../../auth";

// ── Tempo até arquivar após lida (5 minutos em ms) ──
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
  const [user, setUser]               = useState(null);
  const [notificacoes, setNotificacoes] = useState([]);
  // Arquivadas: só memória local, some ao deslogar
  const [arquivadas, setArquivadas]   = useState([]);
  const [filtro, setFiltro]           = useState("todas");

  // Mapa de timers: { [id]: timeoutId }
  // Usamos useRef para não recriar o mapa a cada render
  const timersRef = useRef({});

  // 🔐 Auth — limpa arquivadas ao deslogar
  useEffect(() => {
    const unsubscribe = observeAuthState((u) => {
      setUser(u);
      if (!u) {
        // usuário deslogou: limpa arquivadas da memória
        setArquivadas([]);
        // cancela todos os timers pendentes
        Object.values(timersRef.current).forEach(clearTimeout);
        timersRef.current = {};
      }
    });
    return unsubscribe;
  }, []);

  // 🔔 Notificações em tempo real
  useEffect(() => {
    if (!user) return;

    const q = query(
      collection(db, "notificacoes"),
      where("para", "==", user.uid),
      orderBy("createdAt", "desc")
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      setNotificacoes((prev) => {
        const localMap = Object.fromEntries(prev.map((n) => [n.id, n]));
        return snapshot.docs.map((d) => {
          const remoto = { id: d.id, ...d.data() };
          const local  = localMap[d.id];
          // mantém atualização otimista de lida
          if (local?.lida && !remoto.lida) return { ...remoto, lida: true };
          return remoto;
        });
      });
    });

    return unsubscribe;
  }, [user]);

  // ⏳ Motor de arquivamento — observa notificações lidas e agenda timer
  useEffect(() => {
    notificacoes.forEach((n) => {
      // só agenda se: está lida, não tem timer rodando e não está arquivada
      if (
        n.lida &&
        !timersRef.current[n.id] &&
        !arquivadas.find((a) => a.id === n.id)
      ) {
        timersRef.current[n.id] = setTimeout(() => {
          arquivar(n);
        }, TEMPO_ARQUIVAR_MS);
      }

      // se ficou não-lida de novo (ex: edge case), cancela o timer
      if (!n.lida && timersRef.current[n.id]) {
        clearTimeout(timersRef.current[n.id]);
        delete timersRef.current[n.id];
      }
    });
  }, [notificacoes]);

  // 📦 Arquivar: move para memória local e apaga do Firestore
  const arquivar = async (notif) => {
    // adiciona nas arquivadas locais
    setArquivadas((prev) => {
      if (prev.find((a) => a.id === notif.id)) return prev;
      return [notif, ...prev];
    });
    // remove da lista ativa
    setNotificacoes((prev) => prev.filter((n) => n.id !== notif.id));
    // limpa o timer
    delete timersRef.current[notif.id];
    // apaga do Firestore
    try {
      await deleteDoc(doc(db, "notificacoes", notif.id));
    } catch (e) {
      console.error("[arquivar] erro ao deletar:", e);
    }
  };

  // 🗑️ Excluir da lista ativa
  const excluirNotificacao = async (id) => {
    clearTimeout(timersRef.current[id]);
    delete timersRef.current[id];
    setNotificacoes((prev) => prev.filter((n) => n.id !== id));
    await deleteDoc(doc(db, "notificacoes", id));
  };

  // 🗑️ Excluir das arquivadas (só local, já saiu do Firestore)
  const excluirArquivada = (id) => {
    setArquivadas((prev) => prev.filter((a) => a.id !== id));
  };

  // ✅ Marcar uma como lida — otimista
  const marcarComoLida = async (id, lida) => {
    if (lida) return;
    setNotificacoes((prev) =>
      prev.map((n) => (n.id === id ? { ...n, lida: true } : n))
    );
    await updateDoc(doc(db, "notificacoes", id), { lida: true });
  };

  // ✅ Marcar todas como lidas — otimista
  const marcarTodasComoLidas = async () => {
    if (!user) return;
    const naoLidas = notificacoes.filter((n) => !n.lida);
    if (naoLidas.length === 0) return;

    setNotificacoes((prev) => prev.map((n) => ({ ...n, lida: true })));

    const batch = writeBatch(db);
    naoLidas.forEach((n) => {
      batch.update(doc(db, "notificacoes", n.id), { lida: true });
    });
    await batch.commit();
  };

  // ⏱️ Tempo relativo
  const tempoRelativo = (timestamp) => {
    if (!timestamp) return "";
    const agora = new Date();
    const data  = new Date(timestamp.seconds * 1000);
    const diff  = Math.floor((agora - data) / 1000);

    if (diff < 60)      return "agora";
    if (diff < 3600)    return `há ${Math.floor(diff / 60)} min`;
    if (diff < 86400)   return `há ${Math.floor(diff / 3600)} h`;
    if (diff < 2592000) return `há ${Math.floor(diff / 86400)} dias`;
    return data.toLocaleDateString();
  };

  // 📅 É hoje?
  const isHoje = (timestamp) => {
    if (!timestamp) return false;
    const data  = new Date(timestamp.seconds * 1000);
    const agora = new Date();
    return (
      data.getDate()     === agora.getDate() &&
      data.getMonth()    === agora.getMonth() &&
      data.getFullYear() === agora.getFullYear()
    );
  };

  // 💬 Texto da notificação
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
      default:
        return "Nova notificação";
    }
  };

  // 🎨 Classe do avatar
  const avatarClass = (tipo) => {
    const map = {
      seguindo:    "seguidor",
      curtida:     "curtida",
      comentario:  "comentario",
      mensagem:    "mensagem",
    };
    return map[tipo] || "seguidor";
  };

  // 🔤 Iniciais
  const iniciais = (nome = "") =>
    nome.split(" ").slice(0, 2).map((p) => p[0]?.toUpperCase()).join("");

  // 🔢 Contagem não lidas por tipo
  const contarNaoLidas = (tipo) => {
    const base = notificacoes.filter((n) => !n.lida);
    if (tipo === "todas") return base.length;
    if (tipo === "arquivadas") return 0;
    return base.filter((n) => n.tipo === tipo).length;
  };

  // 📋 Lista ativa filtrada (exclui aba arquivadas das filtradas normais)
  const estaEmArquivadas = filtro === "arquivadas";

  const notifFiltradas = estaEmArquivadas
    ? []
    : filtro === "todas"
      ? notificacoes
      : notificacoes.filter((n) => n.tipo === filtro);

  const hoje       = notifFiltradas.filter((n) =>  isHoje(n.createdAt));
  const anteriores = notifFiltradas.filter((n) => !isHoje(n.createdAt));

  // Limpeza de timers ao desmontar o componente
  useEffect(() => {
    return () => {
      Object.values(timersRef.current).forEach(clearTimeout);
    };
  }, []);

  return (
    <Layout>
      <div className="notif-wrapper">

        {/* ── ABAS ── */}
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
                  {/* badge de quantidade para arquivadas */}
                  {isArq && arquivadas.length > 0 && (
                    <span className="tab-badge tab-badge--arquivo">{arquivadas.length}</span>
                  )}
                  {/* badge de não lidas para as outras abas */}
                  {!isArq && count > 0 && (
                    <span className="tab-badge">{count}</span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* ── LISTA ── */}
        <div className="container-notificacoes">

          {/* ── MODO NORMAL ── */}
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

          {/* ── MODO ARQUIVADAS ── */}
          {estaEmArquivadas && (
            <>
              {/* aviso de sessão */}
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
                      onLida={() => {}} // já lida, sem ação
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

      {/* ── FAB — só aparece fora da aba arquivadas ── */}
      {!estaEmArquivadas && (
        <button className="fab-marcar" onClick={marcarTodasComoLidas}>
          <span className="material-symbols-outlined">done_all</span>
          Marcar todas como lidas
        </button>
      )}
    </Layout>
  );
}

/* ──────────────────────────────────────────────
   CARD — mostra countdown quando lida e aguardando arquivamento
────────────────────────────────────────────── */
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
}) {
  const tipoClass = avatarClass(n.tipo);

  // countdown visual: segundos restantes até arquivar
  const [segundosRestantes, setSegundosRestantes] = useState(null);

  useEffect(() => {
    if (!n.lida || isArquivada || !timersRef) return;

    // verifica se tem timer rodando pra esse card
    if (!timersRef.current[n.id]) return;

    // calcula quando o timer vai disparar
    // como não temos o timestamp exato do início, estimamos pela
    // presença do timer — recalculamos a cada segundo
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
      {/* Avatar */}
      <div className={`notif-avatar ${tipoClass}`}>
        {iniciais(n.de)}
        <span className={`tipo-icon ${tipoClass}`}>
          <span className="material-symbols-outlined">
            {tipoIcone(n.tipo)}
          </span>
        </span>
      </div>

      {/* Conteúdo */}
      <div className="notif-content">
        <p className="notif-text">{renderTexto(n)}</p>
        <div className="notif-meta">
          {!n.lida && <span className="dot-unread" />}
          <span className="notif-time">{tempoRelativo(n.createdAt)}</span>

          {/* countdown de arquivamento */}
          {n.lida && !isArquivada && segundosRestantes !== null && (
            <span className="notif-arquivando">
              <span className="material-symbols-outlined" style={{ fontSize: 11 }}>
                schedule
              </span>
              arquivando em {formatarContagem(segundosRestantes)}
            </span>
          )}
        </div>
      </div>

      {/* Excluir */}
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
    case "seguindo":    return "person_add";
    case "curtida":     return "favorite";
    case "comentario":  return "chat_bubble";
    case "mensagem":    return "send";
    default:            return "notifications";
  }
}