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
} from "firebase/firestore";

import { observeAuthState } from "../../auth";

export default function Notificacao() {
  const [user, setUser] = useState(null);
  const [notificacoes, setNotificacoes] = useState([]);

  // 🔐 usuário
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // 🔔 buscar notificações
  useEffect(() => {
    if (!user) return;

    const q = query(
      collection(db, "notificacoes"),
      where("para", "==", user.uid),
      orderBy("createdAt", "desc")
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const lista = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      setNotificacoes(lista);
    });

    return unsubscribe;
  }, [user]);

  // 🗑️ excluir
  const excluirNotificacao = async (id) => {
    await deleteDoc(doc(db, "notificacoes", id));
  };

  // ⏱️ tempo relativo
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

  // 🧠 texto
  const renderTexto = (n) => {
    switch (n.tipo) {
      case "seguindo":
        return (
          <>
            <strong>{n.de}</strong> começou a seguir você
          </>
        );

      case "curtida":
        return (
          <>
            <strong>{n.de}</strong> curtiu sua publicação
          </>
        );

      case "comentario":
        return (
          <>
            <strong>{n.de}</strong> comentou na sua publicação:
            <span className="texto-comentario"> "{n.texto}"</span>
          </>
        );

      case "mensagem":
        return (
          <>
            <strong>{n.de}</strong> te enviou uma mensagem:
            <span className="texto-comentario"> "{n.texto}"</span>
          </>
        );

      default:
        return "Nova notificação";
    }
  };

  // 🎯 ícones corrigidos
  const renderIcone = (tipo) => {
    switch (tipo) {
      case "seguindo":
        return "👤";
      case "curtida":
        return "👍";
      case "comentario":
        return "💬";
      case "mensagem":
        return "📩"; // 🔥 NOVO
      default:
        return "🔔";
    }
  };

  return (
    <Layout>
      <div className="container-notificacoes">

        <h2 className="titulo">🔔 Notificações</h2>

        {notificacoes.length === 0 ? (
          <p className="vazio">Nenhuma notificação ainda</p>
        ) : (
          notificacoes.map((n) => (
            <div key={n.id} className="card-notificacao">

              {/* 🔥 ÍCONE CORRIGIDO */}
              <div className="icone">
                {renderIcone(n.tipo)}
              </div>

              {/* CONTEÚDO */}
              <div className="conteudo">
                <p className="texto">{renderTexto(n)}</p>
                <span className="tempo">
                  {tempoRelativo(n.createdAt)}
                </span>
              </div>

              {/* EXCLUIR */}
              <button
                className="btn-excluir"
                onClick={() => excluirNotificacao(n.id)}
              >
                ✖
              </button>

            </div>
          ))
        )}

      </div>

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
    &copy; Pesque & Fale 2026 - Todos os direitos reservados.
  </p>
</footer>
    </Layout>
  );
}