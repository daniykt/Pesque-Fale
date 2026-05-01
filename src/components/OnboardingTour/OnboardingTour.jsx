import React, { useEffect, useState, useCallback } from 'react';
import './OnboardingTour.css';

// Cada passo aponta para um seletor CSS já existente na sidebar/home
const STEPS = [
  {
    id: 'boas-vindas',
    selector: null, // passo inicial sem elemento destacado
    titulo: 'Bem-vindo ao Pesque & Fale! 🎣',
    descricao:
      'Que bom ter você aqui! Deixa a gente te mostrar rapidinho as principais seções da plataforma.',
    posicao: 'centro',
  },
  {
    id: 'home',
    selector: 'a[href="/home"]',
    titulo: 'Página Inicial 🏠',
    descricao:
      'Aqui você acompanha as publicações da comunidade, eventos de pesca e dicas do dia. É o coração da plataforma!',
    posicao: 'direita',
  },
  {
    id: 'pesquisa',
    selector: 'a[href="/pesquisar"]',
    titulo: 'Pesquisa 🔍',
    descricao:
      'Encontre os melhores rios, lagos e pesqueiros perto de você. Veja avaliações de outros pescadores.',
    posicao: 'direita',
  },
  {
    id: 'notificacoes',
    selector: 'a[href="/notificacao"]',
    titulo: 'Notificações 🔔',
    descricao:
      'Fique por dentro das novidades! Veja quando alguém curtir ou comentar nas suas publicações.',
    posicao: 'direita',
  },
  {
    id: 'chat',
    selector: 'a[href="/chat"]',
    titulo: 'Chat 💬',
    descricao:
      'Converse diretamente com outros pescadores! Troque dicas, combine pescarias e faça novas amizades.',
    posicao: 'direita',
  },
  {
    id: 'sobre',
    selector: 'a[href="/sobre"]',
    titulo: 'Sobre Nós 🎓',
    descricao:
      'Conheça a equipe por trás do Pesque & Fale e saiba mais sobre o projeto desenvolvido na FATEC.',
    posicao: 'direita',
  },
  {
    id: 'perfil',
    selector: 'a[href="/perfil"]',
    titulo: 'Seu Perfil 👤',
    descricao:
      'Aqui você personaliza sua conta, vê suas publicações e gerencia suas informações de pescador.',
    posicao: 'direita',
  },
];

// Retorna o bounding rect de um seletor ou null
const getRect = (selector) => {
  if (!selector) return null;
  const el = document.querySelector(selector);
  if (!el) return null;
  return el.getBoundingClientRect();
};

// Padding ao redor do elemento destacado
const PAD = 8;

export default function OnboardingTour({ onFinalizar }) {
  const [stepIndex, setStepIndex] = useState(0);
  const [rect, setRect] = useState(null);
  const [tooltipStyle, setTooltipStyle] = useState({});

  const step = STEPS[stepIndex];
  const isUltimo = stepIndex === STEPS.length - 1;
  const isPrimeiro = stepIndex === 0;

  // Atualiza o rect do elemento destacado
  const atualizarRect = useCallback(() => {
    const r = getRect(step.selector);
    setRect(r);
  }, [step.selector]);

  useEffect(() => {
    atualizarRect();
    window.addEventListener('resize', atualizarRect);
    return () => window.removeEventListener('resize', atualizarRect);
  }, [atualizarRect]);

  // Posiciona o tooltip relativo ao elemento destacado
  useEffect(() => {
    if (!rect || step.posicao === 'centro') {
      setTooltipStyle({});
      return;
    }

    const TOOLTIP_W = 300;
    const GAP = 16;

    // Posiciona à direita do elemento (sidebar fica à esquerda)
    const top = rect.top + rect.height / 2;
    const left = rect.right + GAP;

    setTooltipStyle({
      position: 'fixed',
      top: `${top}px`,
      left: `${left}px`,
      transform: 'translateY(-50%)',
      width: `${TOOLTIP_W}px`,
    });
  }, [rect, step.posicao]);

  const avancar = () => {
    if (isUltimo) {
      onFinalizar();
    } else {
      setStepIndex((i) => i + 1);
    }
  };

  const voltar = () => {
    if (!isPrimeiro) setStepIndex((i) => i - 1);
  };

  // Coordenadas do spotlight
  const spotX = rect ? rect.left - PAD : 0;
  const spotY = rect ? rect.top - PAD : 0;
  const spotW = rect ? rect.width + PAD * 2 : 0;
  const spotH = rect ? rect.height + PAD * 2 : 0;

  return (
    <>
      {/* Overlay com buraco recortado no elemento destacado */}
      <div className="tour-overlay" onClick={(e) => e.stopPropagation()}>
        {rect && (
          <svg className="tour-svg" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <mask id="tour-mask">
                {/* Fundo branco = área escurecida */}
                <rect width="100%" height="100%" fill="white" />
                {/* Buraco arredondado = área iluminada */}
                <rect
                  x={spotX}
                  y={spotY}
                  width={spotW}
                  height={spotH}
                  rx="12"
                  ry="12"
                  fill="black"
                />
              </mask>
            </defs>
            <rect
              width="100%"
              height="100%"
              fill="rgba(0,0,0,0.6)"
              mask="url(#tour-mask)"
            />
            {/* Borda pulsante ao redor do elemento */}
            <rect
              x={spotX}
              y={spotY}
              width={spotW}
              height={spotH}
              rx="12"
              ry="12"
              fill="none"
              stroke="#7BAAFF"
              strokeWidth="2"
              className="tour-spotlight-border"
            />
          </svg>
        )}
      </div>

      {/* Tooltip */}
      <div
        className={`tour-tooltip ${step.posicao === 'centro' ? 'tour-tooltip--centro' : ''}`}
        style={step.posicao !== 'centro' ? tooltipStyle : undefined}
      >
        {/* Setinha lateral quando não é centro */}
        {step.posicao === 'direita' && <div className="tour-arrow tour-arrow--esquerda" />}

        <div className="tour-tooltip-header">
          <div className="tour-steps-dots">
            {STEPS.map((_, i) => (
              <span
                key={i}
                className={`tour-dot ${i === stepIndex ? 'tour-dot--ativo' : ''}`}
              />
            ))}
          </div>
          <button
            className="tour-btn-pular"
            onClick={onFinalizar}
            aria-label="Pular tour"
          >
            Pular
          </button>
        </div>

        <h3 className="tour-titulo">{step.titulo}</h3>
        <p className="tour-descricao">{step.descricao}</p>

        <div className="tour-tooltip-footer">
          <span className="tour-contador">
            {stepIndex + 1} de {STEPS.length}
          </span>
          <div className="tour-btns">
            {!isPrimeiro && (
              <button className="tour-btn tour-btn--secundario" onClick={voltar}>
                Anterior
              </button>
            )}
            <button className="tour-btn tour-btn--primario" onClick={avancar}>
              {isUltimo ? 'Começar! 🎣' : 'Próximo'}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}