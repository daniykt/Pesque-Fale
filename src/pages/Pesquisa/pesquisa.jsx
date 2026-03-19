import React, { useState } from "react";
import { Link } from 'react-router-dom';
import "./pesquisa.css"; 

const locaisExemplo = [
  {
    id: 1,
    nome: "Represa do Vale Sereno",
    localizacao: "Barra do Garças, MT",
    melhorEpoca: "Maio a Setembro",
    tipo: "Represa",
    descricao:
      "Um dos melhores locais para pesca de tucunaré e pintado. Águas claras e correntes moderadas.",
    peixes: ["tucunaré", "pintado", "dourado"],
    tags: ["Boas estradas e trilhas"],
    avaliacao: 4.7,
    imagem: ".pesqueefale3semestre/assets/pesquisa/represavalesereno.jpg",
  },
  {
    id: 2,
    nome: "Lago das Fendas",
    localizacao: "Manaus, AM",
    melhorEpoca: "Ano todo",
    tipo: "Lago",
    descricao:
      "Lago particular com ótima estrutura para pesca esportiva, especialmente de pacu e piapara.",
    peixes: ["pacu", "piapara", "tilápia"],
    tags: [],
    avaliacao: 4.9,
    imagem:
      ".jpg", 
  },
  {
    id: 3,
    nome: "Represa Jacarupema",
    localizacao: "Capitólio, MG",
    melhorEpoca: "Outubro a Março",
    tipo: "Represa",
    descricao:
      "Grande represa conhecida por suas corvinas e tucunarés de bom porte. Área com vários pontos de pesca.",
    peixes: ["corvina", "tucunaré", "traíra"],
    tags: [],
    avaliacao: 4.5,
    imagem: "url_para_imagem_jacarupema.jpg", 
  },
   {
    id: 4,
    nome: "Rio Araguaia - Trecho Sul",
    localizacao: "Luís Alves, GO",
    melhorEpoca: "Junho a Outubro",
    tipo: "Rio",
    descricao:
      "Trecho famoso pela pesca de grandes peixes como pintado e pirarara, com belas praias naturais.",
    peixes: ["pintado", "pirarara", "pacu"],
    tags: ["Pesca embarcada", "Praias naturais"],
    avaliacao: 4.8,
    imagem: "url_para_imagem_araguaia.jpg",
  },
  {
    id: 5,
    nome: "Pesqueiro Recanto Verde",
    localizacao: "Campinas, SP",
    melhorEpoca: "Ano todo",
    tipo: "Pesqueiro",
    descricao:
      "Pesqueiro com excelente infraestrutura, ideal para pesca esportiva de tambaqui e tilápia.",
    peixes: ["tambaqui", "tilápia", "pacu"],
    tags: ["Infraestrutura completa", "Familiar"],
    avaliacao: 4.6,
    imagem: "url_para_imagem_recanto.jpg",
  },
  {
    id: 6,
    nome: "Lagoa Azul da Serra",
    localizacao: "Domingos Martins, ES",
    melhorEpoca: "Abril a Agosto",
    tipo: "Lagoa",
    descricao:
      "Lago de águas cristalinas em região serrana, ótimo para pesca tranquila e contato com a natureza.",
    peixes: ["tilápia", "carpa", "traíra"],
    tags: ["Águas cristalinas", "Ambiente tranquilo"],
    avaliacao: 4.4,
    imagem: "url_para_imagem_lago_azul.jpg",
  },
  {
  id: 7,
  nome: "Rio Paraná",
  localizacao: "Foz do Iguaçu, PR",
  melhorEpoca: "Agosto a Novembro",
  tipo: "Rio",
  descricao:
    "Local icônico para pesca esportiva, com grande variedade de espécies e ótima estrutura turística na região.",
  peixes: ["dourado", "surubim", "piapara"],
  tags: ["Pesca esportiva", "Região turística"],
  avaliacao: 4.8,
  imagem: "url_para_imagem_rio_parana.jpg",
},
{
  id: 8,
  nome: "Pesqueiro Águas Claras",
  localizacao: "Sorocaba, SP",
  melhorEpoca: "Ano todo",
  tipo: "Pesqueiro",
  descricao:
    "Pesqueiro muito bem avaliado, ideal para iniciantes e famílias, com grande quantidade de peixes e fácil acesso.",
  peixes: ["tilápia", "pacu", "tambaqui"],
  tags: ["Fácil acesso", "Ideal para iniciantes"],
  avaliacao: 4.7,
  imagem: "url_para_imagem_aguas_claras.jpg",
}
];

export default function Pesquisar() {
  // Estados para os filtros
  const [searchTerm, setSearchTerm] = useState("");   
  const [fishType, setFishType] = useState("");
  const [locationType, setLocationType] = useState("");
  const [rating, setRating] = useState("0");
  const [results, setResults] = useState(locaisExemplo); // Inicializa com todos os locais

  // Função de busca com lógica de filtro
  const handleSearch = () => {
    console.log("Buscando com filtros:", {
      searchTerm,
      fishType,
      locationType,
      rating,
    });

    const locaisFiltrados = locaisExemplo.filter((local) => {
      // Filtro por termo de pesquisa (nome ou localização)
      const matchesSearch =
        searchTerm === "" ||
        local.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
        local.localizacao.toLowerCase().includes(searchTerm.toLowerCase());

      // Filtro por tipo de peixe
      const matchesFish =
        fishType === "" || local.peixes.includes(fishType.toLowerCase());

      // Filtro por tipo de local
      const matchesLocation =
        locationType === "" ||
        local.tipo.toLowerCase() === locationType.toLowerCase();

      // Filtro por avaliação mínima
      const matchesRating = local.avaliacao >= parseFloat(rating);

      // Retorna true apenas se passar em TODOS os filtros ativos
      return matchesSearch && matchesFish && matchesLocation && matchesRating;
    });

    setResults(locaisFiltrados);
  };

  return (
    <div className="layout-container">

      <div className="column">
        <div className="">
          <main>
            <section className="search-container">
              <h2>PESQUISAR LOCAIS DE PESCA</h2>

              {/* Barra de Pesquisa */}
              <div className="search-box">
                <input
                  type="text"
                  id="search-input"
                  placeholder="Digite o nome de um local, cidade ou tipo de peixe..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
                <button id="search-button" onClick={handleSearch}>
                  <i className="fas fa-search"></i> Pesquisar
                </button>
              </div>

              {/* Filtros */}
              <div className="filters">
                <div className="filter-group">
                  <label htmlFor="fish-type">Tipo de Peixe</label>
                  <select
                    id="fish-type"
                    value={fishType}
                    onChange={(e) => setFishType(e.target.value)}
                  >
                    <option value="">Todos</option>
                    <option value="tucunaré">Tucunaré</option>
                    <option value="dourado">Dourado</option>
                    <option value="pintado">Pintado</option>
                    <option value="pacu">Pacu</option>
                    <option value="corvina">Corvina</option>
                    <option value="tilápia">Tilápia</option>
                    <option value="carpa">Carpa</option>
                    <option value="traíra">Traíra</option>
                    <option value="surubim">Surubim</option>
                    <option value="pacu">Pacu</option>
                    <option value="tambaqui">Tambaqui</option>
                  </select>
                </div>

                <div className="filter-group">
                  <label htmlFor="location-type">Tipo de Local</label>
                  <select
                    id="location-type"
                    value={locationType}
                    onChange={(e) => setLocationType(e.target.value)}
                  >
                    <option value="">Todos</option>
                    <option value="rio">Rio</option>
                    <option value="lago">Lago</option>
                    <option value="represa">Represa</option>
                    <option value="pesqueiro">Pesqueiro</option>
                    <option value="lagoa">Lagoa</option>
                  </select>
                </div>

                <div className="filter-group">
                  <label htmlFor="rating">Avaliação Mínima</label>
                  <select
                    id="rating"
                    value={rating}
                    onChange={(e) => setRating(e.target.value)}
                  >
                    <option value="0">Qualquer</option>
                    <option value="3">3+ estrelas</option>
                    <option value="4">4+ estrelas</option>
                    <option value="4.5">4.5+ estrelas</option>
                  </select>
                </div>
              </div>

              {/* Container de Resultados */}
              <div className="results-container" id="results-container">
                {results.length > 0 ? (
                  results.map((local) => (
                    <div key={local.id} className="local-card">
                      {/* Imagem do Local */}
                      <img
                        src={local.imagem}
                        alt={local.nome}
                        className="local-image"
                      />

                      <div className="local-card-content">
                        <h3>{local.nome}</h3>
                        <p className="location-info">
                          <i className="fas fa-map-marker-alt"></i>{" "}
                          {local.localizacao}
                        </p>

                        <div className="info-row">
                          <p>
                            <i className="far fa-calendar-alt"></i> Melhor
                            época: {local.melhorEpoca}
                          </p>
                          <p>
                            <i className="fas fa-water"></i> {local.tipo}
                          </p>
                        </div>

                        <p className="local-description">{local.descricao}</p>

                        {/* Tags de Peixes */}
                        <div className="fish-tags">
                          {local.peixes.map((peixe) => (
                            <span key={peixe} className="fish-tag">
                              <i className="fas fa-fish"></i> {peixe}
                            </span>
                          ))}
                        </div>

                        {/* Outras Tags */}
                        {local.tags.length > 0 && (
                          <div className="other-tags">
                            {local.tags.map((tag) => (
                              <span key={tag} className="other-tag">
                                <i className="fas fa-check"></i> {tag}
                              </span>
                            ))}
                          </div>
                        )}

                        {/* Avaliação */}
                        <div className="rating">
                          <i className="fas fa-star text-warning"></i>{" "}
                          {local.avaliacao.toFixed(1)}/5
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div id="no-results" className="no-results">
                    <i
                      className="fas fa-fish"
                      style={{ fontSize: "2em", marginBottom: "15px" }}
                    ></i>
                    <p>
                      Nenhum local de pesca encontrado com os filtros
                      selecionados. Tente ajustar sua pesquisa.
                    </p>
                  </div>
                )}
              </div>
            </section>
          </main>
        </div>

        {/* Rodapé - Mantido conforme original */}
        <footer>
          <div className="footer-container">
            <div className="footer-info">
              <h3>Sobre Nós</h3>
              <p>
                Grupo de estudantes dedicados ao desenvolvimento de iniciativas
                voltadas à melhoria do trabalho socioeconômico em Matão-SP e
                região.
              </p>
            </div>

            <div className="footer-links">
              <h3>Links Úteis</h3>
              <Link to="/">Página Inicial</Link>
              <Link to="/locaisavaliados">Locais Avaliados</Link>
              <Link to="/notificacoes">Notificações</Link>
              <Link to="/sobre">Sobre nós</Link>
              <Link to="/perfil">Perfil</Link>
            </div>

            <div className="footer-contact">
              <h3>Contato</h3>
              <p>
                Email: <strong>pesquefale@gmail.com</strong>
              </p>
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
