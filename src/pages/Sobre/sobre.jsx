import React from 'react';
import { Link } from 'react-router-dom';
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
      profissao: 'Desenvolvedor Full-Stack em Formação',
      descricao: 'Estou cursando Desenvolvimento de Software Multiplataforma na FATEC. Sou Full-Stack em formação (Dart, JavaScript, React e C#). Combino design centrado no usuário com habilidade para organizar, planejar e coordenar projetos em equipe.',
      foto: fotoDanilo, // 2. Chame a variável importada aqui, sem aspas
    },
    {
      id: 2,
      nome: 'Henrique Tavares',
      profissao: 'Desenvolvedor Front-End | Co-Fundador',
      descricao: 'Tenho 19 anos e sou desenvolvedor front-end, iniciando no back-end. No Pesque & Fale organizo os papéis da equipe e oriento meus parceiros, valorizando o trabalho em equipe e o impacto positivo da iniciativa.',
      foto: fotoHenrique,      
    },
    {
      id: 3,
      nome: 'Vinícius Bovo',
      profissao: 'Desenvolvedor Front-End | Co-Fundador',
      descricao: 'Tenho 18 anos, sou desenvolvedor front-end e cofundador do Pesque & Fale. Criei a plataforma para incentivar a pesca em Matão-SP, organizando informações e promovendo inovação na área socioeconômica do lazer local.',
      foto: fotoVinicius,      
    },
    {
      id: 4,
      nome: 'Lucas Catto',
      profissao: 'Desenvolvedor Front-End | Co-Fundador',
      descricao: 'Tenho 18 anos e sou desenvolvedor front-end. Sou cofundador do Pesque & Fale, um projeto que inova no mundo da pesca em Matão. Busco unir criatividade e tecnologia para gerar impacto positivo na comunidade.',
      foto: fotoLucas,     
    },
    {
      id: 5,
      nome: 'João Pedro Ferreira',
      profissao: 'Desenvolvedor Front-End | Co-Fundador',
      descricao: 'Tenho 18 anos e atuo como desenvolvedor front-end, sempre buscando criar experiências digitais funcionais e atrativas. Sou um dos idealizadores do projeto Pesque & Fale, trazendo inovação ao universo da pesca em Matão.',
      foto: fotoJoao,
    },
    {
      id: 6,
      nome: 'Rebeca Scutare',
      profissao: 'Estudante de Desenvolvimento de Software',
      descricao: 'Tenho 18 anos e estudo na Fatec Matão. Sou aluna do curso de Desenvolvimento de Software Multiplataforma e atualmente estou no segundo semestre.',
      foto: fotoRebeca,
    }
  ];

  return (
    <Layout>
      <div className="sobre-corpo">
        <section className="sobre-nos">
          <h1>Nossa Equipe</h1>
          <div className="container">
            {membros.map(membro => (
              <div key={membro.id} className="card">
                <img src={membro.foto} alt={`Foto de ${membro.nome}`} />
                <h2>{membro.nome}</h2>
                <p className="profissao">{membro.profissao}</p>
                <p className="descricao">{membro.descricao}</p>
                <div className="social">
                  <i className="fab fa-linkedin"></i>
                  <i className="fab fa-github"></i>
                </div>
              </div>
            ))}
          </div>
        </section>

        <footer>
          <div className="footer-container">
            <div>
              <h3>Sobre Nós</h3>
              <p>Grupo de estudantes dedicados ao desenvolvimento de iniciativas voltadas à melhoria do trabalho socioeconômico em Matão-SP e região.</p>
            </div>
            <div>
              <h3>Links Úteis</h3>
              <Link to="/">Página Inicial</Link>
              <Link to="/pesquisar">Pesquisa de Locais</Link>
              <Link to="/locaisavaliados">Melhores locais</Link>
              <Link to="/notificacoes">Notificações</Link>
              <Link to="/perfil">Perfil</Link>
            </div>
            <div>
              <h3>Contato</h3>
              <p>Email: pesquefale@gmail.com</p>
            </div>
          </div>
          <p className="copyright">&copy; Pesque & Fale 2025 - Todos os direitos reservados.</p>
        </footer>
      </div>
    </Layout>
  );
};

export default SobreNos;