import React from 'react';
import './sobre.css';
import Layout from '../../components/sidebar/layout';

import fotoDanilo from '../../assets/image/sobrenos/fotodanilo.jpg';
import fotoHenrique from '../../assets/image/sobrenos/fotohenrique.jpg';
import fotoVinicius from '../../assets/image/sobrenos/fotovinicius.jpg';
import fotoLucas from '../../assets/image/sobrenos/fotolucas.jpg';
import fotoJoao from '../../assets/image/sobrenos/fotojoao.jpg';
import fotoRebeca from '../../assets/image/sobrenos/fotorebeca.jpg';

const SobreNos = () => {
  const membros = [
    {
      id: 1,
      nome: 'Danilo Silva',
      iniciais: 'DS',
      badge: 'Teste · Front-end - Líder',
      profissao: 'Desenvolvedor Full-Stack em Formação',
      descricao:
        'Estou cursando Desenvolvimento de Software Multiplataforma na FATEC. Sou Full-Stack em formação (Dart, JavaScript, React e C#). Combino design centrado no usuário com habilidade para organizar, planejar e coordenar projetos em equipe.',
      foto: fotoDanilo,
      linkedin: '#',
      github: '#',
    },
    {
      id: 2,
      nome: 'Henrique Tavares',
      iniciais: 'HT',
      badge: 'Back-end · Líder',
      profissao:
        'Desenvolvedor Full-Stack em Formação com foco em back-end | Líder de Equipe',
      descricao:
        'Sou desenvolvedor Full-Stack em formação, com foco em back-end. No Pesque & Fale organizo os papéis da equipe e oriento meus parceiros, valorizando o trabalho em equipe e o impacto positivo da iniciativa. Sou responsável por implementar diferentes funcionalidades no site como login/cadastro e edição de perfil, além de organizar o banco de dados e garantir a segurança dos dados dos usuários.',
      foto: fotoHenrique,
      linkedin: '#',
      github: '#',
    },
    {
      id: 3,
      nome: 'Vinícius Bovo',
      iniciais: 'VB',
      badge: 'Front-end · Co-fundador',
      profissao:
        'Desenvolvedor Full-Stack em Formação com foco em front-end | Co-Fundador',
      descricao:
        'Sou desenvolvedor Full-Stack em formação, com foco em front-end e cofundador do Pesque & Fale. Criei a plataforma para incentivar a pesca em Matão-SP, organizando informações e promovendo inovação na área socioeconômica do lazer local.',
      foto: fotoVinicius,
      linkedin: '#',
      github: '#',
    },
    {
      id: 4,
      nome: 'Lucas Catto',
      iniciais: 'LC',
      badge: 'Back-end · Co-fundador',
      profissao:
        'Desenvolvedor Full-Stack em Formação com foco em back-end | Co-Fundador',
      descricao:
        'Sou desenvolvedor Full-Stack em formação, com foco em back-end. Sou cofundador do Pesque & Fale, um projeto que inova no mundo da pesca em Matão. Busco unir criatividade e tecnologia para gerar impacto positivo na comunidade.',
      foto: fotoLucas,
      linkedin: '#',
      github: '#',
    },
    {
      id: 5,
      nome: 'João Pedro Ferreira',
      iniciais: 'JP',
      badge: 'Front-end · Co-fundador',
      profissao:
        'Desenvolvedor Full-Stack em Formação com foco em front-end | Co-Fundador',
      descricao:
        'Atuo como desenvolvedor Full-Stack em formação com foco em front-end. Sou um dos idealizadores do projeto Pesque & Fale, trazendo inovação ao universo da pesca em Matão.',
      foto: fotoJoao,
      linkedin: '#',
      github: '#',
    },
    {
      id: 6,
      nome: 'Rebeca Scutare',
      iniciais: 'RS',
      badge: 'Docs · Co-fundadora',
      profissao: 'Gestora de Projetos em Formação | Co-Fundadora',
      descricao:
        'Atuo como gestora do projeto Pesque & Fale. Sou responsável por planejar e documentar o projeto. Meu objetivo é contribuir para o sucesso do projeto e garantir sua implementação eficiente.',
      foto: fotoRebeca,
      linkedin: '#',
      github: '#',
    },
  ];

  return (
    <Layout>
      <div className="sobre-corpo">
        {/* Hero com ondas */}
        <section className="snos-hero">
          <div className="snos-hero__bg">
            <svg
              className="snos-hero__wave"
              viewBox="0 0 1440 200"
              preserveAspectRatio="none"
            >
              <path
                fill="rgba(255,255,255,0.06)"
                d="M0,64L48,80C96,96,192,128,288,133.3C384,139,480,117,576,96C672,75,768,53,864,58.7C960,64,1056,96,1152,106.7C1248,117,1344,107,1392,101.3L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"
              />
            </svg>
            <svg
              className="snos-hero__wave snos-hero__wave--bottom"
              viewBox="0 0 1440 200"
              preserveAspectRatio="none"
            >
              <path
                fill="rgba(255,255,255,0.04)"
                d="M0,128L48,122.7C96,117,192,107,288,112C384,117,480,139,576,138.7C672,139,768,117,864,112C960,107,1056,117,1152,122.7C1248,128,1344,128,1392,128L1440,128L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"
              />
            </svg>
          </div>
          <div className="snos-hero__content">
            <span className="snos-hero__tag">
              <i className="fas fa-fish" /> Pesque &amp; Fale · FATEC
            </span>
            <h1 className="snos-hero__title">
              Nossa <span>Equipe</span>
            </h1>
            <p className="snos-hero__sub">
              Desenvolvido por estudantes de Desenvolvimento de Software
              Multiplataforma, o Pesque &amp; Fale conecta pescadores de todo o
              Brasil.
            </p>
            <div className="snos-hero__bubbles">
              <span className="bubble" />
              <span className="bubble" />
              <span className="bubble" />
              <span className="bubble" />
            </div>
          </div>
        </section>

        {/* Divisor */}
        <div className="snos-divider">
          <div className="snos-divider__line" />
          <span className="snos-divider__text">
            <i className="fas fa-users" /> Os membros
          </span>
          <div className="snos-divider__line" />
        </div>

        {/* Grid de cards */}
        <div className="snos-grid">
          {membros.map((membro) => (
            <article key={membro.id} className="snos-card">
              <div className="snos-card__inner">
                <div className="snos-card__avatar-wrap">
                  <img
                    src={membro.foto}
                    alt={`Foto de ${membro.nome}`}
                    className="snos-card__avatar"
                    onError={(e) => {
                      e.currentTarget.style.display = 'none';
                      e.currentTarget.nextSibling.style.display = 'flex';
                    }}
                  />
                  <div
                    className="snos-card__avatar-fallback"
                    style={{ display: 'none' }}
                  >
                    {membro.iniciais}
                  </div>
                </div>

                <div className="snos-card__body">
                  <h2 className="snos-card__name">{membro.nome}</h2>
                  <span className="snos-card__badge">{membro.badge}</span>
                  <p className="snos-card__role">{membro.profissao}</p>
                  <p className="snos-card__desc">{membro.descricao}</p>
                </div>

                <div className="snos-card__socials">
                  <a
                    href={membro.linkedin}
                    target="_blank"
                    rel="noreferrer"
                    className="snos-card__social-link"
                    aria-label={`LinkedIn de ${membro.nome}`}
                  >
                    <i className="fab fa-linkedin-in" />
                  </a>
                  <a
                    href={membro.github}
                    target="_blank"
                    rel="noreferrer"
                    className="snos-card__social-link"
                    aria-label={`GitHub de ${membro.nome}`}
                  >
                    <i className="fab fa-github" />
                  </a>
                </div>
              </div>
            </article>
          ))}
        </div>

        {/* Rodapé */}
        <div className="snos-footer">
          <div className="snos-footer__left">
            <div className="snos-footer__icon">
              <i className="fas fa-water" />
            </div>
            <div>
              <h3 className="snos-footer__title">Pesque &amp; Fale</h3>
              <p className="snos-footer__text">
                FATEC · Desenvolvimento de Software Multiplataforma · 3º Semestre
              </p>
            </div>
          </div>
          <div className="snos-footer__tags">
            <span className="snos-footer__tag">Vida na Água</span>
            <span className="snos-footer__tag">Trabalho Decente</span>
            <span className="snos-footer__tag">Crescimento Econômico</span>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default SobreNos;