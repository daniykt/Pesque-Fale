-- Migration 007: foto de capa e tags dos pontos oficiais (Task 9.13, issue #232).
--
-- Preenche foto_capa e tags dos 10 pontos criados na 006. Sete pontos têm
-- foto; Tarumã, Represa de Ibitinga e Represa de Bariri recebem só tags (o
-- app mostra o ícone padrão quando foto_capa é NULL).
--
-- As fotos são PROVISÓRIAS (recortes do Google Maps, decisão do time para a
-- demo da COPEX) e serão substituídas por fotos autorizadas numa 008. As URLs
-- são as mesmas que já estão em produção (conferidas no Supabase em 28/10).
--
-- Só UPDATE, sempre filtrando pelo UUID do ponto E pela conta oficial.
-- Idempotente: rodar de novo grava os mesmos valores.
-- Sem BEGIN/COMMIT próprios: o npm run migrate já abre a transação.
-- Não mexe em nome, descricao, coordenadas, tipo nem cidade (o Pirá depende).

-- Recanto do Pescador
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225190/01-recanto-do-pescador_2.jpg',
    tags = ARRAY['tanques', 'restaurante', 'familia'],
    atualizado_em = NOW()
WHERE id = 'e9277769-991b-4929-9473-fd2235b5194a'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Rota do Peixe Pesqueiro e Ecoturismo
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225509/02-rota-do-peixe_2.jpg',
    tags = ARRAY['restaurante', 'ecoturismo', 'familia'],
    atualizado_em = NOW()
WHERE id = 'e229fb84-4f79-41ee-b146-2e2a5e980536'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Pesque Pague e Restaurante Marucci
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225190/03-marucci_2.jpg',
    tags = ARRAY['pesque-pague', 'restaurante'],
    atualizado_em = NOW()
WHERE id = '2594f7b1-7ec1-480d-a3eb-c844cddad82c'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Pesque Pague & Restaurante Tarumã (sem foto)
UPDATE pontos_de_pesca
SET tags = ARRAY['pesque-pague', 'restaurante', 'playground'],
    atualizado_em = NOW()
WHERE id = '8c04c221-f1cb-479a-8db6-65dcf65c030a'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Pesqueiro Terra Nostra
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225191/06-terra-nostra_2.jpg',
    tags = ARRAY['tilapia', 'restaurante', 'familia'],
    atualizado_em = NOW()
WHERE id = 'd266e196-91d4-42ef-8a16-3b840b085ed2'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Pedra do Rio Mogi-Guaçu
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225190/04-pedra-do-rio-mogi-guacu_2.jpg',
    tags = ARRAY['rio-mogi-guacu', 'natureza'],
    atualizado_em = NOW()
WHERE id = 'd0164467-3738-497a-8fd4-ffd1c932d3dd'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Represa de Ibitinga (sem foto)
UPDATE pontos_de_pesca
SET tags = ARRAY['rio-tiete', 'barco', 'esportes-nauticos'],
    atualizado_em = NOW()
WHERE id = 'aa8c8704-0290-474c-855e-f486b5f64009'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Represa de Bariri (sem foto)
UPDATE pontos_de_pesca
SET tags = ARRAY['rio-tiete', 'barco'],
    atualizado_em = NOW()
WHERE id = 'fcaf3bb0-5313-437e-8691-aff73a0b247e'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Cachoeira de Emas
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225191/07-cachoeira-de-emas_2.jpg',
    tags = ARRAY['rio-mogi-guacu', 'corredeiras', 'restaurantes'],
    atualizado_em = NOW()
WHERE id = 'fd5afbbd-71e0-4ab0-b489-0878fbcefcc8'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';

-- Porto de pesca Ponte do Rio Pardo
UPDATE pontos_de_pesca
SET foto_capa = 'https://res.cloudinary.com/luvfmoi2/image/upload/v1793225191/08-ponte-do-rio-pardo_2.jpg',
    tags = ARRAY['rio-pardo', 'aluguel-de-barco'],
    atualizado_em = NOW()
WHERE id = '8623af90-318e-4609-b84d-e87da3f915ab'
  AND criado_por = '69397c7f-3249-451c-98b4-6fb7dda07e3e';
