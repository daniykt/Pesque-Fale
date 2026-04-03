import React, { useState } from "react";
import { Link } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./locaisAvaliados.css";

const LocaisAvaliados = () => {
  const [categorias] = useState([
    {
      titulo: "Parques e Lagos",
      locais: [
        {
          id: 1,
          nome: "Lago Azul",
          imagem:
            "https://viajapinha.com.br/wp-content/uploads/2016/04/piscinas-naturais-barra-da-lagoa.jpg",
          estrelas: 5,
          descricao: "Ambiente natural e ideal para pesca esportiva.",
          localizacao: "São Carlos - SP",
        },
        {
          id: 2,
          nome: "Lago do Pescador",
          imagem:
            "https://parqueaquatico.com.br/wp-content/uploads/2023/10/Foto-17.jpg",
          estrelas: 5,
          descricao: "Ambiente familiar com ótimos quiosques.",
          localizacao: "Campinas - SP",
        },
      ],
    },
    {
      titulo: "Represas",
      locais: [
        {
          id: 3,
          nome: "Represa do Vale",
          imagem:
            "https://tse4.mm.bing.net/th/id/OIP.cXMFZTOzIOBKuoFu0zKyhQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3",
          estrelas: 4,
          descricao: "Grande variedade de peixes e ótima estrutura.",
          localizacao: "Ribeirão Preto - SP",
        },
        {
          id: 4,
          nome: "Represa da Paz",
          imagem: "https://vault.pulsarimagens.com.br/file/thumb/11JPR543.jpg",
          estrelas: 4,
          descricao: "Ideal para relaxar e pescar em meio à natureza.",
          localizacao: "Piracicaba - SP",
        },
      ],
    },
    {
      titulo: "Pesqueiros",
      locais: [
        {
          id: 5,
          nome: "Pesqueiro da Serra",
          imagem:
            "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/19/98/83/b4/pesca-esportiva.jpg?w=900&h=500&s=1",
          estrelas: 5,
          descricao: "Local tranquilo e ideal para toda a família.",
          localizacao: "Poços de Caldas - MG",
        },
        {
          id: 6,
          nome: "Rio Verde Park",
          imagem:
            "https://busbud.imgix.net/city-hires/1474307214349-Salvador,Bahia,Brazil.jpg?h=480&w=720&auto=format%2Ccompress&fit=crop",
          estrelas: 4,
          descricao: "Pesca esportiva e infraestrutura excelente.",
          localizacao: "Uberlândia - MG",
        },
      ],
    },
  ]);

  const renderStars = (rating) => {
    return "★".repeat(rating) + "☆".repeat(5 - rating);
  };

  return (
    <Layout>
      <h1>⭐ Locais + Bem Avaliados</h1>

      {categorias.map((categoria, index) => (
        <section key={index} className="categoria">
          <h2 className="categoria-titulo">{categoria.titulo}</h2>
          <div className="grid-container">
            {categoria.locais.map((local) => (
              <div key={local.id} className="card">
                <img src={local.imagem} alt={local.nome} className="card-img" />
                <div className="card-content">
                  <h3>{local.nome}</h3>
                  <p className="stars">{renderStars(local.estrelas)}</p>
                  <p>{local.descricao}</p>
                  <p>
                    <strong>Localização:</strong> {local.localizacao}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </section>
      ))}

      <footer>
        <div className="footer-container">
          <div>
            <h3>Sobre Nós</h3>
            <p>
              Grupo de estudantes dedicados ao desenvolvimento de iniciativas
              voltadas à melhoria do trabalho socioeconômico em Matão-SP e
              região.
            </p>
          </div>
          <div>
            <h3>Links Úteis</h3>
                <a href="/home">Página Inicial</a>
                <br />
                <a href="/pesquisar">Pesquisa de Locais</a>
                <br />
                <a href="/locais">Melhores Locais</a>
                <br />
                <a href="/notificacao">Notificações</a>
                <br />
                <a href="/sobre">Sobre Nós</a>
                <br />
                <a href="/perfil">Perfil</a>
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
    </Layout>
  );
};

export default LocaisAvaliados;