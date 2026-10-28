import 'package:flutter/foundation.dart';

/// Distinção visual da equipe ao lado do nome do usuário.
///
/// Os ids ficam hardcoded no front na v1.0.0 (UUID é identificador opaco,
/// não PII). Na v1.1 isso migra para um campo `role` no banco.
enum TipoBadge { dev, oficial }

const _idsDevs = <String>{'UUID_DANILO', 'UUID_DEV_2', 'UUID_DEV_3'};

const _idsOficial = <String>{'UUID_OFICIAL'};

/// Oficial tem prioridade sobre dev caso um id esteja nas duas listas.
TipoBadge? resolverBadge(String? userId) {
  if (userId == null || userId.isEmpty) return null;
  if (_idsOficial.contains(userId)) return TipoBadge.oficial;
  if (_idsDevs.contains(userId)) return TipoBadge.dev;
  return null;
}

@visibleForTesting
Set<String> get idsDevs => _idsDevs;

@visibleForTesting
Set<String> get idsOficial => _idsOficial;

// Contas com badge (manter em sincronia com os Sets acima):
//
// Devs:
//   UUID_DANILO  = 'UUID_DANILO'
//   UUID_DEV_2   = 'UUID_DEV_2'
//   UUID_DEV_3   = 'UUID_DEV_3'
//
// Oficial (@pesquefale):
//   UUID_OFICIAL = 'UUID_OFICIAL'
