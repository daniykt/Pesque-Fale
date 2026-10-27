import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/conversa.dart';
import '../providers/chat_provider.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/erro_mutual_follow.dart';
import 'widgets/input_mensagem.dart';
import 'widgets/lista_mensagens.dart';
import 'widgets/skeleton_mensagens.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversa});

  final Conversa conversa;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final ChatProvider _provider;
  bool _erroMostrado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // O socket é o global do RealtimeManager, que já cuida do token e da
    // reconexão; o provider entra no chat assim que houver conexão.
    _provider = ChatProvider(
      realtime: context.read<RealtimeManager>(),
      usuarioLogadoId: context.read<AuthProvider>().usuario!.id,
      outroId: widget.conversa.outroId,
    )..iniciar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _provider.status == StatusChat.conectado) {
      _provider.marcarVistoManual();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.status == StatusChat.semMutualFollow &&
              !_erroMostrado) {
            _erroMostrado = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const ErroMutualFollowDialog(),
              );
            });
          }

          return Scaffold(
            appBar: ChatAppBar(
              conversa: widget.conversa,
              outroDigitando: provider.outroDigitando,
            ),
            body: Column(
              children: [
                // Sincronização (CHAT_FORA_DE_SINCRONIA) usa o mesmo visual de
                // queda de rede. `chatId != null` separa a ressincronização do
                // load inicial, que já tem o skeleton.
                if (provider.status == StatusChat.erroConexao ||
                    (provider.status == StatusChat.conectando &&
                        provider.chatId != null))
                  const _BannerReconectando(),
                Expanded(child: _buildConteudo(provider)),
                InputMensagem(
                  onEnviar: provider.enviarMensagem,
                  onDigitando: provider.notificarDigitando,
                  habilitado: provider.status == StatusChat.conectado,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConteudo(ChatProvider provider) {
    // Só no load inicial: ressincronizando, a lista atual continua na tela.
    if (provider.status == StatusChat.conectando && provider.chatId == null) {
      return const SkeletonMensagens();
    }
    if (provider.mensagens.isEmpty) {
      return _EstadoVazio(nomeOutro: widget.conversa.outroNome);
    }
    return ListaMensagens(
      mensagens: provider.mensagens,
      usuarioLogadoId: provider.usuarioLogadoId,
      outroDigitando: provider.outroDigitando,
    );
  }
}

class _BannerReconectando extends StatelessWidget {
  const _BannerReconectando();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      color: colors.warning,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Sem conexão. Tentando reconectar...'),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.nomeOutro});

  final String nomeOutro;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand_outlined,
            size: 64,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Diga oi para ${nomeOutro.split(' ').first}!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
