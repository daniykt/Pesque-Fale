import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import "./index.css";

import imgFamilia from "../../assets/image/index/tio.gif"
import imgLogo1 from "../../assets/image/login/logo1.png"
import imgLogo2 from "../../assets/image/login/logo2.png"
import imgFotoDanilo from "../../assets/image/sobrenos/fotodanilo.jpg"
import imgFotoVinicius from "../../assets/image/sobrenos/fotovinicius.jpg"
import imgFotoHenrique from "../../assets/image/sobrenos/fotohenrique.jpg"
import imgFotoLucas from "../../assets/image/sobrenos/fotolucas.jpg"
import imgFotoJoao from "../../assets/image/sobrenos/fotojoao.jpg"
import imgFotoRebeca from "../../assets/image/sobrenos/fotorebeca.jpg"

const teamMembers = [
  {
    nome: "Danilo Silva",
    role: "Desenvolvedor Full-Stack em Formação",
    bio: "Estou cursando Desenvolvimento de Software Multiplataforma na FATEC. Sou Full-Stack em formação (Dart, JavaScript, React e C#). Combino design centrado no usuário com habilidade para organizar, planejar e coordenar projetos em equipe.",
    foto: imgFotoDanilo,
    linkedin: "#",
    github: "#"
  },
  {
    nome: "Henrique Tavares",
    role: "Desenvolvedor Front-End | Co-Fundador",
    bio: "Tenho 19 anos e sou desenvolvedor front-end, iniciando no back-end. No Pesque & Fale organizo os papéis da equipe e oriento meus parceiros, valorizando o trabalho em equipe e o impacto positivo da iniciativa.",
    foto: imgFotoHenrique,
    linkedin: "#",
    github: "#"
  },
  {
    nome: "Vinicius Bovo",
    role: "Desenvolvedor Front-End | Co-Fundador",
    bio: "Tenho 18 anos, sou desenvolvedor front-end e cofundador do Pesque & Fale. Criei a plataforma para incentivar a pesca em Matão-SP, organizando informações e promovendo inovação na área socioeconômica do lazer local.",
    foto: imgFotoVinicius,
    linkedin: "#",
    github: "#"
  },
  {
    nome: "Lucas Catto",
    role: "Desenvolvedor Front-End | Co-Fundador",
    bio: "Tenho 18 anos e sou desenvolvedor front-end. Sou cofundador do Pesque & Fale, um projeto que inova no mundo da pesca em Matão. Busco unir criatividade e tecnologia para gerar impacto positivo na comunidade.",
    foto: imgFotoLucas,
    linkedin: "#",
    github: "#"
  },
  {
    nome: "João Pedro",
    role: "Desenvolvedor Front-End | Co-Fundador",
    bio: "Tenho 18 anos e atuo como desenvolvedor front-end, sempre buscando criar experiências digitais funcionais e atrativas. Sou um dos idealizadores do projeto Pesque & Fale, trazendo inovação ao universo da pesca em Matão.",
    foto: imgFotoJoao,
    linkedin: "#",
    github: "#"
  },
  {
    nome: "Rebeca Scutare",
    role: "Estudante de Desenvolvimento de Software",
    bio: "Tenho 18 anos e estudo na Fatec Matão. Sou aluna do curso de Desenvolvimento de Software Multiplataforma e atualmente estou no segundo semestre.",
    foto: imgFotoRebeca,
    linkedin: "#",
    github: "#"
  },
];

const faqItems = [
  {
    pergunta: "O que é o Pesque & Fale?",
    resposta: "O Pesque & Fale é uma plataforma que conecta pescadores, permitindo compartilhar experiências, descobrir novos locais de pesca e avaliar rios e lagos da região."
  },
  {
    pergunta: "A plataforma é gratuita?",
    resposta: "Sim! O cadastro e o uso de todas as funcionalidades da plataforma são completamente gratuitos."
  },
  {
    pergunta: "Como posso cadastrar um local de pesca?",
    resposta: "Após fazer login na plataforma, basta acessar a seção de locais e clicar em 'Cadastrar Local'. Preencha as informações como nome, endereço e características do local."
  },
  {
    pergunta: "Posso avaliar locais sem me cadastrar?",
    resposta: "Não. Para deixar avaliações e comentários, é necessário estar logado na plataforma. O cadastro é rápido e gratuito."
  },
  {
    pergunta: "O Pesque & Fale atende apenas a região de Matão-SP?",
    resposta: "Atualmente o foco principal é Matão-SP, mas a plataforma está em constante expansão e logo atenderá outras regiões."
  },
  {
    pergunta: "Como funciona o sistema de avaliações?",
    resposta: "Após visitar um local cadastrado, você pode atribuir uma nota de 1 a 5 estrelas e deixar um comentário detalhado sobre sua experiência, ajudando outros pescadores."
  }
];

const Index = () => {
  const [faqAberto, setFaqAberto] = useState(null);
  const [menuOpen, setMenuOpen] = useState(false);

  const toggleFaq = (index) => {
    setFaqAberto(faqAberto === index ? null : index);
  };

  const toggleMenu = (e) => {
    e.stopPropagation();
    setMenuOpen(!menuOpen);
  };

  const closeMenu = () => {
    setMenuOpen(false);
  };

  // Fechar menu ao clicar fora
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuOpen && !e.target.closest('#navbar')) {
        setMenuOpen(false);
      }
    };
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, [menuOpen]);

  // Fechar menu ao redimensionar
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 768) {
        setMenuOpen(false);
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

    const handleScrollTo = (e, targetId) => {
    e.preventDefault();
    const el = document.getElementById(targetId);
    if (el) {
      const offset = document.getElementById('navbar').offsetHeight;
      window.scrollTo({
        top: el.offsetTop - offset,
        behavior: 'smooth'
      });
    }
    closeMenu();
  };

  return (
    <>
      {/* NAVBAR */}
      <nav id="navbar">
        <div className="nav-container">
          <div className="logo-index">
            <img src={imgLogo1} alt="Logo 1" />
            <img src={imgLogo2} alt="Logo 2" />
          </div>
          
          <ul id="navLinks" className={menuOpen ? 'active' : ''}>
            <li><a href="#home" onClick={(e) => handleScrollTo(e, 'home')}>Início</a></li>
            <li><a href="#features" onClick={(e) => handleScrollTo(e, 'features')}>Recursos</a></li>
            <li><a href="#about" onClick={(e) => handleScrollTo(e, 'about')}>Sobre</a></li>
            <li><a href="#team" onClick={(e) => handleScrollTo(e, 'team')}>Equipe</a></li>
            <li><a href="#faq" onClick={(e) => handleScrollTo(e, 'faq')}>Dúvidas</a></li>
          </ul>
          
          <button id="menuToggle" className={menuOpen ? 'active' : ''} onClick={toggleMenu}>
            <span></span>
            <span></span>
            <span></span>
          </button>
        </div>
      </nav>

      {/* HERO */}
      <section className="hero" id="home">
        <div className="hero-content">
          <div className="hero-text">
            <h1>Conecte-se com <span>Pescadores</span> Descubra os Melhores <span>Locais</span></h1>
            <p>A plataforma perfeita para compartilhar experiências, fazer amizades e encontrar os melhores rios e lagos para sua pescaria.</p>
            <div className="cta-buttons">
              <Link to="/login" className="btn btn-primary">Começar Agora</Link>
              <a href="#features" className="btn btn-secondary">Saiba Mais</a>
            </div>
          </div>
          <div className="hero-visual">
            <img src={imgFamilia} alt="Familia pescando" className="hero-image" />
          </div>
        </div>
      </section>

      {/* FEATURES */}
      <section className="features" id="features">
        <div className="container-i">
          <div className="section-header">
            <h2>Nossos Recursos</h2>
            <p>Tudo que você precisa para ter a melhor experiência de pesca</p>
          </div>
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">🎣</div>
              <h3>Conecte-se</h3>
              <p>Conheça novos pescadores, compartilhe experiências e construa uma comunidade apaixonada pela pesca.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">📍</div>
              <h3>Descubra Locais</h3>
              <p>Encontre os melhores rios e lagos com avaliações e recomendações de pescadores experientes.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">⭐</div>
              <h3>Avaliações</h3>
              <p>Leia e compartilhe avaliações detalhadas sobre locais de pesca, ajudando toda a comunidade.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ABOUT */}
      <section className="about" id="about">
        <div className="container-i">
          <div className="about-content">
            <div className="about-text">
              <h2>Sobre o <span>PESQUE & FALE</span></h2>
              <p>Nossa plataforma nasceu da necessidade de conectar pescadores e facilitar a descoberta de locais agradáveis e acessíveis para a pesca.</p>
              <p>Funcionamos como uma rede social especializada, onde pescadores podem trocar informações, experiências e feedback sobre os melhores ambientes para pescar.</p>
              <p>Promovemos a pesca sustentável, impulsionando a economia local e proporcionando momentos de lazer e trabalho em harmonia com a natureza.</p>
            </div>
            <div className="stats">
              <div className="stat">
                <div className="stat-number">500+</div>
                <div className="stat-label">Locais Cadastrados</div>
              </div>
              <div className="stat">
                <div className="stat-number">1000+</div>
                <div className="stat-label">Pescadores Ativos</div>
              </div>
              <div className="stat">
                <div className="stat-number">5000+</div>
                <div className="stat-label">Avaliações</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* TEAM */}
      <section className="section-team" id="team">
        <div className="team-container">
          <div className="team-title-area">
            <h2>NOSSA EQUIPE</h2>
          </div>
          <div className="team-grid-layout">
            {teamMembers.map((membro, index) => (
              <div key={index} className="member-card">
                <img src={membro.foto} alt={membro.nome} className="member-photo" />
                <h3 className="member-name">{membro.nome}</h3>
                <span className="member-role">{membro.role}</span>
                <p className="member-bio">{membro.bio}</p>
                <div className="member-social-links">
                  <a href={membro.linkedin} target="_blank" rel="noopener noreferrer">
                    <i className="fab fa-linkedin"></i>
                  </a>
                  <a href={membro.github} target="_blank" rel="noopener noreferrer">
                    <i className="fab fa-github"></i>
                  </a>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="cta-section" id="contact">
        <div className="container-i">
          <h2>Pronto para começar sua jornada?</h2>
          <p>Junte-se à comunidade PESQUE & FALE hoje mesmo</p>
          <Link to="/login" className="btn btn-outline-primary">Cadastre-se Gratuitamente</Link>
        </div>
      </section>

      {/* FAQ */}
      <section className="section-faq" id="faq">
        <div className="container-i">
          <div className="faq-title-area">
            <h2>Perguntas Frequentes</h2>
            <p>Tire suas dúvidas sobre o Pesque & Fale</p>
          </div>
          <div className="faq-list">
            {faqItems.map((item, index) => (
              <div key={index} className={`faq-item ${faqAberto === index ? "faq-item-open" : ""}`}>
                <button className="faq-question" onClick={() => toggleFaq(index)}>
                  <span>{item.pergunta}</span>
                  <i className={`fas fa-chevron-down faq-icon ${faqAberto === index ? "faq-icon-rotated" : ""}`}></i>
                </button>
                <div className="faq-answer">
                  <p>{item.resposta}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CONTATO */}
      <section className="section-contato" id="contato">
        <div className="container-i">
          <div className="contato-content">
            <div className="contato-texto">
              <h2>Entre em Contato</h2>
              <p>Tem alguma dúvida, sugestão ou gostaria de parcerias? Fale conosco pelo e-mail abaixo.</p>
            </div>
            <a href="mailto:pesquefale@gmail.com" className="contato-email">
              <i className="fas fa-envelope"></i>
              <span>pesquefale@gmail.com</span>
            </a>
          </div>
        </div>
      </section>
    </>
  );
};

export default Index;