import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/chat_socket_service.dart';
import '../domain/conversa.dart';
import '../providers/chat_provider.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/erro_mutual_follow.dart';
import 'widgets/input_mensagem.dart';
import 'widgets/lista_mensagens.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversa});

  final Conversa conversa;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  ChatProvider? _provider;
  bool _tokenAusente = false;
  bool _erroMostrado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializar();
  }

  Future<void> _inicializar() async {
    final token = await TokenStorage().readToken();
    if (!mounted) return;

    if (token == null) {
      setState(() => _tokenAusente = true);
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = ChatProvider(
      socketService: ChatSocketService(token: token),
      usuarioLogadoId: auth.usuario!.id,
      outroId: widget.conversa.outroId,
    );
    provider.iniciar();
    setState(() => _provider = provider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _provider?.status == StatusChat.conectado) {
      _provider!.marcarVistoManual();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tokenAusente) {
      return const _ChatIndisponivel();
    }

    final provider = _provider;
    if (provider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider.value(
      value: provider,
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
                if (provider.status == StatusChat.erroConexao)
                  const _BannerReconectando(),
                Expanded(child: _buildConteudo(provider)),
                InputMensagem(
                  onEnviar: provider.enviarMensagem,
                  onDigitando: provider.notificarDigitando,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConteudo(ChatProvider provider) {
    if (provider.status == StatusChat.conectando) {
      return const Center(child: CircularProgressIndicator());
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

class _ChatIndisponivel extends StatelessWidget {
  const _ChatIndisponivel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível conectar. Faça login novamente.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
