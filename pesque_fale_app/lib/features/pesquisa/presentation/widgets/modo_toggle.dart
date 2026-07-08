import 'package:flutter/material.dart';

import '../../providers/pesquisa_locais_provider.dart';

class ModoToggle extends StatelessWidget {
  const ModoToggle({super.key, required this.modo, required this.onChanged});

  final ModoLocais modo;
  final ValueChanged<ModoLocais> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ModoLocais>(
      segments: const [
        ButtonSegment(
          value: ModoLocais.lista,
          label: Text('Lista'),
          icon: Icon(Icons.view_list),
        ),
        ButtonSegment(
          value: ModoLocais.mapa,
          label: Text('Mapa'),
          icon: Icon(Icons.map),
        ),
      ],
      selected: {modo},
      onSelectionChanged: (novo) => onChanged(novo.first),
    );
  }
}
