import React, { useEffect, useState, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./chat.css";

import { db } from "../../firebase";
import {
  collection,
  addDoc,
  query,
  orderBy,
  limit,
  onSnapshot,
  serverTimestamp,
  doc,
  getDoc,
  getDocs,
} from "firebase/firestore";

import { observeAuthState } from "../../auth";

export default function Chat() {
  const { chatId } = useParams();
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [mensagens, setMensagens] = useState([]);
  const [texto, setTexto] = useState("");
  const [permitido, setPermitido] = useState(false);
  const [conversas, setConversas] = useState([]);
  const [outroUsuario, setOutroUsuario] = useState(null);
  const [showScrollBtn, setShowScrollBtn] = useState(false);
  const [loadingConversas, setLoadingConversas] = useState(false);
  const [busca, setBusca] = useState("");

  const mensagensEndRef = useRef(null);
  const mensagensContainerRef = useRef(null);

  // 🔐 usuário
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // =========================
  // 🔥 INBOX MELHORADO
  // =========================
  useEffect(() => {
    const carregarConversas = async () => {
      if (!user || chatId) return;
      setLoadingConversas(true);

      try {
        const meuDoc = await getDoc(doc(db, "usuarios", user.uid));
        if (!meuDoc.exists()) return;

        const dados = meuDoc.data();
        const seguindo = dados?.seguindo || [];

        const lista = await Promise.all(
          seguindo.map(async (id) => {
            const userDoc = await getDoc(doc(db, "usuarios", id));
            if (!userDoc.exists()) return null;

            const u = userDoc.data();
            const cid = [user.uid, id].sort().join("_");

            // Buscar última mensagem
            let ultimaMsg = null;
            let ultimaData = null;
            try {
              const q = query(
                collection(db, "chats", cid, "mensagens"),
                orderBy("createdAt", "desc"),
                limit(1)
              );
              const snap = await getDocs(q);
              if (!snap.empty) {
                const msg = snap.docs[0].data();
                ultimaMsg = msg.texto;
                ultimaData = msg.createdAt?.toDate?.() || new Date(msg.createdAt);
              }
            } catch (_) {}

            return {
              chatId: cid,
              nome: u?.nome || "Usuário",
              foto: u?.fotoPerfil || "",
              ultimaMensagem: ultimaMsg || "Nenhuma mensagem ainda",
              ultimaData: ultimaData,
            };
          })
        );

        // Ordenar por data (mais recente primeiro)
        const ordenada = lista
          .filter(Boolean)
          .sort((a, b) => {
            if (!a.ultimaData && !b.ultimaData) return 0;
            if (!a.ultimaData) return 1;
            if (!b.ultimaData) return -1;
            return b.ultimaData - a.ultimaData;
          });

        setConversas(ordenada);
      } catch (error) {
        console.error("Erro ao carregar conversas:", error);
      } finally {
        setLoadingConversas(false);
      }
    };

    carregarConversas();
  }, [user, chatId]);

  // =========================
  // 🔒 PERMISSÃO + DADOS DO OUTRO
  // =========================
  useEffect(() => {
    const verificar = async () => {
      if (!user || !chatId) return;

      try {
        const ids = chatId.split("_");
        const outroId = ids.find((id) => id !== user.uid);

        const meuDoc = await getDoc(doc(db, "usuarios", user.uid));
        if (!meuDoc.exists()) return;

        const dados = meuDoc.data();

        if (
          dados?.seguindo?.includes(outroId) ||
          dados?.seguidores?.includes(outroId)
        ) {
          setPermitido(true);
        }

        const outroDoc = await getDoc(doc(db, "usuarios", outroId));
        if (outroDoc.exists()) {
          const outro = outroDoc.data();
          setOutroUsuario({
            nome: outro?.nome || "Usuário",
            foto: outro?.fotoPerfil || "",
          });
        }
      } catch (error) {
        console.error("Erro ao verificar permissão:", error);
      }
    };

    verificar();
  }, [user, chatId]);

  // =========================
  // 💬 MENSAGENS
  // =========================
  useEffect(() => {
    if (!chatId || !permitido) return;

    const q = query(
      collection(db, "chats", chatId, "mensagens"),
      orderBy("createdAt", "asc")
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      setMensagens(
        snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
      );
    });

    return unsubscribe;
  }, [chatId, permitido]);

  // =========================
  // ✉️ ENVIAR + NOTIFICAÇÃO
  // =========================
  const enviarMensagem = async () => {
    if (!texto.trim()) return;

    try {
      await addDoc(collection(db, "chats", chatId, "mensagens"), {
        texto,
        userId: user.uid,
        nome: user.displayName || "Pescador",
        createdAt: serverTimestamp(),
      });

      const ids = chatId.split("_");
      const outroId = ids.find((id) => id !== user.uid);

      if (outroId) {
        await addDoc(collection(db, "notificacoes"), {
          tipo: "mensagem",
          de: user.displayName || "Usuário",
          para: outroId,
          texto: texto,
          createdAt: serverTimestamp(),
        });
      }

      setTexto("");
    } catch (error) {
      console.error("Erro ao enviar mensagem:", error);
    }
  };

  // =========================
  // 📜 SCROLL
  // =========================
  const scrollToBottom = () => {
    mensagensEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    if (!showScrollBtn) {
      scrollToBottom();
    }
  }, [mensagens, showScrollBtn]);

  const handleScroll = () => {
    const el = mensagensContainerRef.current;
    if (!el) return;
    const threshold = 100;
    const isNearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < threshold;
    setShowScrollBtn(!isNearBottom);
  };

  useEffect(() => {
    const el = mensagensContainerRef.current;
    if (el) {
      el.addEventListener("scroll", handleScroll);
      return () => el.removeEventListener("scroll", handleScroll);
    }
  }, []);

  // ⏱️ funções auxiliares
  const formatarHora = (timestamp) => {
    if (!timestamp) return "";
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  const mesmoDia = (d1, d2) => {
    if (!d1 || !d2) return false;
    const date1 = d1.toDate ? d1.toDate() : new Date(d1);
    const date2 = d2.toDate ? d2.toDate() : new Date(d2);
    return date1.toDateString() === date2.toDateString();
  };

  const formatarData = (timestamp) => {
    if (!timestamp) return "";
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString("pt-BR", {
      day: "2-digit",
      month: "long",
      year: "numeric",
    });
  };

  const tempoRelativo = (data) => {
    if (!data) return "";
    const agora = new Date();
    const diff = Math.floor((agora - data) / 1000);
    if (diff < 60) return "agora";
    if (diff < 3600) return `${Math.floor(diff / 60)} min`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} h`;
    if (diff < 604800) return `${Math.floor(diff / 86400)} d`;
    return data.toLocaleDateString("pt-BR");
  };

  // Filtro de busca
  const conversasFiltradas = conversas.filter(c =>
    c.nome.toLowerCase().includes(busca.toLowerCase())
  );

  // =========================
  // 🔥 INBOX UI
  // =========================
  if (!chatId) {
    return (
      <Layout>
        <div className="chat-wrapper">
          <div className="chat-header">
            <div className="chat-header-left">
              <span className="chat-header-icon">🐟</span>
              <h1 className="chat-title">Conversas</h1>
            </div>
          </div>

          {/* Campo de busca */}
          <div className="busca-conversas">
            <input
              className="busca-input"
              type="text"
              placeholder="Buscar conversa..."
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
            />
          </div>

          {loadingConversas ? (
            <div style={{ padding: "40px", textAlign: "center", color: "var(--texto-medio)" }}>
              Carregando conversas...
            </div>
          ) : (
            <div className="lista-conversas">
              {conversasFiltradas.length === 0 ? (
                <div className="conversa-vazia">
                  {busca ? "Nenhuma conversa encontrada" : "Você ainda não segue ninguém."}
                </div>
              ) : (
                conversasFiltradas.map((c) => (
                  <div
                    key={c.chatId}
                    className="conversa-item"
                    onClick={() => navigate(`/chat/${c.chatId}`)}
                  >
                    <div className="conversa-avatar">
                      {c.foto ? (
                        <img src={c.foto} alt={c.nome} className="conversa-avatar" />
                      ) : (
                        <span>{c.nome.charAt(0).toUpperCase()}</span>
                      )}
                    </div>
                    <div className="conversa-info">
                      <div className="conversa-nome">{c.nome}</div>
                      <div className="conversa-ultima-msg">{c.ultimaMensagem}</div>
                    </div>
                    <div className="conversa-meta">
                      {c.ultimaData && (
                        <span className="conversa-hora">{tempoRelativo(c.ultimaData)}</span>
                      )}
                      {/* Badge de não lidas (placeholder para futura implementação) */}
                      {/* <span className="conversa-badge">2</span> */}
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
      </Layout>
    );
  }

  // =========================
  // 🔒 BLOQUEIO
  // =========================
  if (!permitido) {
    return (
      <Layout>
        <div style={{ textAlign: "center", marginTop: "60px" }}>
          <h2>🔒 Chat bloqueado</h2>
          <p>Você precisa seguir este usuário para conversar.</p>
        </div>
      </Layout>
    );
  }

  // =========================
  // 💬 CHAT PRINCIPAL (agrupamento + data)
  // =========================
  const renderizarMensagens = () => {
    return mensagens.map((msg, index) => {
      const isMine = msg.userId === user.uid;
      const hora = formatarHora(msg.createdAt);
      const mostrarData =
        index === 0 || !mesmoDia(msg.createdAt, mensagens[index - 1]?.createdAt);

      const mesmoRemetente = index > 0 && mensagens[index - 1].userId === msg.userId;
      const classeSequencia = mesmoRemetente ? "msg-grupo--sequencia" : "";

      const separador = mostrarData ? (
        <div className="data-separador" key={`data-${msg.id}`}>
          {formatarData(msg.createdAt)}
        </div>
      ) : null;

      const avatarOutro =
        !isMine && !mesmoRemetente ? (
          <div className="msg-avatar">
            {outroUsuario?.foto ? (
              <img src={outroUsuario.foto} alt={msg.nome} />
            ) : (
              <span>{msg.nome?.charAt(0) || "?"}</span>
            )}
          </div>
        ) : null;

      const avatarMeu =
        isMine && !mesmoRemetente ? (
          <div className="msg-avatar">
            <span>{user.displayName?.charAt(0) || "?"}</span>
          </div>
        ) : null;

      const spacerMeu = isMine && !avatarMeu ? <div className="msg-avatar-spacer" /> : null;
      const spacerOutro = !isMine && !avatarOutro ? <div className="msg-avatar-spacer" /> : null;

      return (
        <React.Fragment key={msg.id}>
          {separador}
          <div className={`msg-grupo ${isMine ? "msg-grupo--minha" : "msg-grupo--outra"} ${classeSequencia}`}>
            {!isMine && (avatarOutro || spacerOutro)}
            <div className="msg-conteudo">
              {!isMine && !mesmoRemetente && (
                <span className="msg-nome">{msg.nome}</span>
              )}
              <div className={`msg-bolha ${isMine ? "msg-bolha--minha" : "msg-bolha--outra"}`}>
                <p>{msg.texto}</p>
                <span className="msg-hora">{hora}</span>
              </div>
            </div>
            {isMine && (spacerMeu || avatarMeu)}
          </div>
        </React.Fragment>
      );
    });
  };

  return (
    <Layout>
      <div className="chat-wrapper">
        {/* Header */}
        <div className="chat-header">
          <div className="chat-header-left">
            <span className="chat-header-icon">🐟</span>
            <div>
              <h1 className="chat-title">
                {outroUsuario?.nome || "Pescador"}
              </h1>
              <div className="chat-subtitle">
                <span className="online-dot"></span>
                <span>Online</span>
              </div>
            </div>
          </div>

          <div className="chat-header-right">
            <div className="user-badge">
              {outroUsuario?.foto ? (
                <img
                  src={outroUsuario.foto}
                  alt={outroUsuario.nome}
                  className="user-avatar-img"
                />
              ) : (
                <div className="user-avatar-placeholder">
                  {outroUsuario?.nome?.charAt(0) || "?"}
                </div>
              )}
              <span className="user-name-badge">
                {outroUsuario?.nome || "Usuário"}
              </span>
            </div>
          </div>
        </div>

        {/* Mensagens */}
        <div className="chat-mensagens" ref={mensagensContainerRef} onScroll={handleScroll}>
          {mensagens.length === 0 ? (
            <div className="chat-vazio">
              <span className="chat-vazio-icon">💬</span>
              <p>Nenhuma mensagem ainda</p>
              <span>Seja o primeiro a dizer olá!</span>
            </div>
          ) : (
            renderizarMensagens()
          )}
          <div ref={mensagensEndRef} />
        </div>

        {showScrollBtn && (
          <button className="btn-scroll-bottom" onClick={scrollToBottom}>
            <span className="material-symbols-outlined">arrow_downward</span>
          </button>
        )}

        {/* Input */}
        <div className="chat-input-area">
          <div className="chat-input-row">
            <input
              value={texto}
              onChange={(e) => setTexto(e.target.value)}
              placeholder="Digite sua mensagem..."
              onKeyDown={(e) => e.key === "Enter" && enviarMensagem()}
            />
            <button
              className="btn-enviar"
              onClick={enviarMensagem}
              disabled={!texto.trim()}
            >
              <span className="material-symbols-outlined">send</span>
            </button>
          </div>
          <span className="char-count">{texto.length}/500</span>
        </div>
      </div>
    </Layout>
  );
}