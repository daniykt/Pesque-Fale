#!/usr/bin/env bash
# Mede o tempo de resposta dos endpoints da Home e do Perfil (Task 10.4.1 / 10.4.7).
#
# Uso (na pasta api/):
#   EMAIL=voce@email.com SENHA=suasenha bash scripts/medir-tempos.sh
#
# Variáveis opcionais:
#   BASE_URL   padrão: https://pesque-fale-api.onrender.com/v1
#   RODADAS    padrão: 5 (use número ímpar para a mediana ser exata)
#   TOKEN      access_token já pronto (pula o login)
#   USER_ID    perfil a medir (padrão: o usuário logado)
#   PUB_ID     publicação para medir curtir/descurtir (opcional; use post de OUTRA conta)
#
# Saída: tabela em Markdown pronta para colar na issue.

set -u

BASE_URL="${BASE_URL:-https://pesque-fale-api.onrender.com/v1}"
RODADAS="${RODADAS:-5}"
TOKEN="${TOKEN:-}"
USER_ID="${USER_ID:-}"
PUB_ID="${PUB_ID:-}"
EMAIL="${EMAIL:-}"
SENHA="${SENHA:-}"

ROOT_URL="${BASE_URL%/v1}"

# ---------- login ----------
if [ -z "$TOKEN" ]; then
  if [ -z "$EMAIL" ] || [ -z "$SENHA" ]; then
    echo "Informe TOKEN ou EMAIL e SENHA." >&2
    exit 1
  fi
  echo "Acordando a API (cold start do Render pode levar ~1 min)..." >&2
  curl -s -o /dev/null --max-time 120 "$ROOT_URL/health"

  RESP=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"senha\":\"$SENHA\"}")
  TOKEN=$(printf '%s' "$RESP" | grep -o '"access_token":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -z "$TOKEN" ]; then
    echo "Login falhou: $RESP" >&2
    exit 1
  fi
  if [ -z "$USER_ID" ]; then
    USER_ID=$(printf '%s' "$RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  fi
else
  curl -s -o /dev/null --max-time 120 "$ROOT_URL/health"
fi

if [ -z "$USER_ID" ]; then
  echo "Informe USER_ID (não foi possível descobrir pelo login)." >&2
  exit 1
fi

AUTH=(-H "Authorization: Bearer $TOKEN")

# ---------- medição ----------
# mede METODO URL -> imprime "status ms" de uma chamada
uma_chamada() {
  local metodo="$1" url="$2"
  curl -s -o /dev/null -X "$metodo" "${AUTH[@]}" \
    -w "%{http_code} %{time_total}" --max-time 60 "$url"
}

mediana() {
  sort -n | awk '{v[NR]=$1} END { if (NR%2) print v[(NR+1)/2]; else printf "%.0f\n", (v[NR/2]+v[NR/2+1])/2 }'
}

# medir NOME METODO URL
medir() {
  local nome="$1" metodo="$2" url="$3"
  uma_chamada "$metodo" "$url" > /dev/null   # aquecimento, descartado
  local tempos="" status="" s t ms
  for _ in $(seq 1 "$RODADAS"); do
    read -r s t < <(uma_chamada "$metodo" "$url")
    status="$s"
    ms=$(awk -v t="$t" 'BEGIN { printf "%.0f", t * 1000 }')
    tempos="$tempos$ms"$'\n'
  done
  local med min max
  med=$(printf '%s' "$tempos" | mediana)
  min=$(printf '%s' "$tempos" | sort -n | head -1)
  max=$(printf '%s' "$tempos" | sort -n | tail -1)
  printf '| %s | `%s` | %s | **%s** | %s | %s |\n' "$nome" "$metodo ${url#$BASE_URL}" "$status" "$med" "$min" "$max"
}

# curtir e descurtir em par, para não deixar curtida sobrando
medir_curtida() {
  local url="$BASE_URL/publicacoes/$PUB_ID/curtir"
  uma_chamada DELETE "$url" > /dev/null   # garante estado inicial sem curtida
  local tc="" td="" s t
  for _ in $(seq 1 "$RODADAS"); do
    read -r s t < <(uma_chamada POST "$url");   tc="$tc$(awk -v t="$t" 'BEGIN{printf "%.0f", t*1000}')"$'\n'; sc="$s"
    read -r s t < <(uma_chamada DELETE "$url"); td="$td$(awk -v t="$t" 'BEGIN{printf "%.0f", t*1000}')"$'\n'; sd="$s"
  done
  printf '| Curtir | `POST /publicacoes/:id/curtir` | %s | **%s** | %s | %s |\n' "$sc" \
    "$(printf '%s' "$tc" | mediana)" "$(printf '%s' "$tc" | sort -n | head -1)" "$(printf '%s' "$tc" | sort -n | tail -1)"
  printf '| Descurtir | `DELETE /publicacoes/:id/curtir` | %s | **%s** | %s | %s |\n' "$sd" \
    "$(printf '%s' "$td" | mediana)" "$(printf '%s' "$td" | sort -n | head -1)" "$(printf '%s' "$td" | sort -n | tail -1)"
}

echo "Medindo ($RODADAS rodadas por endpoint)..." >&2
echo
echo "**Medição** — $(date '+%d/%m/%Y %H:%M') · \`$BASE_URL\` · $RODADAS rodadas · mediana em ms"
echo
echo "| Tela | Endpoint | Status | Mediana | Mín | Máx |"
echo "|---|---|---|---|---|---|"
medir "Feed — Para você" GET "$BASE_URL/publicacoes?pagina=1&porPagina=20"
medir "Feed — Seguindo"  GET "$BASE_URL/publicacoes?pagina=1&porPagina=20&seguindo=true"
medir "Eventos"          GET "$BASE_URL/eventos?futuros=true&porPagina=10"
medir "Locais"           GET "$BASE_URL/pontos?porPagina=50"
medir "Perfil"           GET "$BASE_URL/usuarios/$USER_ID"
medir "Perfil — publicações" GET "$BASE_URL/usuarios/$USER_ID/publicacoes?pagina=1&porPagina=12"
if [ -n "$PUB_ID" ]; then
  medir_curtida
fi
echo
