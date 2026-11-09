abstract class CurtidasRepository {
  Future<void> curtir(String publicacaoId);

  Future<void> descurtir(String publicacaoId);
}
