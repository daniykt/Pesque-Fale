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
  onSnapshot,
  serverTimestamp,
  doc,
  getDoc,
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
  const [outroUsuario, setOutroUsuario] = useState(null); // dados do outro usuário no chat

  const mensagensEndRef = useRef(null);

  // 🔐 usuário
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // =========================
  // 🔥 INBOX (USUÁRIOS SEGUIDOS)
  // =========================
  useEffect(() => {
    const carregarSeguindo = async () => {
      if (!user || chatId) return;

      try {
        const meuDoc = await getDoc(doc(db, "usuarios", user.uid));
        if (!meuDoc.exists()) return;

        const dados = meuDoc.data();
        const seguindo = dados?.seguindo || [];

        const lista = await Promise.all(
          seguindo.map(async (id) => {
            const docSnap = await getDoc(doc(db, "usuarios", id));
            if (!docSnap.exists()) return null;

            const u = docSnap.data();
            const chatIdGerado = [user.uid, id].sort().join("_");

            return {
              chatId: chatIdGerado,
              nome: u?.nome || "Usuário",
              foto: u?.fotoPerfil || "",
            };
          })
        );

        setConversas(lista.filter(Boolean));
      } catch (error) {
        console.error("Erro ao carregar seguindo:", error);
      }
    };

    carregarSeguindo();
  }, [user, chatId]);

  // =========================
  // 🔒 PERMISSÃO + CARREGAR DADOS DO OUTRO USUÁRIO
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

        // Buscar dados do outro usuário
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
  useEffect(() => {
    mensagensEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [mensagens]);

  // ⏱️ função para formatar hora
  const formatarHora = (timestamp) => {
    if (!timestamp) return "";
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  // =========================
  // 🔥 INBOX UI (sem chatId)
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

          <div className="lista-conversas">
            {conversas.length === 0 ? (
              <div className="conversa-vazia">
                Você ainda não segue ninguém.
              </div>
            ) : (
              conversas.map((c) => (
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
                  <div>
                    <div className="conversa-nome">{c.nome}</div>
                    <div className="conversa-dica">Toque para conversar</div>
                  </div>
                </div>
              ))
            )}
          </div>
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
  // 💬 CHAT (com chatId e permitido)
  // =========================
  return (
    <Layout>
      <div className="chat-wrapper">
        {/* Header do chat com o outro usuário */}
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

        {/* Área de mensagens */}
        <div className="chat-mensagens">
          {mensagens.length === 0 ? (
            <div className="chat-vazio">
              <span className="chat-vazio-icon">💬</span>
              <p>Nenhuma mensagem ainda</p>
              <span>Seja o primeiro a dizer olá!</span>
            </div>
          ) : (
            mensagens.map((msg) => {
              const isMine = msg.userId === user.uid;
              return (
                <div
                  key={msg.id}
                  className={`msg-grupo ${isMine ? "msg-grupo--minha" : "msg-grupo--outra"}`}
                >
                  {!isMine && (
                    <div className="msg-avatar">
                      {outroUsuario?.foto ? (
                        <img src={outroUsuario.foto} alt={msg.nome} />
                      ) : (
                        <span>{msg.nome?.charAt(0) || "?"}</span>
                      )}
                    </div>
                  )}
                  {isMine && <div className="msg-avatar-spacer" />}
                  
                  <div className="msg-conteudo">
                    {!isMine && (
                      <span className="msg-nome">{msg.nome}</span>
                    )}
                    <div className={`msg-bolha ${isMine ? "msg-bolha--minha" : "msg-bolha--outra"}`}>
                      <p>{msg.texto}</p>
                      <span className="msg-hora">
                        {formatarHora(msg.createdAt)}
                      </span>
                    </div>
                  </div>
                  
                  {isMine && (
                    <div className="msg-avatar">
                      {/* Avatar do usuário logado (pode ser o mesmo do badge no header) */}
                      <span>{user.displayName?.charAt(0) || "?"}</span>
                    </div>
                  )}
                </div>
              );
            })
          )}
          <div ref={mensagensEndRef} />
        </div>

        {/* Área de input */}
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