const pool = require('../../config/database');

const TIPOS_DE_LOCAL = ['pesqueiro', 'rio', 'lago', 'represa', 'mar'];
const MAXIMO_LOCAIS = 5;
const MAXIMO_ACOES = 3;

const TELAS = {
  nova_publicacao: 'Abrir tela de publicar',
  pesquisa_locais: 'Abrir pesquisa de locais',
  editar_perfil: 'Abrir editar perfil',
  configuracoes: 'Abrir configurações',
  chat: 'Abrir o chat',
  sobre: 'Abrir sobre o app',
};

const DECLARACOES = [
  {
    name: 'buscar_locais',
    description:
      'Busca locais de pesca cadastrados no Pesque & Fale pelo nome, tipo ou cidade. Use quando o usuário perguntar sobre um local específico ou quiser encontrar locais.',
    parameters: {
      type: 'object',
      properties: {
        busca: { type: 'string', description: 'Parte do nome do local, por exemplo "Lago Azul".' },
        tipo: { type: 'string', enum: TIPOS_DE_LOCAL, description: 'Tipo do local.' },
        cidade: { type: 'string', description: 'Nome da cidade.' },
      },
    },
  },
  {
    name: 'sugerir_tela',
    description:
      'Mostra ao usuário um botão para abrir uma tela do app. Use quando ele quiser fazer algo que tem uma tela própria, como publicar, pesquisar locais ou editar o perfil.',
    parameters: {
      type: 'object',
      properties: {
        tela: { type: 'string', enum: Object.keys(TELAS), description: 'Tela a ser aberta.' },
      },
      required: ['tela'],
    },
  },
];

async function buscarLocais({ busca, tipo, cidade } = {}) {
  const condicoes = [];
  const valores = [];

  if (typeof busca === 'string' && busca.trim()) {
    valores.push(`%${busca.trim()}%`);
    condicoes.push(`LOWER(nome) LIKE LOWER($${valores.length})`);
  }
  if (TIPOS_DE_LOCAL.includes(tipo)) {
    valores.push(tipo);
    condicoes.push(`tipo = $${valores.length}`);
  }
  if (typeof cidade === 'string' && cidade.trim()) {
    valores.push(cidade.trim());
    condicoes.push(`LOWER(cidade) = LOWER($${valores.length})`);
  }

  const where = condicoes.length > 0 ? `WHERE ${condicoes.join(' AND ')}` : '';
  valores.push(MAXIMO_LOCAIS);

  const { rows } = await pool.query(
    `SELECT id, nome, tipo, cidade, estado, avg_nota
     FROM pontos_de_pesca
     ${where}
     ORDER BY avg_nota DESC NULLS LAST, nome ASC
     LIMIT $${valores.length}`,
    valores
  );

  return rows.map((ponto) => ({
    id: ponto.id,
    nome: ponto.nome,
    tipo: ponto.tipo,
    cidade: ponto.cidade,
    estado: ponto.estado,
    nota: Number(ponto.avg_nota) || 0,
  }));
}

function criarFerramentas() {
  const acoes = [];

  function adicionarAcao(acao) {
    const repetida = acoes.some((existente) => JSON.stringify(existente) === JSON.stringify(acao));
    if (!repetida && acoes.length < MAXIMO_ACOES) acoes.push(acao);
  }

  async function executar(nome, argumentos = {}) {
    try {
      if (nome === 'buscar_locais') {
        const locais = await buscarLocais(argumentos);
        locais.slice(0, MAXIMO_ACOES).forEach((local) =>
          adicionarAcao({ tipo: 'abrir_local', pontoId: local.id, rotulo: `Ver ${local.nome}` })
        );
        return { locais, total: locais.length };
      }

      if (nome === 'sugerir_tela') {
        const rotulo = TELAS[argumentos.tela];
        if (!rotulo) return { erro: 'Tela desconhecida.' };
        adicionarAcao({ tipo: 'abrir_tela', tela: argumentos.tela, rotulo });
        return { ok: true, botao: rotulo };
      }

      return { erro: 'Ferramenta desconhecida.' };
    } catch (err) {
      console.error('Erro na ferramenta do assistente:', nome, err.message);
      return { erro: 'Não foi possível consultar agora.' };
    }
  }

  return { declaracoes: DECLARACOES, executar, acoes };
}

module.exports = { TELAS, criarFerramentas };