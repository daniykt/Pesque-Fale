# AGENTS.md — App Flutter

Complementa o `AGENTS.md` da raiz. Flutter 3.44.4 (mesma versão do CI).

## Rodar

```bash
flutter pub get
flutter run                                                    # usa a API de produção
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3333/v1  # API local (emulador Android)
flutter run --dart-define=USE_MOCK=true                        # repositórios mock, sem rede
```

Atenção: por padrão o app aponta para a **API de produção** (`AppConfig.apiBaseUrl`). Não crie dados de teste lá.

## Arquitetura

Por feature, em `lib/features/<feature>/`:

- `data/`: `<x>_api_client.dart` (HTTP), `<x>_repository.dart` (contrato abstrato), `<x>_repository_http.dart` e `<x>_repository_mock.dart`, `<x>_exceptions.dart`
- `domain/`: models e enums
- `presentation/`: páginas e `widgets/`
- `providers/`: `ChangeNotifier` com o estado da tela

Compartilhado: `lib/core/` (config, theme, realtime, router, utils) e `lib/shared/` (widgets e utils reutilizáveis).

- A escolha mock/http é feita no `main.dart` via `AppConfig.useMock`. Repositório novo segue esse padrão e entra no `MultiProvider` do `main.dart`.
- Widgets não chamam a API direto: widget → provider → repository.
- Realtime: use só o `RealtimeManager` (`lib/core/realtime/`). Leia o contrato no topo do arquivo: callbacks de `subscribe` não podem capturar dados do usuário logado, e providers com vida curta desfazem as assinaturas no `dispose`.

## UI

- Cores só via `Theme.of(context).extension<AppColors>()!`. Nada de `Color(0x...)` nem `Colors.xxx` fora de `lib/core/theme/`.
- Espaçamento só com `AppSpacing` (`xxs` 4 … `xxl` 48) e raio só com `AppRadius` (`sm`, `md`, `lg`, `pill` e os getters `*Radius`).
- Tipografia pelo `Theme.of(context).textTheme` (definido em `AppTypography`).
- Feedback ao usuário só com `AppSnackbar` (`showError`, `showSuccess`, `showWarning`, `showInfo`). Nada de `SnackBar` solto nem diálogos de alerta para mensagens simples.
- Toda tela nova precisa funcionar no **tema claro e no escuro**. `primary` é cor de fundo; para texto ou ícone sobre `background`/`surface`, use `primaryAccent`.
- Imagem do Cloudinary passa pelos helpers de `lib/core/utils/cloudinary_url.dart`. Nunca monte a URL na mão, e sempre tenha `errorBuilder` ou fallback para URL nula ou quebrada.
- Listas com itens que mudam: use `ValueKey(item.id)`.

## Código

- Sem `print`/`debugPrint` em `lib/`.
- Textos visíveis em pt-BR.
- Não remova os comentários `TODO` deixados pelo time do back. Eles marcam migrações futuras.

## Testes

- Ficam em `test/`, espelhando `lib/` (`test/features/<feature>/...`).
- Use fakes que implementam o repository abstrato. Para realtime, existe `test/features/chat/support/fake_realtime_manager.dart`.
- Bug corrigido ganha um teste que falharia sem a correção. Liste os cenários antes de escrever: o teste precisa validar o comportamento esperado, não só aumentar a cobertura.
