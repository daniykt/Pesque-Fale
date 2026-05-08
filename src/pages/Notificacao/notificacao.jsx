import React, { useEffect, useState } from "react";
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

const TIPOS = [
  { key: "todas",      label: "Todas",        icon: "notifications" },
  { key: "seguindo",   label: "Seguidores",   icon: "person_add" },
  { key: "curtida",    label: "Curtidas",     icon: "favorite" },
  { key: "comentario", label: "Comentários",  icon: "chat_bubble" },
  { key: "mensagem",   label: "Mensagens",    icon: "send" },
];

export default function Notificacao() {
  const [user, setUser]                 = useState(null);
  const [notificacoes, setNotificacoes] = useState([]);
  const [filtro, setFiltro]             = useState("todas");

  // 🔐 Auth
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
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
          if (local?.lida && !remoto.lida) return { ...remoto, lida: true };
          return remoto;
        });
      });
    });

    return unsubscribe;
  }, [user]);

  const excluirNotificacao = async (id) => {
    setNotificacoes((prev) => prev.filter((n) => n.id !== id));
    await deleteDoc(doc(db, "notificacoes", id));
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
    naoLidas.forEach((n) => {
      batch.update(doc(db, "notificacoes", n.id), { lida: true });
    });
    await batch.commit();
  };

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

  const avatarClass = (tipo) => {
    const map = {
      seguindo:    "seguidor",
      curtida:     "curtida",
      comentario:  "comentario",
      mensagem:    "mensagem",
    };
    return map[tipo] || "seguidor";
  };

  const iniciais = (nome = "") =>
    nome.split(" ").slice(0, 2).map((p) => p[0]?.toUpperCase()).join("");

  const contarNaoLidas = (tipo) => {
    const base = notificacoes.filter((n) => !n.lida);
    if (tipo === "todas") return base.length;
    return base.filter((n) => n.tipo === tipo).length;
  };

  const notifFiltradas =
    filtro === "todas"
      ? notificacoes
      : notificacoes.filter((n) => n.tipo === filtro);

  const hoje       = notifFiltradas.filter((n) =>  isHoje(n.createdAt));
  const anteriores = notifFiltradas.filter((n) => !isHoje(n.createdAt));

  return (
    <Layout>
      {/*
        .notif-wrapper usa height: 100vh + overflow: hidden
        para que o scroll aconteça DENTRO do .container-notificacoes
        e não na página inteira.
      */}
      <div className="notif-wrapper">

        {/* ── ABAS ── */}
        <div className="notif-header">
          <div className="notif-tabs">
            {TIPOS.map((t) => {
              const count = contarNaoLidas(t.key);
              return (
                <button
                  key={t.key}
                  className={`notif-tab ${filtro === t.key ? "active" : ""}`}
                  onClick={() => setFiltro(t.key)}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 16 }}>
                    {t.icon}
                  </span>
                  {t.label}
                  {count > 0 && <span className="tab-badge">{count}</span>}
                </button>
              );
            })}
          </div>
        </div>

        {/* ── LISTA ── */}
        <div className="container-notificacoes">

          {/* Hoje */}
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
                  />
                ))}
              </div>
            </>
          )}

          {/* Anteriores */}
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
                  />
                ))}
              </div>
            </>
          )}

          {/* Vazio */}
          {notifFiltradas.length === 0 && (
            <div className="vazio">
              <span className="material-symbols-outlined">notifications_off</span>
              Nenhuma notificação aqui
            </div>
          )}
        </div>
      </div>

      {/* ── FAB ── */}
      <button className="fab-marcar" onClick={marcarTodasComoLidas}>
        <span className="material-symbols-outlined">done_all</span>
        Marcar todas como lidas
      </button>
    </Layout>
  );
}

/* ── CARD ── */
function CardNotificacao({
  n,
  avatarClass,
  iniciais,
  renderTexto,
  tempoRelativo,
  onLida,
  onExcluir,
}) {
  const tipoClass = avatarClass(n.tipo);

  return (
    <div
      className={`notif-card ${n.lida ? "lida" : "nao-lida"}`}
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