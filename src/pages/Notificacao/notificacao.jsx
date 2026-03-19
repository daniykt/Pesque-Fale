import React, { useState } from "react";
import { Link } from "react-router-dom";
import "./notificacao.css";

export default function Notificacao() {

  // Estado inicial com suporte a curtidas e favoritos
  const [notificacoes, setNotificacoes] = useState([
    {
      id: 1,
      data: "05/05/2025 10:35",
      usuario: "Reginaldosilva",
      texto:
        "Lugarzinho da hora pra pescar, viu? Vou aproveitar mais vezes com certeza!",
      lida: false,
      curtida: null,
      favorito: false,
    },
    {
      id: 2,
      data: "14/09/2025 12:00",
      usuario: "Carlos_ferreira",
      texto:
        "Você pode me informar se aí é permitido usar molinete profissional?",
      lida: false,
      curtida: null,
      favorito: false,
    },
    {
      id: 3,
      data: "20/02/2025 15:30",
      usuario: "Sistema",
      texto: "Pedro e João começaram a seguir você",
      lida: false,
      curtida: null,
      favorito: false,
    },
    {
      id: 4,
      data: "01/06/2025 20:30",
      usuario: "Sistema",
      texto: "Maria e Lucas curtiram seu post.",
      lida: false,
      curtida: null,
      favorito: false,
    },
    {
      id: 5,
      data: "24/11/2025 19:30",
      usuario: "Sistema",
      texto: "Seu post Dicas de pesca para iniciantes atingiu 100 curtidas!",
      lida: false,
      curtida: null,
      favorito: false,
    },
    {
      id: 6,
      data: "10/10/2025 22:00",
      usuario: "Marinasantos",
      texto: "Adorei as fotos do seu último passeio!",
      lida: false,
      curtida: null,
      favorito: false,
    },
  ]);

  //  FUNÇÕES

  const toggleCurtir = (id) => {
    setNotificacoes(
      notificacoes.map((n) =>
        n.id === id
          ? { ...n, curtida: n.curtida === "like" ? null : "like" }
          : n,
      ),
    );
  };

  const toggleDescurtir = (id) => {
    setNotificacoes(
      notificacoes.map((n) =>
        n.id === id
          ? { ...n, curtida: n.curtida === "dislike" ? null : "dislike" }
          : n,
      ),
    );
  };

  const toggleFavorito = (id) => {
    setNotificacoes(
      notificacoes.map((n) =>
        n.id === id ? { ...n, favorito: !n.favorito } : n,
      ),
    );
  };

  const excluir = (id) => {
    setNotificacoes(notificacoes.filter((n) => n.id !== id));
  };

  const marcarComoLida = (id) => {
    setNotificacoes(
      notificacoes.map((n) => (n.id === id ? { ...n, lida: !n.lida } : n)),
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
    <div className="layout-container">
      {/* Sidebar simulada */}
      <nav className="sidebar">
        <div className="sidebar-header">
          <img
            src=".assets/logo/logo.jpg"
            alt="Pesque & Fale"
            className="logo"
            width="100"
          />
        </div>
      </nav>

      <div className="column">
        <div className="main-content">
          <div className="container-notificacoes">
            {notificacoes.map((n) => (
              <div
                key={n.id}
                className={`notificacao ${n.lida ? "lida-estilo" : ""}`}
              >
                <div className="meta">
                  <span className="data">{n.data}</span>
                  <button className="close" onClick={() => excluir(n.id)}>
                    &times;
                  </button>
                </div>

                <p className="comentario">
                  <strong>{n.usuario}:</strong> {n.texto}
                </p>

                <div
                  className="botoes"
                  style={{ display: "flex", gap: "10px", marginTop: "15px" }}
                >
                  {/* Botão Marcar como lida */}
                  <button
                    onClick={() => marcarComoLida(n.id)}
                    style={estiloBotaoBase}
                  >
                    <i className="fas fa-check"></i>{" "}
                    {n.lida ? "Lida" : "Marcar como lida"}
                  </button>

                  {/* Botão Curtir - Muda para verde se ativo */}
                  <button
                    onClick={() => toggleCurtir(n.id)}
                    style={{
                      ...estiloBotaoBase,
                      backgroundColor:
                        n.curtida === "like" ? "#28a745" : "#082a66",
                    }}
                  >
                    <i
                      className={
                        n.curtida === "like"
                          ? "fas fa-thumbs-up"
                          : "far fa-thumbs-up"
                      }
                    ></i>{" "}
                    Curtir
                  </button>

                  {/* Botão Não Curtir - Muda para vermelho se ativo */}
                  <button
                    onClick={() => toggleDescurtir(n.id)}
                    style={{
                      ...estiloBotaoBase,
                      backgroundColor:
                        n.curtida === "dislike" ? "#bb1b2bff" : "#082a66",
                    }}
                  >
                    <i
                      className={
                        n.curtida === "dislike"
                          ? "fas fa-thumbs-down"
                          : "far fa-thumbs-down"
                      }
                    ></i>{" "}
                    Não Curtir
                  </button>

                  {/* Botão Favorito - Muda para amarelo se ativo */}
                  <button
                    onClick={() => toggleFavorito(n.id)}
                    style={{
                      ...estiloBotaoBase,
                      backgroundColor: n.favorito ? "#ffc107" : "#082a66",
                    }}
                  >
                    <i
                      className={n.favorito ? "fas fa-star" : "far fa-star"}
                    ></i>{" "}
                    Favorito
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
        </div>

        {/* Rodapé */}
        <footer>
          <div className="footer-container">
            <div>
              <h3>Sobre Nós</h3>
              <p>Grupo de estudantes dedicados ao desenvolvimento de iniciativas voltadas à melhoria do trabalho socioeconômico em Matão-SP e região.
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
          <p className="copyright">
            &copy; Pesque & Fale 2025 - Todos os direitos reservados.
          </p>
        </footer>
      </div>
    </div>
  );
}
