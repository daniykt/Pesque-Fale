import React, { useEffect, useState, useRef } from "react";
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
} from "firebase/firestore";

import { observeAuthState } from "../../auth";

export default function Chat() {
  const [user, setUser] = useState(null);
  const [mensagens, setMensagens] = useState([]);
  const [texto, setTexto] = useState("");
  const [enviando, setEnviando] = useState(false);
  const mensagensEndRef = useRef(null);
  const inputRef = useRef(null);

  // 🔐 Observar usuário logado
  useEffect(() => {
    const unsubscribe = observeAuthState((u) => setUser(u));
    return unsubscribe;
  }, []);

  // 🔥 Mensagens em tempo real
  useEffect(() => {
    const q = query(collection(db, "chats"), orderBy("createdAt", "asc"));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const lista = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      setMensagens(lista);
    });
    return unsubscribe;
  }, []);

  // 📜 Auto-scroll para última mensagem
  useEffect(() => {
    mensagensEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [mensagens]);

  // ✉️ Enviar mensagem
  const enviarMensagem = async () => {
    if (!texto.trim()) return;
    if (!user) return alert("Faça login para participar do chat");

    setEnviando(true);
    try {
      await addDoc(collection(db, "chats"), {
        texto,
        userId: user.uid,
        nome: user.displayName || "Pescador Anônimo",
        foto: user.photoURL || "",
        createdAt: serverTimestamp(),
      });
      setTexto("");
      inputRef.current?.focus();
    } catch (error) {
      console.error("Erro ao enviar:", error);
    } finally {
      setEnviando(false);
    }
  };

  // ⌨️ Enter para enviar
  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      enviarMensagem();
    }
  };

  // 🕐 Formatar horário
  const formatarHora = (timestamp) => {
    if (!timestamp?.toDate) return "";
    return timestamp.toDate().toLocaleTimeString("pt-BR", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  // 🅰️ Iniciais do nome
  const getIniciais = (nome) => {
    return nome
      ?.split(" ")
      .map((p) => p[0])
      .slice(0, 2)
      .join("")
      .toUpperCase() || "?";
  };

  // 🎨 Cor do avatar baseada no nome
  const getAvatarColor = (nome) => {
    const cores = [
      "#2E7D5E", "#1A5276", "#6E4B7B", "#7D3C28",
      "#2E86C1", "#1E8449", "#922B21", "#7D6608",
    ];
    let hash = 0;
    for (let i = 0; i < (nome?.length || 0); i++) {
      hash = nome.charCodeAt(i) + ((hash << 5) - hash);
    }
    return cores[Math.abs(hash) % cores.length];
  };

  return (
    <Layout>
      <div className="chat-wrapper">
        {/* Header */}
        <header className="chat-header">
          <div className="chat-header-left">
            <div className="chat-header-icon">🎣</div>
            <div>
              <h1 className="chat-title">Chat dos Pescadores</h1>
              <p className="chat-subtitle">
                <span className="online-dot" />
                {mensagens.length > 0
                  ? `${mensagens.length} mensagem${mensagens.length !== 1 ? "s" : ""}`
                  : "Seja o primeiro a pescar uma conversa!"}
              </p>
            </div>
          </div>
          <div className="chat-header-right">
            {user ? (
              <div className="user-badge">
                {user.photoURL ? (
                  <img src={user.photoURL} alt={user.displayName} className="user-avatar-img" />
                ) : (
                  <div
                    className="user-avatar-placeholder"
                    style={{ background: getAvatarColor(user.displayName) }}
                  >
                    {getIniciais(user.displayName)}
                  </div>
                )}
                <span className="user-name-badge">{user.displayName?.split(" ")[0]}</span>
              </div>
            ) : (
              <span className="login-hint">⚠️ Faça login para participar</span>
            )}
          </div>
        </header>

        {/* Área de mensagens */}
        <div className="chat-mensagens">
          {mensagens.length === 0 ? (
            <div className="chat-vazio">
              <div className="chat-vazio-icon">🌊</div>
              <p>O rio está quieto por enquanto…</p>
              <span>Seja o primeiro a lançar uma mensagem!</span>
            </div>
          ) : (
            mensagens.map((msg, i) => {
              const eMinha = msg.userId === user?.uid;
              const mesmoRemetente = i > 0 && mensagens[i - 1].userId === msg.userId;

              return (
                <div
                  key={msg.id}
                  className={`msg-grupo ${eMinha ? "msg-grupo--minha" : "msg-grupo--outra"} ${mesmoRemetente ? "msg-grupo--sequencia" : ""}`}
                >
                  {/* Avatar (só aparece na primeira mensagem de uma sequência) */}
                  {!eMinha && !mesmoRemetente && (
                    <div
                      className="msg-avatar"
                      style={{ background: getAvatarColor(msg.nome) }}
                      title={msg.nome}
                    >
                      {msg.foto ? (
                        <img src={msg.foto} alt={msg.nome} />
                      ) : (
                        getIniciais(msg.nome)
                      )}
                    </div>
                  )}
                  {!eMinha && mesmoRemetente && <div className="msg-avatar-spacer" />}

                  <div className="msg-conteudo">
                    {!eMinha && !mesmoRemetente && (
                      <span className="msg-nome">{msg.nome}</span>
                    )}
                    <div className={`msg-bolha ${eMinha ? "msg-bolha--minha" : "msg-bolha--outra"}`}>
                      <p>{msg.texto}</p>
                      <span className="msg-hora">{formatarHora(msg.createdAt)}</span>
                    </div>
                  </div>
                </div>
              );
            })
          )}
          <div ref={mensagensEndRef} />
        </div>

        {/* Input de envio */}
        <div className="chat-input-area">
          {!user && (
            <div className="chat-login-aviso">
              🔒 Faça login para enviar mensagens
            </div>
          )}
          <div className={`chat-input-row ${!user ? "chat-input-row--disabled" : ""}`}>
            <input
              ref={inputRef}
              type="text"
              placeholder={user ? "Digite sua mensagem... 🎣" : "Faça login para participar"}
              value={texto}
              onChange={(e) => setTexto(e.target.value)}
              onKeyDown={handleKeyDown}
              disabled={!user || enviando}
              maxLength={500}
            />
            <button
              onClick={enviarMensagem}
              disabled={!user || enviando || !texto.trim()}
              className={`btn-enviar ${enviando ? "btn-enviar--carregando" : ""}`}
              title="Enviar mensagem (Enter)"
            >
              {enviando ? (
                <span className="spinner" />
              ) : (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <path d="M22 2L11 13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M22 2L15 22L11 13L2 9L22 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              )}
            </button>
          </div>
          {texto.length > 400 && (
            <span className="char-count">{texto.length}/500</span>
          )}
        </div>
      </div>

      {/* Footer */}
      <footer>
        <div className="footer-container">
          <div className="footer-info">
            <h3>Sobre Nós</h3>
            <p>
              Plataforma criada por estudantes com o objetivo de conectar pescadores,
              compartilhar experiências e fortalecer a comunidade de pesca em Matão-SP e região.
            </p>
          </div>
          <div className="footer-links">
            <h3>Links Úteis</h3>
            <a href="/home">Página Inicial</a><br />
            <a href="/pesquisar">Pesquisa de Locais</a><br />
            <a href="/chat">Chat de Pescadores</a><br />
            <a href="/notificacao">Notificações</a><br />
            <a href="/sobre">Sobre Nós</a><br />
            <a href="/perfil">Perfil</a>
          </div>
          <div className="footer-contact">
            <h3>Contato</h3>
            <p>Email: <strong>pesquefale@gmail.com</strong></p>
          </div>
        </div>
        <p className="copyright">
          &copy; Pesque &amp; Fale 2026 - Todos os direitos reservados.
        </p>
      </footer>
    </Layout>
  );
}
