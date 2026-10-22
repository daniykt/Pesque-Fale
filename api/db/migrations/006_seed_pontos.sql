-- Migration 006: seed dos pontos de pesca oficiais (Task 9.4, issue #181).
--
-- Cria a conta oficial "Pesque & Fale" e 10 pontos de pesca da região de
-- Matão/SP (5 pesqueiros e 5 em rios), todos com criado_por = conta oficial.
--
-- Idempotente: UUIDs fixos + ON CONFLICT (id) DO NOTHING. Rodar de novo,
-- inclusive direto com psql -f, não duplica nada.
--
-- Divergências com o texto da issue:
--   * ON CONFLICT (nome) não é possível: pontos_de_pesca.nome não tem UNIQUE.
--   * Não existe coluna geom: o ponto fica em latitude/longitude, e o índice
--     GIST da 001 já usa ST_MakePoint(longitude, latitude).
--   * Os tipos "cachoeira" e "pesque-pague" não existem no CHECK de tipo;
--     foram mapeados para 'rio' e 'pesqueiro'.
--
-- A conta oficial não faz login: senha_hash recebe um valor que não é hash
-- bcrypt, então o bcrypt.compare do login devolve false (401, nunca 500).
--
-- Sem BEGIN/COMMIT próprios: o npm run migrate já abre a transação.
--
-- Rollback: ver a descrição do PR. Apagar a conta oficial remove os pontos
-- em cascata (FK pontos_de_pesca.criado_por ON DELETE CASCADE).

INSERT INTO usuarios (id, nome, username, email, senha_hash, bio, onboarding_concluido)
VALUES (
  '69397c7f-3249-451c-98b4-6fb7dda07e3e',
  'Pesque & Fale',
  'pesqueefale',
  'oficial@pesqueefale.app',
  '!conta-oficial-sem-login',
  'Conta oficial do Pesque & Fale. Pontos de pesca verificados da região.',
  true
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO pontos_de_pesca (id, nome, descricao, latitude, longitude, cidade, estado, tipo, criado_por)
VALUES
  ('e9277769-991b-4929-9473-fd2235b5194a', 'Recanto do Pescador', 'Pesqueiro com dois tanques, restaurante e parquinho, na Av. Marchesan.', -21.6336475, -48.3874036, 'Matão', 'SP', 'pesqueiro', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('e229fb84-4f79-41ee-b146-2e2a5e980536', 'Rota do Peixe Pesqueiro e Ecoturismo', 'Pesqueiro com restaurante e ecoturismo na estrada Matão–Rincão.', -21.5697614, -48.2414521, 'Matão', 'SP', 'pesqueiro', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('2594f7b1-7ec1-480d-a3eb-c844cddad82c', 'Pesque Pague e Restaurante Marucci', 'Pesque-pague com restaurante no Jardim Imperador, dentro de Araraquara.', -21.7462451, -48.1606061, 'Araraquara', 'SP', 'pesqueiro', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('8c04c221-f1cb-479a-8db6-65dcf65c030a', 'Pesque Pague & Restaurante Tarumã', 'Pesque-pague com vários tanques e restaurante, na Estrada Vicinal Nelson Barbieri, km 13.', -21.8542679, -48.3293725, 'Araraquara', 'SP', 'pesqueiro', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('d266e196-91d4-42ef-8a16-3b840b085ed2', 'Pesqueiro Terra Nostra', 'Pesqueiro com restaurante e área para crianças, conhecido pela pesca de tilápia.', -21.8695994, -48.1548428, 'Araraquara', 'SP', 'pesqueiro', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('d0164467-3738-497a-8fd4-ffd1c932d3dd', 'Pedra do Rio Mogi-Guaçu', 'Pedra grande na margem do rio Mogi-Guaçu, usada por pescadores.', -21.5959160, -47.9847878, 'Rincão', 'SP', 'rio', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('aa8c8704-0290-474c-855e-f486b5f64009', 'Represa de Ibitinga', 'Represa da usina de Ibitinga no rio Tietê, usada para pesca e esportes náuticos.', -21.8126974, -48.9858082, 'Ibitinga', 'SP', 'represa', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('fcaf3bb0-5313-437e-8691-aff73a0b247e', 'Represa de Bariri', 'Represa da usina de Bariri no rio Tietê, entre Bariri e Boraceia. Verifique a regulamentação local antes de pescar.', -22.1963931, -48.7316925, 'Bariri', 'SP', 'represa', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('fd5afbbd-71e0-4ab0-b489-0878fbcefcc8', 'Cachoeira de Emas', 'Corredeiras do rio Mogi-Guaçu, com restaurantes de peixe na orla. Verifique a regulamentação local antes de pescar.', -21.9259629, -47.3686206, 'Pirassununga', 'SP', 'rio', '69397c7f-3249-451c-98b4-6fb7dda07e3e'),
  ('8623af90-318e-4609-b84d-e87da3f915ab', 'Porto de pesca Ponte do Rio Pardo', 'Porto de pesca na ponte do rio Pardo (SP-373), com aluguel de barcos.', -20.6154516, -48.3356842, 'Jaborandi', 'SP', 'rio', '69397c7f-3249-451c-98b4-6fb7dda07e3e')
ON CONFLICT (id) DO NOTHING;
