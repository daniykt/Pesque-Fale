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
  const [digitando, setDigitando] = useState(false);
  const [enviando, setEnviando] = useState(false);

  const mensagensEndRef = useRef(null);
  const mensagensContainerRef = useRef(null);

  // 🔐 Usuário autenticado
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // =========================
  // 📥 INBOX - Lista de Conversas
  // =========================
  useEffect(() => {
    const carregarConversas = async () => {
      if (!user || chatId) return;
      setLoadingConversas(true);

      try {
        const meuDoc = await getDoc(doc(db, "usuarios", user.uid));
        if (!meuDoc.exists()) {
          setLoadingConversas(false);
          return;
        }

        const dados = meuDoc.data();
        const seguindo = dados?.seguindo || [];

        const lista = await Promise.all(
          seguindo.map(async (id) => {
            const userDoc = await getDoc(doc(db, "usuarios", id));
            if (!userDoc.exists()) return null;

            const u = userDoc.data();
            const cid = [user.uid, id].sort().join("_");

            let ultimaMsg = null;
            let ultimaData = null;
            let naoLidas = 0;

            try {
              const q = query(
                collection(db, "chats", cid, "mensagens"),
                orderBy("createdAt", "desc"),
                limit(20)
              );
              const snap = await getDocs(q);
              if (!snap.empty) {
                const msg = snap.docs[0].data();
                ultimaMsg = msg.texto;
                ultimaData = msg.createdAt?.toDate?.() || new Date(msg.createdAt);

                // Contar não lidas (mensagens do outro usuário não lidas)
                naoLidas = snap.docs.filter(d => {
                  const m = d.data();
                  return m.userId !== user.uid && m.status !== "visto";
                }).length;
              }
            } catch (_) {}

            return {
              chatId: cid,
              nome: u?.nome || "Usuário",
              foto: u?.fotoPerfil || "",
              ultimaMensagem: ultimaMsg || "Nenhuma mensagem ainda",
              ultimaData: ultimaData,
              naoLidas: naoLidas,
            };
          })
        );

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
  // 🔒 Permissão + Dados do Outro Usuário
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
  // 💬 Mensagens em Tempo Real
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
  // ✉️ Enviar Mensagem
  // =========================
  const enviarMensagem = async () => {
    if (!texto.trim() || enviando) return;
    setEnviando(true);

    try {
      await addDoc(collection(db, "chats", chatId, "mensagens"), {
        texto: texto.trim(),
        userId: user.uid,
        nome: user.displayName || "Pescador",
        createdAt: serverTimestamp(),
        status: "enviado",
      });

      const ids = chatId.split("_");
      const outroId = ids.find((id) => id !== user.uid);

      if (outroId) {
        await addDoc(collection(db, "notificacoes"), {
          tipo: "mensagem",
          de: user.displayName || "Usuário",
          para: outroId,
          texto: texto.trim(),
          createdAt: serverTimestamp(),
        });
      }

      setTexto("");
    } catch (error) {
      console.error("Erro ao enviar mensagem:", error);
    } finally {
      setEnviando(false);
    }
  };

  // =========================
  // 📜 Scroll Automático
  // =========================
  const scrollToBottom = () => {
    mensagensEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    if (!showScrollBtn) {
      scrollToBottom();
    }
  }, [mensagens, showScrollBtn, digitando]);

  const handleScroll = () => {
    const el = mensagensContainerRef.current;
    if (!el) return;
    const threshold = 120;
    const isNearBottom =
      el.scrollHeight - el.scrollTop - el.clientHeight < threshold;
    setShowScrollBtn(!isNearBottom);
  };

  useEffect(() => {
    const el = mensagensContainerRef.current;
    if (el) {
      el.addEventListener("scroll", handleScroll);
      return () => el.removeEventListener("scroll", handleScroll);
    }
  }, []);

  // ⏱️ Helpers de Formatação
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

  const formatarDataAmigavel = (timestamp) => {
    if (!timestamp) return "";
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    const hoje = new Date();
    const ontem = new Date(hoje);
    ontem.setDate(hoje.getDate() - 1);

    if (date.toDateString() === hoje.toDateString()) return "Hoje";
    if (date.toDateString() === ontem.toDateString()) return "Ontem";

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
    return data.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" });
  };

  const conversasFiltradas = conversas.filter((c) =>
    c.nome.toLowerCase().includes(busca.toLowerCase())
  );

  // =========================
  // 🏠 RENDER: INBOX
  // =========================
  if (!chatId) {
    return (
      <Layout>
        <div className="chat-wrapper">
          <div className="chat-header-simple">
            <div className="chat-header-left">
              <span className="chat-header-icon">🐟</span>
              <div>
                <h1 className="chat-title">Conversas</h1>
                <div className="chat-subtitle">
                  {conversas.length} {conversas.length === 1 ? "conversa" : "conversas"}
                </div>
              </div>
            </div>
          </div>

          <div className="busca-conversas">
            <input
              className="busca-input"
              type="text"
              placeholder="🔍 Buscar conversa..."
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
            />
          </div>

          {loadingConversas ? (
            <div
              style={{
                flex: 1,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "var(--chat-text-secondary)",
                fontSize: "0.9rem",
                gap: "10px",
              }}
            >
              <div className="spinner" style={{ borderColor: "var(--chat-border)", borderTopColor: "var(--chat-primary)" }} />
              Carregando conversas...
            </div>
          ) : (
            <div className="lista-conversas">
              {conversasFiltradas.length === 0 ? (
                <div className="conversa-vazia">
                  {busca ? (
                    <>😕 Nenhuma conversa encontrada para "<strong>{busca}</strong>"</>
                  ) : (
                    <>🎣 Você ainda não segue ninguém.<br />Descubra pescadores na pesquisa!</>
                  )}
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
                        <img src={c.foto} alt={c.nome} />
                      ) : (
                        <span>{c.nome.charAt(0).toUpperCase()}</span>
                      )}
                    </div>
                    <div className="conversa-info">
                      <div className="conversa-nome">{c.nome}</div>
                      <div className="conversa-ultima-msg">
                        {c.ultimaMensagem}
                      </div>
                    </div>
                    <div className="conversa-meta">
                      {c.ultimaData && (
                        <span className="conversa-hora">
                          {tempoRelativo(c.ultimaData)}
                        </span>
                      )}
                      {c.naoLidas > 0 && (
                        <span className="conversa-badge">{c.naoLidas}</span>
                      )}
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
        <div className="chat-wrapper" style={{ justifyContent: "center", alignItems: "center" }}>
          <div className="chat-vazio">
            <div className="chat-vazio-icon" style={{ fontSize: "2.5rem" }}>🔒</div>
            <p>Chat bloqueado</p>
            <span>Você precisa seguir este usuário para conversar.</span>
            <button
              className="btn-enviar"
              style={{ marginTop: "16px", padding: "10px 24px", borderRadius: "24px", width: "auto" }}
              onClick={() => navigate("/chat")}
            >
              <span className="material-symbols-outlined" style={{ fontSize: "18px" }}>arrow_back</span>
              <span style={{ marginLeft: "6px", fontSize: "0.85rem", fontWeight: 500 }}>Voltar</span>
            </button>
          </div>
        </div>
      </Layout>
    );
  }

  // =========================
  // 💬 RENDER: CHAT PRINCIPAL
  // =========================
  const renderizarMensagens = () => {
    return mensagens.map((msg, index) => {
      const isMine = msg.userId === user?.uid;
      const hora = formatarHora(msg.createdAt);
      const mostrarData =
        index === 0 ||
        !mesmoDia(msg.createdAt, mensagens[index - 1]?.createdAt);

      const mesmoRemetente =
        index > 0 && mensagens[index - 1].userId === msg.userId;
      const classeSequencia = mesmoRemetente ? "msg-grupo--sequencia" : "";

      const separador = mostrarData ? (
        <div className="data-separador" key={`data-${msg.id}`}>
          {formatarDataAmigavel(msg.createdAt)}
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
            <span>{user?.displayName?.charAt(0) || "?"}</span>
          </div>
        ) : null;

      const spacerMeu =
        isMine && !avatarMeu ? <div className="msg-avatar-spacer" /> : null;
      const spacerOutro =
        !isMine && !avatarOutro ? <div className="msg-avatar-spacer" /> : null;

      return (
        <React.Fragment key={msg.id}>
          {separador}
          <div
            className={`msg-grupo ${
              isMine ? "msg-grupo--minha" : "msg-grupo--outra"
            } ${classeSequencia}`}
          >
            {!isMine && (avatarOutro || spacerOutro)}
            <div className="msg-conteudo">
              {!isMine && !mesmoRemetente && (
                <span className="msg-nome">{msg.nome}</span>
              )}
              <div
                className={`msg-bolha ${
                  isMine ? "msg-bolha--minha" : "msg-bolha--outra"
                }`}
              >
                <p>{msg.texto}</p>
                <span className="msg-hora">{hora}</span>
                {isMine && (
                  <div
                    className={`msg-status ${
                      msg.status === "visto" ? "visto" : ""
                    }`}
                  >
                    <span className="material-symbols-outlined">
                      {msg.status === "visto" ? "done_all" : "done"}
                    </span>
                  </div>
                )}
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
            <button
              className="btn-voltar-chat"
              onClick={() => navigate("/chat")}
              title="Voltar às conversas"
            >
              <span className="material-symbols-outlined">arrow_back</span>
            </button>

            {outroUsuario?.foto ? (
              <img
                src={outroUsuario.foto}
                alt={outroUsuario.nome}
                className="chat-avatar"
              />
            ) : (
              <div className="chat-avatar">
                {outroUsuario?.nome?.charAt(0) || "?"}
              </div>
            )}

            <div className="chat-header-info">
              <h1 className="chat-title">
                {outroUsuario?.nome || "Pescador"}
              </h1>
              <div className="chat-subtitle">
                {digitando ? (
                  <span style={{ color: "rgba(255,255,255,0.8)", fontStyle: "italic" }}>
                    digitando...
                  </span>
                ) : (
                  <>
                    <span className="online-dot"></span>
                    <span>Online</span>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Mensagens */}
        <div
          className="chat-mensagens"
          ref={mensagensContainerRef}
          onScroll={handleScroll}
        >
          {mensagens.length === 0 && !digitando ? (
            <div className="chat-vazio">
              <div className="chat-vazio-icon">💬</div>
              <p>Nenhuma mensagem ainda</p>
              <span>Seja o primeiro a dizer olá! 👋</span>
            </div>
          ) : (
            renderizarMensagens()
          )}

          {/* Indicador de digitação */}
          {digitando && (
            <div className="msg-digitando">
              <div className="msg-avatar">
                {outroUsuario?.foto ? (
                  <img
                    src={outroUsuario.foto}
                    alt=""
                    style={{
                      width: "100%",
                      height: "100%",
                      borderRadius: "50%",
                      objectFit: "cover",
                    }}
                  />
                ) : (
                  <span>{outroUsuario?.nome?.charAt(0) || "?"}</span>
                )}
              </div>
              <div className="bolha-digitando">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          )}

          <div ref={mensagensEndRef} />
        </div>

        {/* Botão scroll para baixo */}
        {showScrollBtn && (
          <button className="btn-scroll-bottom" onClick={scrollToBottom} title="Rolar para baixo">
            <span className="material-symbols-outlined">arrow_downward</span>
          </button>
        )}

        {/* Input */}
        <div className="chat-input-area">
          <div className="chat-input-row">
            <button className="btn-emoji" title="Adicionar emoji">
              <span className="material-symbols-outlined">emoji_emotions</span>
            </button>
            <input
              value={texto}
              onChange={(e) => {
                setTexto(e.target.value);
                // Limitar a 500 caracteres
                if (e.target.value.length > 500) {
                  setTexto(e.target.value.slice(0, 500));
                }
              }}
              placeholder="Digite sua mensagem..."
              onKeyDown={(e) => e.key === "Enter" && !e.shiftKey && enviarMensagem()}
              maxLength={500}
            />
            <button
              className="btn-enviar"
              onClick={enviarMensagem}
              disabled={!texto.trim() || enviando}
              title="Enviar mensagem"
            >
              {enviando ? (
                <div className="spinner" />
              ) : (
                <span className="material-symbols-outlined">send</span>
              )}
            </button>
          </div>
          <span className="char-count">{texto.length}/500</span>
        </div>
      </div>
    </Layout>
  );
}