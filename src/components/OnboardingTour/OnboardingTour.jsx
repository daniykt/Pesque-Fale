import React, { useEffect, useState, useCallback, useId } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import './OnboardingTour.css';

const DESKTOP_STEPS = [
  {
    id: 'boas-vindas',
    selector: null,
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
    id: 'chat',
    selector: 'a[href="/chat"]',
    titulo: 'Chat 💬',
    descricao:
      'Converse diretamente com outros pescadores! Troque dicas, combine pescarias e faça novas amizades.',
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
  {
    id: 'logout',
    selector: '[data-tour="logout"]',
    titulo: 'Sair da Conta 🚪',
    descricao:
      'Aqui você pode sair da sua conta com segurança. Use quando estiver em um dispositivo compartilhado.',
    posicao: 'direita',
  },
  {
    id: 'tema',
    selector: '[data-tour="theme"]',
    titulo: 'Modo Escuro 🌙',
    descricao:
      'Prefere um visual mais confortável à noite? Ative o modo escuro com um clique!',
    posicao: 'direita',
  },
];

const MOBILE_STEPS = [
  {
    id: 'boas-vindas',
    selector: null,
    titulo: 'Bem-vindo ao Pesque & Fale! 🎣',
    descricao:
      'Que bom ter você aqui! Deixa a gente te mostrar rapidinho as principais seções da plataforma.',
    posicao: 'centro',
  },
  {
    id: 'home',
    selector: '.bottom-nav a[href="/home"]',
    titulo: 'Página Inicial 🏠',
    descricao:
      'Acompanhe as publicações, eventos e dicas do dia. É o coração da plataforma!',
    posicao: 'cima',
  },
  {
    id: 'pesquisa',
    selector: '.bottom-nav a[href="/pesquisar"]',
    titulo: 'Pesquisa 🔍',
    descricao:
      'Encontre os melhores rios, lagos e pesqueiros perto de você.',
    posicao: 'cima',
  },
  {
    id: 'chat',
    selector: '.bottom-nav a[href="/chat"]',
    titulo: 'Chat 💬',
    descricao:
      'Converse com outros pescadores, troque dicas e combine pescarias.',
    posicao: 'cima',
  },
  {
    id: 'notificacoes',
    selector: '.bottom-nav a[href="/notificacao"]',
    titulo: 'Notificações 🔔',
    descricao:
      'Fique por dentro de curtidas e comentários nas suas publicações.',
    posicao: 'cima',
  },
  {
    id: 'perfil',
    selector: '.bottom-nav a[href="/perfil"]',
    titulo: 'Seu Perfil 👤',
    descricao:
      'Personalize sua conta, veja suas publicações e gerencie suas informações.',
    posicao: 'cima',
  },
  {
    id: 'menu-perfil',
    selector: '.pmenu-trigger',
    titulo: 'Menu de Opções ⚙️',
    descricao:
      'Aqui você encontra o "Sobre Nós", pode alternar entre Modo Claro e Escuro, e também sair da sua conta com segurança.',
    posicao: 'baixo',
  },
];

const getRect = (selector) => {
  if (!selector) return null;
  const el = document.querySelector(selector);
  if (!el) return null;
  return el.getBoundingClientRect();
};

const PAD = 8;
const TOOLTIP_W = 340;
const GAP = 16;

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

export default function OnboardingTour({ onFinalizar }) {
  const [isMobile, setIsMobile] = useState(window.innerWidth <= 900);
  const [stepIndex, setStepIndex] = useState(0);
  const [rect, setRect] = useState(null);
  const [tooltipStyle, setTooltipStyle] = useState({});
  const [arrowClass, setArrowClass] = useState('tour-arrow--esquerda');
  const [tooltipMode, setTooltipMode] = useState('lateral');
  const maskId = useId();
  const navigate = useNavigate();
  const location = useLocation();

  const STEPS = isMobile ? MOBILE_STEPS : DESKTOP_STEPS;
  const step = STEPS[stepIndex];
  const isUltimo = stepIndex === STEPS.length - 1;
  const isPrimeiro = stepIndex === 0;
  const isBoasVindas = stepIndex === 0;
  const progresso = ((stepIndex + 1) / STEPS.length) * 100;

  // Redireciona para /perfil quando a etapa do menu for alcançada no mobile
  useEffect(() => {
    if (isMobile && step.id === 'menu-perfil' && location.pathname !== '/perfil') {
      navigate('/perfil');
    }
  }, [isMobile, step.id, navigate, location.pathname]);

  const atualizarRect = useCallback(() => {
    const r = getRect(step.selector);
    setRect(r);
  }, [step.selector]);

  useEffect(() => {
    atualizarRect();
    window.addEventListener('resize', atualizarRect);
    window.addEventListener('scroll', atualizarRect, true);
    return () => {
      window.removeEventListener('resize', atualizarRect);
      window.removeEventListener('scroll', atualizarRect, true);
    };
  }, [atualizarRect]);

  useEffect(() => {
    const originalBody = document.body.style.overflow;
    const originalHtml = document.documentElement.style.overflow;
    document.body.style.overflow = 'hidden';
    document.documentElement.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = originalBody;
      document.documentElement.style.overflow = originalHtml;
    };
  }, []);

  useEffect(() => {
    const isCentro = !rect || step.posicao === 'centro';
    if (isCentro) {
      setTooltipMode('centro');
      setTooltipStyle({});
      setArrowClass('tour-arrow--esquerda');
      return;
    }

    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const TOOLTIP_H_EST = 350;
    const targetCenterY = rect.top + rect.height / 2;
    const targetCenterX = rect.left + rect.width / 2;

    // Posição "baixo" (abaixo do elemento) – usada no menu de 3 pontos
    if (step.posicao === 'baixo') {
      const top = rect.bottom + GAP;
      const left = targetCenterX - TOOLTIP_W / 2;
      const clampedLeft = clamp(left, 16, vw - TOOLTIP_W - 16);
      const clampedTop = clamp(top, 16, vh - TOOLTIP_H_EST - 16);

      setTooltipMode('inferior');
      setTooltipStyle({
        position: 'fixed',
        top: `${clampedTop}px`,
        left: `${clampedLeft}px`,
        width: `${TOOLTIP_W}px`,
        maxHeight: `${vh - 32}px`,
        overflowY: 'auto',
      });
      setArrowClass('tour-arrow--cima');
      return;
    }

    // Posição "cima" (acima do elemento) – usada nos ícones da BottomNav
    if (step.posicao === 'cima') {
      const top = rect.top - TOOLTIP_H_EST - GAP;
      const left = targetCenterX - TOOLTIP_W / 2;
      const clampedLeft = clamp(left, 16, vw - TOOLTIP_W - 16);
      const clampedTop = clamp(top, 16, vh - TOOLTIP_H_EST - 16);

      setTooltipMode('cima');
      setTooltipStyle({
        position: 'fixed',
        top: `${clampedTop}px`,
        left: `${clampedLeft}px`,
        width: `${TOOLTIP_W}px`,
        maxHeight: `${vh - 32}px`,
        overflowY: 'auto',
      });
      setArrowClass('tour-arrow--cima');
      return;
    }

    // Lateral (direita/esquerda)
    const fitsRight = rect.right + GAP + TOOLTIP_W <= vw - 16;
    const fitsLeft = rect.left - GAP - TOOLTIP_W >= 16;

    if (fitsRight || fitsLeft) {
      let idealTop = targetCenterY - TOOLTIP_H_EST / 2;
      const topLimit = 16;
      const bottomLimit = vh - 16;
      if (idealTop < topLimit) idealTop = topLimit;
      if (idealTop + TOOLTIP_H_EST > bottomLimit) {
        idealTop = bottomLimit - TOOLTIP_H_EST;
        if (idealTop < topLimit) idealTop = topLimit;
      }
      const left = fitsRight ? rect.right + GAP : rect.left - TOOLTIP_W - GAP;
      const arrowTopOffset = targetCenterY - idealTop;
      const arrowTopClamped = clamp(arrowTopOffset, 20, TOOLTIP_H_EST - 20);

      setTooltipMode('lateral');
      setTooltipStyle({
        position: 'fixed',
        top: `${idealTop}px`,
        left: `${left}px`,
        width: `${TOOLTIP_W}px`,
        maxHeight: `${vh - 32}px`,
        overflowY: 'auto',
        '--arrow-top': `${arrowTopClamped}px`,
      });
      setArrowClass(fitsRight ? 'tour-arrow--esquerda' : 'tour-arrow--direita');
      return;
    }

    // Inferior (fallback)
    const left = clamp(targetCenterX - TOOLTIP_W / 2, 16, vw - TOOLTIP_W - 16);
    setTooltipMode('inferior');
    setTooltipStyle({
      position: 'fixed',
      top: `${Math.min(rect.bottom + GAP, vh - 16)}px`,
      left: `${left}px`,
      width: `${TOOLTIP_W}px`,
      maxHeight: `${vh - 32}px`,
      overflowY: 'auto',
    });
    setArrowClass('tour-arrow--cima');
  }, [rect, step.posicao]);

  const avancar = () => {
    if (isUltimo) {
      onFinalizar?.();
    } else {
      setStepIndex((i) => i + 1);
    }
  };

  const voltar = () => {
    if (!isPrimeiro) setStepIndex((i) => i - 1);
  };

  const spotX = rect ? rect.left - PAD : 0;
  const spotY = rect ? rect.top - PAD : 0;
  const spotW = rect ? rect.width + PAD * 2 : 0;
  const spotH = rect ? rect.height + PAD * 2 : 0;

  return (
    <>
      <div className="tour-overlay" aria-hidden="true">
        <svg className="tour-svg" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <mask id={maskId}>
              <rect width="100%" height="100%" fill="white" />
              {rect && (
                <rect
                  x={spotX}
                  y={spotY}
                  width={spotW}
                  height={spotH}
                  rx="16"
                  ry="16"
                  fill="black"
                />
              )}
            </mask>
          </defs>

          <rect
            width="100%"
            height="100%"
            fill="rgba(2, 6, 23, 0.62)"
            mask={`url(#${maskId})`}
          />

          {rect && (
            <rect
              x={spotX}
              y={spotY}
              width={spotW}
              height={spotH}
              rx="16"
              ry="16"
              fill="none"
              stroke="#7BAAFF"
              strokeWidth="2"
              className="tour-spotlight-border"
            />
          )}
        </svg>
      </div>

      <div
        className={`tour-tooltip ${
          step.posicao === 'centro' ? 'tour-tooltip--centro' : ''
        } ${tooltipMode === 'inferior' ? 'tour-tooltip--inferior' : ''} ${
          tooltipMode === 'cima' ? 'tour-tooltip--cima' : ''
        }`}
        style={step.posicao !== 'centro' ? tooltipStyle : undefined}
        role="dialog"
        aria-modal="true"
        aria-live="polite"
      >
        {step.posicao !== 'centro' && (
          <div className={`tour-arrow ${arrowClass}`} />
        )}

        <div className="tour-tooltip-top">
          <div className="tour-chip">
            <span className="tour-chip-dot" />
            Tour guiado
          </div>
          <button
            type="button"
            className="tour-btn-pular"
            onClick={onFinalizar}
            aria-label="Pular tour"
          >
            Pular
          </button>
        </div>

        {!isBoasVindas && (
          <div className="tour-progress">
            <div className="tour-progress-track">
              <div className="tour-progress-fill" style={{ width: `${progresso}%` }} />
            </div>
            <div className="tour-progress-meta">
              <span className="tour-contador">
                Passo {stepIndex + 1} de {STEPS.length}
              </span>
              <span className="tour-progress-percent">{Math.round(progresso)}%</span>
            </div>
          </div>
        )}

        <h3 className="tour-titulo">{step.titulo}</h3>
        <p className="tour-descricao">{step.descricao}</p>

        {!isBoasVindas && (
          <div className="tour-steps-dots" aria-hidden="true">
            {STEPS.map((_, i) => (
              <span
                key={i}
                className={`tour-dot ${i === stepIndex ? 'tour-dot--ativo' : ''}`}
              />
            ))}
          </div>
        )}

        <div
          className={`tour-tooltip-footer ${
            isBoasVindas ? 'tour-tooltip-footer--single' : ''
          }`}
        >
          {!isBoasVindas && (
            <button
              type="button"
              className="tour-btn tour-btn--secundario"
              onClick={voltar}
              disabled={isPrimeiro}
            >
              Anterior
            </button>
          )}

          <button
            type="button"
            className="tour-btn tour-btn--primario"
            onClick={avancar}
          >
            {isBoasVindas ? 'Vamos lá' : isUltimo ? 'Começar! 🎣' : 'Próximo'}
          </button>
        </div>
      </div>
    </>
  );
}