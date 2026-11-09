import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/tag_publicacao.dart';

class CampoTags extends StatefulWidget {
  const CampoTags({
    super.key,
    required this.selecionadas,
    required this.limite,
    required this.onAdicionar,
    required this.onRemover,
  });

  final Set<String> selecionadas;
  final int limite;
  final void Function(String) onAdicionar;
  final void Function(String) onRemover;

  @override
  State<CampoTags> createState() => _CampoTagsState();
}

class _CampoTagsState extends State<CampoTags> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adicionarCustom() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    widget.onAdicionar(texto);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final atingiuLimite = widget.selecionadas.length >= widget.limite;
    final customizadas = widget.selecionadas
        .where((t) => !TagPublicacao.values.any((tag) => tag.label == t))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(até ${widget.limite})',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in TagPublicacao.values)
              FilterChip(
                label: Text(tag.label),
                selected: widget.selecionadas.contains(tag.label),
                onSelected:
                    (atingiuLimite && !widget.selecionadas.contains(tag.label))
                    ? null
                    : (selecionado) => selecionado
                          ? widget.onAdicionar(tag.label)
                          : widget.onRemover(tag.label),
              ),
          ],
        ),
        if (customizadas.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in customizadas)
                Chip(label: Text(tag), onDeleted: () => widget.onRemover(tag)),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !atingiuLimite,
                decoration: InputDecoration(
                  hintText: atingiuLimite
                      ? 'Limite de ${widget.limite} tags atingido'
                      : 'Adicionar tag personalizada...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.pillRadius,
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                onSubmitted: (_) => _adicionarCustom(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Material(
              color: atingiuLimite ? colors.textSecondary : colors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: atingiuLimite ? null : _adicionarCustom,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
