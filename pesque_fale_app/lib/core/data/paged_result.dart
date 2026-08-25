class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.pagina,
    required this.porPagina,
  });

  final List<T> items;
  final int total;
  final int pagina;
  final int porPagina;

  bool get temMais => pagina * porPagina < total;
}
