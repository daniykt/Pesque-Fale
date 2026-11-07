const dicasDePesca = [
  'Chegue ao local com calma e evite barulho na margem. Peixe assustado '
      'demora a voltar.',
  'Confira a linha antes de sair de casa. Trechos ásperos ou com nós '
      'costumam arrebentar na hora da briga.',
  'Anzol afiado faz diferença. Passe a ponta de leve na unha: se escorregar, '
      'está na hora de afiar ou trocar.',
  'Respeite o período de defeso (piracema) da sua região. Ele protege a '
      'reprodução dos peixes.',
  'Antes de pescar, confira as regras locais de tamanho mínimo e de '
      'quantidade de peixes que podem ser levados.',
  'Na pesca esportiva, molhe as mãos antes de pegar o peixe. Isso protege a '
      'camada que cobre a pele dele.',
  'Para soltar o peixe, segure-o dentro da água até ele nadar sozinho. Não '
      'jogue de volta de longe.',
  'Use alicate de bico para tirar o anzol com menos ferimento para o peixe '
      'e para você.',
  'Leve de volta todo o lixo, inclusive pedaços de linha. Eles prendem aves '
      'e outros animais.',
  'Protetor solar, chapéu e água também são equipamento de pesca. Reaplique '
      'o protetor ao longo do dia.',
  'No barco, use colete salva-vidas, mesmo que você saiba nadar.',
  'Avise alguém sobre onde vai pescar e a que horas pretende voltar.',
  'Observe a água: movimento na superfície e pássaros mergulhando costumam '
      'indicar peixe por perto.',
  'Os peixes pararam de beliscar? Experimente outra profundidade antes de '
      'trocar de lugar.',
  'Ajuste a fricção do molinete antes de arremessar: firme para fisgar, '
      'solta o bastante para a linha não arrebentar.',
  'Guarde as iscas artificiais separadas por tipo. Fica mais fácil achar a '
      'certa e os anzóis não se embolam.',
  'Isca natural precisa estar fresca. Mantenha na sombra e em lugar fresco.',
  'Depois de pescar, lave a vara e o molinete com água limpa para tirar '
      'barro e areia, que gastam as peças.',
  'Seque bem o equipamento antes de guardar para evitar ferrugem e mofo.',
  'Depois de fisgar, mantenha a vara erguida e a linha esticada. Linha '
      'frouxa ajuda o peixe a escapar.',
  'Em dia de vento, arremesse a favor dele para ganhar distância com menos '
      'esforço.',
  'Nada acontece há um bom tempo? Troque de isca: cor, tamanho e movimento '
      'fazem diferença.',
  'Começou a trovejar? Saia da água e guarde a vara. Vara de pesca pode '
      'conduzir eletricidade.',
  'Calçado com sola antiderrapante evita quedas em pedras e barrancos '
      'molhados.',
  'Cuide da margem e da vegetação. Barranco firme é bom para você e para o '
      'rio.',
  'Em pesqueiro ou área particular, conheça as regras do lugar antes de '
      'começar.',
  'Anote o que deu certo: local, isca e horário. Com o tempo, você descobre '
      'os seus próprios padrões.',
  'Pescar acompanhado é mais seguro e mais divertido. Chame um amigo ou '
      'alguém da família para a próxima pescaria.',
  'Leve um kit de primeiros socorros com curativos e antisséptico.',
  'Paciência faz parte da pescaria. Aproveite o tempo ao ar livre, mesmo nos '
      'dias de pouco peixe.',
];

String dicaDoDia(DateTime data) {
  final hoje = DateTime.utc(data.year, data.month, data.day);
  final diaDoAno = hoje.difference(DateTime.utc(data.year)).inDays;
  return dicasDePesca[diaDoAno % dicasDePesca.length];
}
