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
  // 🔒 PERMISSÃO
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
  // ✉️ ENVIAR
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

  // =========================
  // 🔥 INBOX UI
  // =========================
  if (!chatId) {
    return (
      <Layout>
        <div className="chat-wrapper">
          <h2 style={{ marginBottom: "20px" }}>💬 Conversas</h2>

          {conversas.length === 0 ? (
            <p>Você ainda não segue ninguém</p>
          ) : (
            conversas.map((c) => (
              <div
                key={c.chatId}
                className="chat-item"
                onClick={() => navigate(`/chat/${c.chatId}`)}
                style={{
                  padding: "12px",
                  borderBottom: "1px solid #ddd",
                  cursor: "pointer",
                }}
              >
                <strong>{c.nome}</strong>
                <p style={{ opacity: 0.7 }}>
                  Toque para iniciar uma conversa
                </p>
              </div>
            ))
          )}
        </div>

        {/* ✅ FOOTER */}
        <footer>
          <div className="footer-container">

            <div className="footer-info">
              <h3>Sobre Nós</h3>
              <p>
                Plataforma criada por estudantes com o objetivo de conectar pescadores,
                compartilhar experiências e fortalecer a comunidade de pesca.
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
            &copy; Pesque & Fale 2026
          </p>
        </footer>

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
  // 💬 CHAT
  // =========================
  return (
    <Layout>
      <div className="chat-wrapper">

        <div className="chat-mensagens">
          {mensagens.map((msg) => (
            <div key={msg.id}>
              <strong>{msg.nome}</strong>
              <p>{msg.texto}</p>
            </div>
          ))}
          <div ref={mensagensEndRef} />
        </div>

        <div className="chat-input-area">
          <input
            value={texto}
            onChange={(e) => setTexto(e.target.value)}
            placeholder="Digite..."
          />
          <button onClick={enviarMensagem}>Enviar</button>
        </div>

      </div>

      {/* ✅ FOOTER TAMBÉM NO CHAT */}
      <footer>
        <div className="footer-container">

          <div className="footer-info">
            <h3>Sobre Nós</h3>
            <p>
              Plataforma criada para conectar pescadores e compartilhar experiências.
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
          &copy; 2026 Pesque & Fale
        </p>
      </footer>

    </Layout>
  );
}