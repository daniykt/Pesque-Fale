import React, { useEffect, useState, useRef, useLayoutEffect } from "react";
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
  updateDoc,
  where,
} from "firebase/firestore";

import { observeAuthState } from "../../auth";

export default function Chat() {
  const { chatId } = useParams();
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [mensagens, setMensagens] = useState([]);
  const [texto, setTexto] = useState("");
  const [permitido, setPermitido] = useState(null);
  const [conversas, setConversas] = useState(null);
  const [outroUsuario, setOutroUsuario] = useState(null);
  const [showScrollBtn, setShowScrollBtn] = useState(false);
  const [busca, setBusca] = useState("");
  const [digitando, setDigitando] = useState(false);
  const [enviando, setEnviando] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);

  const mensagensEndRef = useRef(null);
  const mensagensContainerRef = useRef(null);
  const primeiraCargaRef = useRef(true);

  // 🔐 Usuário autenticado
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // =========================
  // 📥 INBOX – Lista de Conversas (sem flash)
  // =========================
  useEffect(() => {
    if (!user) return;

    const unsubscribes = [];

    const carregarConversasRealtime = async () => {
      const meuDoc = await getDoc(doc(db, "usuarios", user.uid));
      if (!meuDoc.exists()) {
        setConversas([]);
        return;
      }

      const dados = meuDoc.data();
      const seguindo = dados?.seguindo || [];

      if (seguindo.length === 0) {
        setConversas([]);
        return;
      }

      seguindo.forEach((id) => {
        const cid = [user.uid, id].sort().join("_");

        const q = query(
          collection(db, "chats", cid, "mensagens"),
          orderBy("createdAt", "desc"),
          limit(1)
        );

        const unsubscribe = onSnapshot(q, async (snapshot) => {
          let ultimaMsg = "Nenhuma mensagem ainda";
          let ultimaData = null;

          if (!snapshot.empty) {
            const msg = snapshot.docs[0].data();
            ultimaMsg = msg.texto;
            ultimaData = msg.createdAt?.toDate?.() || new Date();
          }

          const qNaoLidas = query(
            collection(db, "chats", cid, "mensagens"),
            where("userId", "!=", user.uid)
          );
          const snapNaoLidas = await getDocs(qNaoLidas);
          const naoLidas = snapNaoLidas.docs.filter(
            (d) => d.data().status !== "visto"
          ).length;

          const userDoc = await getDoc(doc(db, "usuarios", id));
          const u = userDoc.data();

          setConversas((prev) => {
            const base = Array.isArray(prev) ? prev : [];
            const outras = base.filter((c) => c.chatId !== cid);

            const nova = {
              chatId: cid,
              nome: u?.nome || "Usuário",
              foto: u?.fotoPerfil || "",
              ultimaMensagem: ultimaMsg,
              ultimaData: ultimaData,
              naoLidas,
              outroId: id, // ✅ guarda o ID do outro usuário para navegação
            };

            return [nova, ...outras].sort((a, b) => {
              if (!a.ultimaData) return 1;
              if (!b.ultimaData) return -1;
              return b.ultimaData - a.ultimaData;
            });
          });
        });

        unsubscribes.push(unsubscribe);
      });
    };

    carregarConversasRealtime();

    return () => {
      unsubscribes.forEach((unsub) => unsub());
    };
  }, [user]);

  // 🔄 LIMPEZA SINCRONA AO TROCAR DE CONVERSA (elimina flash)
  useLayoutEffect(() => {
    setPermitido(null);
    setMensagens([]);
    setOutroUsuario(null);
    setDigitando(false);
    setShowScrollBtn(false);
    setLoadingMessages(true);
    primeiraCargaRef.current = true;
  }, [chatId]);

  // =========================
  // 🔒 Permissão + dados do outro usuário (inclui ID)
  // Chat liberado se A segue B ou B segue A
  // =========================
  useEffect(() => {
    if (!user || !chatId) {
      setPermitido(null);
      return;
    }

    setPermitido(null);

    const ids = chatId.split("_");
    const outroId = ids.find((id) => id !== user.uid);

    // Carrega dados do outro usuário (one-shot) – INCLUI O ID
    const carregarOutroUsuario = async () => {
      try {
        const outroDoc = await getDoc(doc(db, "usuarios", outroId));
        if (outroDoc.exists()) {
          const outro = outroDoc.data();
          setOutroUsuario({
            id: outroId,               // ✅ agora tem o id
            nome: outro?.nome || "Usuário",
            foto: outro?.fotoPerfil || "",
          });
        }
      } catch (e) {
        console.error("Erro ao carregar outro usuário:", e);
      }
    };

    carregarOutroUsuario();

    // Permissão: liberado se A segue B ou B segue A
    const verificarPermissao = async () => {
      try {
        const meuDoc   = await getDoc(doc(db, "usuarios", user.uid));
        const outroDoc = await getDoc(doc(db, "usuarios", outroId));

        if (!meuDoc.exists() || !outroDoc.exists()) {
          setPermitido(false);
          setLoadingMessages(false);
          return;
        }

        const meusDados   = meuDoc.data();
        const outrosDados = outroDoc.data();

        const euSigoEle  = (meusDados.seguindo   || []).includes(outroId);
        const eleSegueEu = (outrosDados.seguindo  || []).includes(user.uid);

        setPermitido(euSigoEle || eleSegueEu);
        if (!euSigoEle && !eleSegueEu) setLoadingMessages(false);
      } catch (error) {
        console.error("Erro ao verificar permissão:", error);
        setPermitido(false);
        setLoadingMessages(false);
      }
    };

    verificarPermissao();

    return () => {};
  }, [user, chatId]);

  // =========================
  // 💬 Mensagens em Tempo Real + Marcar como Visto
  // =========================
  useEffect(() => {
    if (!chatId || !permitido || !user) return;

    const q = query(
      collection(db, "chats", chatId, "mensagens"),
      orderBy("createdAt", "asc")
    );

    const unsubscribe = onSnapshot(q, async (snapshot) => {
      const msgs = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      setMensagens(msgs);
      setLoadingMessages(false);

      const mensagensParaAtualizar = snapshot.docs.filter((d) => {
        const m = d.data();
        return m.userId !== user.uid && m.status !== "visto";
      });

      if (mensagensParaAtualizar.length > 0) {
        await Promise.all(
          mensagensParaAtualizar.map(async (docSnap) => {
            try {
              await updateDoc(docSnap.ref, { status: "visto" });
            } catch (e) {
              console.log("Erro ao marcar como visto:", e);
            }
          })
        );
      }
    });

    return unsubscribe;
  }, [chatId, permitido, user]);

  // ✅ Efeito único de scroll
  useEffect(() => {
    const container = mensagensContainerRef.current;
    if (!container) return;

    if (primeiraCargaRef.current) {
      const timer = setTimeout(() => {
        container.scrollTop = container.scrollHeight;
      }, 0);
      primeiraCargaRef.current = false;
      return () => clearTimeout(timer);
    }

    if (!showScrollBtn) {
      mensagensEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [mensagens, showScrollBtn, digitando]);

  // =========================
  // ✉️ Enviar Mensagem
  // =========================
  const enviarMensagem = async () => {
    if (!texto.trim() || enviando || !permitido) return;
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
          deId: user.uid,
          para: outroId,
          texto: texto.trim(),
          chatId: chatId,
          createdAt: serverTimestamp(),
          lida: false,
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

  const conversasFiltradas = conversas
    ? conversas.filter((c) =>
        c.nome.toLowerCase().includes(busca.toLowerCase())
      )
    : [];

  // =========================
  // 🎨 RENDER
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
      const classeSequencia = mesmoRemetente ? "sequencia" : "";

      const separador = mostrarData ? (
        <div className="date-separator" key={`data-${msg.id}`}>
          {formatarDataAmigavel(msg.createdAt)}
        </div>
      ) : null;

      return (
        <React.Fragment key={msg.id}>
          {separador}
          <div
            className={`msg-group ${isMine ? "mine" : "theirs"} ${classeSequencia}`}
          >
            <div className="msg-content">
              <div className={`msg-bubble ${isMine ? "me" : "other"}`}>
                <p>{msg.texto}</p>
                <span className="msg-time">
                  {hora}
                  {isMine && (
                    <span
                      className={`msg-status ${msg.status === "visto" ? "visto" : ""}`}
                      title={msg.status === "visto" ? "Visto" : "Enviado"}
                    >
                      <span className="material-symbols-outlined">
                        {msg.status === "visto" ? "done_all" : "done"}
                      </span>
                    </span>
                  )}
                </span>
              </div>
            </div>
          </div>
        </React.Fragment>
      );
    });
  };

  return (
    <Layout>
      <div className="chat-page">
        <div className={`chat-layout ${chatId ? "show-chat" : "show-list"}`}>
          {/* ── Painel de Conversas ── */}
          <aside className="conversations-panel">
            <div className="conversations-header">
              <h2>Conversas</h2>
              <div className="search-box">
                <span className="material-symbols-outlined">search</span>
                <input
                  type="text"
                  placeholder="Buscar conversa..."
                  value={busca}
                  onChange={(e) => setBusca(e.target.value)}
                />
              </div>
            </div>

            {conversas === null ? (
              <div className="conversations-loading">
                <div className="spinner" />
                <span>Carregando conversas...</span>
              </div>
            ) : (
              <div className="conversations-list">
                {conversasFiltradas.length === 0 ? (
                  <div className="conversa-vazia">
                    {busca ? (
                      <>
                        😕 Nenhuma conversa encontrada para "<strong>{busca}</strong>"
                      </>
                    ) : (
                      <>
                        🎣 Você ainda não segue ninguém.<br />
                        Descubra pescadores na pesquisa!
                      </>
                    )}
                  </div>
                ) : (
                  conversasFiltradas.map((c) => (
                    <div
                      key={c.chatId}
                      className={`conversation-item ${chatId === c.chatId ? "active" : ""}`}
                    >
                      {/* CLIQUE NO CONTAINER PRINCIPAL → ABRE O CHAT */}
                      <div
                        className="conversation-item__chat-area"
                        onClick={() => navigate(`/chat/${c.chatId}`)}
                        style={{ display: 'flex', flex: 1, alignItems: 'center', gap: '12px' }}
                      >
                        {/* AVATAR: navega para perfil com stopPropagation */}
                        <div
                          className="conv-avatar"
                          onClick={(e) => {
                            e.stopPropagation();
                            navigate(`/perfil/${c.outroId}`);
                          }}
                          style={{ cursor: 'pointer' }}
                        >
                          {c.foto ? (
                            <img src={c.foto} alt={c.nome} />
                          ) : (
                            <div className="fallback">
                              {c.nome.charAt(0).toUpperCase()}
                            </div>
                          )}
                        </div>

                        <div className="conv-info">
                          <div className="conv-top">
                            {/* NOME: navega para perfil com stopPropagation */}
                            <span
                              className="conv-name"
                              onClick={(e) => {
                                e.stopPropagation();
                                navigate(`/perfil/${c.outroId}`);
                              }}
                              style={{ cursor: 'pointer' }}
                            >
                              {c.nome}
                            </span>
                            <span className="conv-time">{tempoRelativo(c.ultimaData)}</span>
                          </div>
                          <div className="conv-bottom">
                            <span className="conv-preview">{c.ultimaMensagem}</span>
                            {c.naoLidas > 0 && (
                              <span className="conv-badge">{c.naoLidas}</span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            )}
          </aside>

          {/* ── Painel do Chat ── */}
          <main className="chat-panel">
            {!chatId ? (
              <div className="chat-empty-state">
                <div className="chat-empty-icon">💬</div>
                <p>Selecione uma conversa</p>
                <span>Escolha um pescador para começar a conversar</span>
              </div>
            ) : permitido === null || loadingMessages ? (
              <div className="chat-messages chat-messages--loading">
                {Array.from({ length: 4 }).map((_, i) => (
                  <div
                    key={i}
                    className={`skeleton-message ${i % 2 === 0 ? 'skeleton--mine' : 'skeleton--theirs'}`}
                  >
                    <div className="skeleton-avatar" />
                    <div className="skeleton-bubble">
                      <div className="skeleton-line short" />
                      <div className="skeleton-line medium" />
                    </div>
                  </div>
                ))}
              </div>
            ) : !permitido ? (
              <div className="chat-empty-state">
                <div className="chat-empty-icon" style={{ fontSize: "2.5rem" }}>
                  🔒
                </div>
                <p>Chat bloqueado</p>
                <span>
                  Siga este pescador ou aguarde ele te seguir para conversar.
                </span>
                <button
                  className="btn-voltar-bloqueio"
                  onClick={() => navigate("/chat")}
                >
                  <span className="material-symbols-outlined">arrow_back</span>
                  Voltar
                </button>
              </div>
            ) : (
              <>
                <header className="chat-header">
                  {window.innerWidth <= 768 && (
                    <button
                      className="icon-btn"
                      onClick={() => navigate("/chat")}
                      title="Voltar"
                    >
                      <span className="material-symbols-outlined">arrow_back</span>
                    </button>
                  )}
                  <div className="chat-header-left" key={chatId}>
                    {/* AVATAR CLICÁVEL */}
                    <div
                      className="chat-header-avatar"
                      onClick={() => navigate(`/perfil/${outroUsuario?.id}`)}
                      style={{ cursor: 'pointer' }}
                    >
                      {outroUsuario?.foto ? (
                        <img src={outroUsuario.foto} alt={outroUsuario.nome} />
                      ) : (
                        <div className="fallback">
                          {outroUsuario?.nome?.charAt(0) || "?"}
                        </div>
                      )}
                    </div>
                    <div className="chat-header-info">
                      {/* NOME CLICÁVEL */}
                      <h3
                        onClick={() => navigate(`/perfil/${outroUsuario?.id}`)}
                        style={{ cursor: 'pointer' }}
                      >
                        {outroUsuario?.nome || "Pescador"}
                      </h3>
                      {digitando ? (
                        <span className="digitando">digitando...</span>
                      ) : (
                        <span>
                          <span className="online-dot" />
                          Online
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="chat-header-actions">
                    <button className="icon-btn" title="Ligar">
                      <span className="material-symbols-outlined">call</span>
                    </button>
                    <button className="icon-btn" title="Vídeo">
                      <span className="material-symbols-outlined">videocam</span>
                    </button>
                    <button className="icon-btn" title="Mais opções">
                      <span className="material-symbols-outlined">more_vert</span>
                    </button>
                  </div>
                </header>

                <div
                  className="chat-messages"
                  ref={mensagensContainerRef}
                  onScroll={handleScroll}
                >
                  {mensagens.length === 0 && !digitando ? (
                    <div className="chat-empty-state">
                      <div className="chat-empty-icon">👋</div>
                      <p>Nenhuma mensagem ainda</p>
                      <span>Seja o primeiro a dizer olá!</span>
                    </div>
                  ) : (
                    renderizarMensagens()
                  )}

                  {digitando && (
                    <div className="msg-digitando">
                      <div className="bolha-digitando">
                        <span></span>
                        <span></span>
                        <span></span>
                      </div>
                    </div>
                  )}

                  <div ref={mensagensEndRef} />
                </div>

                {showScrollBtn && (
                  <button
                    className="btn-scroll-bottom"
                    onClick={scrollToBottom}
                    title="Rolar para baixo"
                  >
                    <span className="material-symbols-outlined">arrow_downward</span>
                  </button>
                )}

                <div className="chat-input-area">
                  <div className="chat-input-row">
                    <button className="btn-attach" title="Anexar">
                      <span className="material-symbols-outlined">add</span>
                    </button>
                    <input
                      value={texto}
                      onChange={(e) => {
                        setTexto(e.target.value);
                        if (e.target.value.length > 500) {
                          setTexto(e.target.value.slice(0, 500));
                        }
                      }}
                      placeholder="Digite uma mensagem..."
                      onKeyDown={(e) => e.key === "Enter" && !e.shiftKey && enviarMensagem()}
                      maxLength={500}
                    />
                    <button className="btn-attach" title="Emoji">
                      <span className="material-symbols-outlined">mood</span>
                    </button>
                    <button
                      className="btn-send"
                      onClick={enviarMensagem}
                      disabled={!texto.trim() || enviando}
                      title="Enviar mensagem"
                    >
                      {enviando ? (
                        <div className="spinner-sm" />
                      ) : (
                        <span className="material-symbols-outlined">send</span>
                      )}
                    </button>
                  </div>
                  <span className="char-count">{texto.length}/500</span>
                </div>
              </>
            )}
          </main>
        </div>
      </div>
    </Layout>
  );
}