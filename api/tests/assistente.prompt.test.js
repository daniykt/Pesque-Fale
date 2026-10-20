const { NOME_ASSISTENTE, montarInstrucoes } = require('../src/modules/assistente/assistente.prompt');

describe('instruções do Pirá', () => {
  it('apresenta o Pirá como assistente do Pesque & Fale', () => {
    const instrucoes = montarInstrucoes();

    expect(NOME_ASSISTENTE).toBe('Pirá');
    expect(instrucoes).toContain('Você é o Pirá');
    expect(instrucoes).toContain('Pesque & Fale');
  });

  it('informa a tela em que o usuário está', () => {
    expect(montarInstrucoes('inicio')).toContain('O usuário está agora na tela: inicio.');
    expect(montarInstrucoes()).not.toContain('O usuário está agora na tela');
  });

  it('explica o que o Pirá sabe fazer, incluindo a voz', () => {
    const instrucoes = montarInstrucoes();

    expect(instrucoes).toContain('o que você sabe fazer');
    expect(instrucoes).toContain('microfone');
    expect(instrucoes).toContain('Ouvir');
  });

  it('orienta a oferecer a pesquisa de locais quando a busca não encontra nada', () => {
    const instrucoes = montarInstrucoes();

    expect(instrucoes).toContain('Se buscar_locais não encontrar nada');
    expect(instrucoes).toContain('sugerir_tela com pesquisa_locais');
    expect(instrucoes).toContain('Nunca invente locais');
  });
});