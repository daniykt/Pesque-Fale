import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./notificacao.css";

export default function Notificacao() {
  const [notificacoes, setNotificacoes] = useState([]);

  useEffect(() => {
    localStorage.removeItem("notificacoes");
    localStorage.removeItem("contadorNotificacoes");

    const dadosIniciais = [
      {
        id: 1,
        data: "05/05/2025 10:35",
        usuario: "Reginaldosilva",
        texto: "Lugarzinho da hora pra pescar, viu? Vou aproveitar mais vezes com certeza!",
        lida: false,
        curtida: null,
        favorito: false,
      },
      {
        id: 2,
        data: "05/05/2025 11:10",
        usuario: "JoaoPescador",
        texto: "A pescaria de sábado foi ótima, peguei um dourado enorme no laguna!",
        lida: false,
        curtida: null,
        favorito: false,
      },
      {
        id: 3,
        data: "06/05/2025 09:15",
        usuario: "MariaClara",
        texto: "Gostei muito da estrutura do local, banheiros limpos e atendimento nota 10.",
        lida: false,
        curtida: null,
        favorito: false,
      },
      {
        id: 4,
        data: "06/05/2025 14:22",
        usuario: "PedroSantos",
        texto: "O acesso é um pouco difícil se chover, mas o peixe compensa a viagem.",
        lida: false,
        curtida: null,
        favorito: false,
      },
      {
        id: 5,
        data: "07/05/2025 08:45",
        usuario: "AnaBeatriz",
        texto: "Preços justos pelo passeio e aluguel de barco. Recomendo para famílias.",
        lida: false,
        curtida: null,
        favorito: false,
      },
      {
        id: 6,
        data: "07/05/2025 16:00",
        usuario: "LucasAndrade",
        texto: "Voltarei com a família no próximo feriado. Ambiente muito tranquilo e seguro.",
        lida: false,
        curtida: null,
        favorito: false,
      },
    ];
    
    setNotificacoes(dadosIniciais);
    localStorage.setItem("notificacoes", JSON.stringify(dadosIniciais));
    
    // Atualiza o contador no Sidebar imediatamente
    localStorage.setItem("contadorNotificacoes", dadosIniciais.length);
    window.dispatchEvent(new CustomEvent("notificacoesAtualizadas", { detail: dadosIniciais.length }));

  }, []);

  useEffect(() => {
    if (notificacoes.length > 0) {
      localStorage.setItem("notificacoes", JSON.stringify(notificacoes));
    }
    const naoLidas = notificacoes.filter((n) => !n.lida).length;
    localStorage.setItem("contadorNotificacoes", naoLidas);
    window.dispatchEvent(new CustomEvent("notificacoesAtualizadas", { detail: naoLidas }));
  }, [notificacoes]);

  const toggleCurtir = (id) => {
    setNotificacoes((prev) =>
      prev.map((n) =>
        n.id === id ? { ...n, curtida: n.curtida === "like" ? null : "like" } : n
      )
    );
  };

  const toggleDescurtir = (id) => {
    setNotificacoes((prev) =>
      prev.map((n) =>
        n.id === id ? { ...n, curtida: n.curtida === "dislike" ? null : "dislike" } : n
      )
    );
  };

  const toggleFavorito = (id) => {
    setNotificacoes((prev) =>
      prev.map((n) => (n.id === id ? { ...n, favorito: !n.favorito } : n))
    );
  };

  const excluir = (id) => {
    setNotificacoes((prev) => prev.filter((n) => n.id !== id));
  };

  const marcarComoLida = (id) => {
    setNotificacoes((prev) =>
      prev.map((n) => (n.id === id ? { ...n, lida: true } : n))
    );
  };

  // Estilo base dos botões
  const estiloBotaoBase = {
    backgroundColor: "#082a66",
    color: "white",
    border: "none",
    padding: "8px 15px",
    borderRadius: "8px",
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    gap: "8px",
    fontWeight: "bold",
    fontSize: "14px",
  };

  return (
    <Layout>
      {/* Conteúdo principal - será expandido pelo flex */}
      <div className="container-notificacoes" style={{ paddingTop: "20px" }}>
        {notificacoes.map((n) => (
          <div key={n.id} className={`notificacao ${n.lida ? "lida" : ""}`}>
            <div className="meta">
              <span className="data">{n.data}</span>
              <button className="close" onClick={() => excluir(n.id)}>
                &times;
              </button>
            </div>
            <p className="comentario">
              <strong>{n.usuario}:</strong> {n.texto}
            </p>
            <div className="botoes">
              <button
                onClick={() => marcarComoLida(n.id)}
                style={estiloBotaoBase}
                disabled={n.lida}
              >
                <i className="fas fa-check"></i> {n.lida ? "Lida" : "Marcar como lida"}
              </button>
              <button
                onClick={() => toggleCurtir(n.id)}
                style={{
                  ...estiloBotaoBase,
                  backgroundColor: n.curtida === "like" ? "#28a745" : "#082a66",
                }}
              >
                <i className={n.curtida === "like" ? "fas fa-thumbs-up" : "far fa-thumbs-up"}></i> Curtir
              </button>
              <button
                onClick={() => toggleDescurtir(n.id)}
                style={{
                  ...estiloBotaoBase,
                  backgroundColor: n.curtida === "dislike" ? "#bb1b2bff" : "#082a66",
                }}
              >
                <i className={n.curtida === "dislike" ? "fas fa-thumbs-down" : "far fa-thumbs-down"}></i> Não Curtir
              </button>
              <button
                onClick={() => toggleFavorito(n.id)}
                style={{
                  ...estiloBotaoBase,
                  backgroundColor: n.favorito ? "#ffc107" : "#082a66",
                }}
              >
                <i className={n.favorito ? "fas fa-star" : "far fa-star"}></i> Favorito
              </button>
            </div>
          </div>
        ))}
        {notificacoes.length === 0 && (
          <p style={{ textAlign: "center", marginTop: "20px" }}>
            Nenhuma notificação por enquanto!
          </p>
        )}
      </div>

      {/* Footer – agora é irmão direto do conteúdo */}
      <footer>
        <div className="footer-container">
          <div>
            <h3>Sobre Nós</h3>
            <p>
              Grupo de estudantes dedicados ao desenvolvimento de iniciativas
              voltadas à melhoria do trabalho socioeconômico em Matão-SP e região.
            </p>
          </div>
          <div>
            <h3>Links Úteis</h3>
            <Link to="/">Página Inicial</Link>
            <Link to="/pesquisar">Pesquisa de Locais</Link>
            <Link to="/locaisavaliados">Locais Avaliados</Link>
            <Link to="/sobre">Sobre nós</Link>
            <Link to="/perfil">Perfil</Link>
          </div>
          <div>
            <h3>Contato</h3>
            <p>Email: pesquefale@gmail.com</p>
          </div>
        </div>
        <p className="copyright">&copy; Pesque & Fale 2025 - Todos os direitos reservados.</p>
      </footer>
    </Layout>
  );
}