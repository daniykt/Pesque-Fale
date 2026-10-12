enum StatusMarco { feito, atual, futuro }

class MarcoCronograma {
  const MarcoCronograma({
    required this.data,
    required this.titulo,
    required this.descricao,
    required this.status,
  });

  final String data;
  final String titulo;
  final String descricao;
  final StatusMarco status;
}

const List<MarcoCronograma> marcosCronograma = [
  MarcoCronograma(
    data: '1º sem · 2025',
    titulo: 'Primeiros passos em dev web',
    descricao:
        'Site estático em HTML, CSS e JavaScript. Primeira entrega acadêmica do curso.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: '2º sem · 2025',
    titulo: 'Padrão MVC e banco com C#',
    descricao:
        'Aplicação em C# seguindo arquitetura MVC, com persistência em banco de dados.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: '3º sem · 2025',
    titulo: 'Nasce o Pesque & Fale',
    descricao:
        'MVP web em React + Firebase rodando em pesqueefaledb.web.app. Feed, perfil, publicações e autenticação.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: '4º sem · início 2026',
    titulo: 'Migração pra mobile (Flutter)',
    descricao:
        'Reescrita como app nativo. Novo backend em Node.js + PostgreSQL + Cloudinary. Elementos maiores, páginas no lugar de modais.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: 'Fases 1–3',
    titulo: 'Alicerce do app',
    descricao:
        'Autenticação, perfil, onboarding guiado e refatoração visual com design tokens (AppColors, AppSpacing).',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: 'Fase 4',
    titulo: 'Feed, chat e mapas',
    descricao:
        'Feed completo, chat em tempo real com Socket.IO, integração de mapas com OpenStreetMap e tour guiado.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: 'Fase 5',
    titulo: 'Rodada de testes',
    descricao:
        'Sessões manuais exploratórias com o time. 14 bugs catalogados pra priorização.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: 'Fase 6 · set 2026',
    titulo: 'Correções pós-teste',
    descricao:
        'Fotos, badges de notificação, follow mútuo e envio de mensagens corrigidos.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: 'Fase 7 · out 2026',
    titulo: 'Estabilização pré-v1.0',
    descricao:
        'Acessibilidade, reorganização do menu, contadores clicáveis e remoção do Drawer global.',
    status: StatusMarco.feito,
  ),
  MarcoCronograma(
    data: 'Fase 8 · out 2026',
    titulo: 'Refinamento pré-release',
    descricao:
        'Reorganização dos CTAs do perfil, nova tela Sobre Nós, animação de login e ajustes finais.',
    status: StatusMarco.atual,
  ),
  MarcoCronograma(
    data: '17 out · 2026',
    titulo: 'v1.0.0',
    descricao: 'Release pública da primeira versão estável.',
    status: StatusMarco.futuro,
  ),
];

class MembroTime {
  const MembroTime({
    required this.nome,
    required this.funcao,
    required this.fotoAsset,
  });

  final String nome;
  final String funcao;
  final String fotoAsset;
}

const List<MembroTime> membrosTime = [
  MembroTime(
    nome: 'Danilo',
    funcao: 'Front-end',
    fotoAsset: 'assets/image/sobrenos/fotodanilo.jpg',
  ),
  MembroTime(
    nome: 'Henrique',
    funcao: 'Back-end',
    fotoAsset: 'assets/image/sobrenos/fotohenrique.jpg',
  ),
  MembroTime(
    nome: 'Felipe',
    funcao: 'Front-end · QA',
    fotoAsset: 'assets/image/sobrenos/fotofelipe.jpg',
  ),
  MembroTime(
    nome: 'João Pedro',
    funcao: 'Front-end',
    fotoAsset: 'assets/image/sobrenos/fotojoao.jpg',
  ),
  MembroTime(
    nome: 'Lucas',
    funcao: 'Design',
    fotoAsset: 'assets/image/sobrenos/fotolucas.jpg',
  ),
  MembroTime(
    nome: 'Vinícius',
    funcao: 'Design',
    fotoAsset: 'assets/image/sobrenos/fotovinicius.jpg',
  ),
  MembroTime(
    nome: 'Rebeca',
    funcao: 'Documentação',
    fotoAsset: 'assets/image/sobrenos/fotorebeca.jpg',
  ),
];

const List<String> stackItens = [
  'Flutter',
  'Node.js',
  'PostgreSQL',
  'Socket.IO',
  'Cloudinary',
  'OpenStreetMap',
  'FATEC Matão',
];
