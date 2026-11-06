#!/usr/bin/env bash
# Publica o site no VPS: atualiza o código, gera a imagem Docker e troca o container
# sem perder a configuração do container atual. Se o site novo não subir, volta à versão anterior.
#
# Uso: deploy.sh <pasta_no_servidor> <nome_do_container> <porta_host_se_primeira_vez> <url_do_repo> <branch>
set -euo pipefail

APP_DIR="${1:-/opt/rf-consultoria-bancaria}"
CONTAINER="${2:-}"
FIRST_PORT="${3:-}"
REPO_URL="${4:-https://github.com/grupoexpresso2-hue/rf-consultoria-bancaria.git}"
BRANCH="${5:-main}"
IMAGE="rf-consultoria-site"

log() { echo "[deploy] $*"; }
fail() { echo "[deploy] ERRO: $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || fail "git não está instalado no servidor."
command -v docker >/dev/null 2>&1 || fail "Docker não está instalado no servidor."
DOCKER="docker"
if ! docker info >/dev/null 2>&1; then
  if sudo -n docker info >/dev/null 2>&1; then DOCKER="sudo -n docker"; else fail "o usuário não tem permissão para usar o Docker (adicione-o ao grupo docker)."; fi
fi

show_containers() {
  log "Containers em execução no servidor:"
  $DOCKER ps --format '  {{.Names}}  |  imagem: {{.Image}}  |  portas: {{.Ports}}' || true
}

[ -n "$CONTAINER" ] || { show_containers; fail "defina a variável CONTAINER_NAME no GitHub com o nome do container do site (veja a lista acima)."; }

# 1) Código
if [ -d "$APP_DIR/.git" ]; then
  log "Atualizando código em $APP_DIR"
  git -C "$APP_DIR" fetch --depth 1 origin "$BRANCH"
  git -C "$APP_DIR" reset --hard "origin/$BRANCH"
else
  log "Clonando repositório em $APP_DIR"
  mkdir -p "$(dirname "$APP_DIR")"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi
REV="$(git -C "$APP_DIR" rev-parse --short HEAD)"

# 2) Imagem (se falhar aqui, o site atual continua intacto)
log "Gerando imagem $IMAGE:$REV"
$DOCKER build --pull -t "$IMAGE:$REV" -t "$IMAGE:latest" "$APP_DIR"

# 3) Configuração a herdar do container atual
RUN_ARGS=(-d --name "$CONTAINER-novo")
NETWORKS=()
OLD_EXISTS=false
if $DOCKER inspect "$CONTAINER" >/dev/null 2>&1; then
  OLD_EXISTS=true
  log "Copiando portas, rede, rótulos e política de reinício de '$CONTAINER'"
  while read -r p; do [ -n "$p" ] && RUN_ARGS+=(-p "$p"); done < <(
    $DOCKER inspect -f '{{range $port, $binds := .HostConfig.PortBindings}}{{range $binds}}{{if .HostIp}}{{.HostIp}}:{{end}}{{.HostPort}}:{{$port}}{{"\n"}}{{end}}{{end}}' "$CONTAINER")
  while read -r n; do [ -n "$n" ] && NETWORKS+=("$n"); done < <(
    $DOCKER inspect -f '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}}{{"\n"}}{{end}}' "$CONTAINER")
  LABELS_FILE="$(mktemp)"
  $DOCKER inspect -f '{{range $k, $v := .Config.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' "$CONTAINER" \
    | grep -v '^com\.docker\.compose\.' | grep -v '^maintainer=' | grep -v '^$' > "$LABELS_FILE" || true
  RUN_ARGS+=(--label-file "$LABELS_FILE")
  RESTART="$($DOCKER inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$CONTAINER")"
  [ -n "$RESTART" ] && [ "$RESTART" != "no" ] && RUN_ARGS+=(--restart "$RESTART") || RUN_ARGS+=(--restart unless-stopped)
else
  [ -n "$FIRST_PORT" ] || { show_containers; fail "o container '$CONTAINER' não existe. Para criar do zero, defina HOST_PORT no GitHub (ex.: 8080)."; }
  log "Container '$CONTAINER' não existe: criando novo na porta $FIRST_PORT"
  RUN_ARGS+=(-p "$FIRST_PORT:80" --restart unless-stopped)
fi
[ ${#NETWORKS[@]} -gt 0 ] && RUN_ARGS+=(--network "${NETWORKS[0]}")

rollback() {
  log "Falha ao subir a versão nova. Restaurando a anterior."
  $DOCKER rm -f "$CONTAINER-novo" >/dev/null 2>&1 || true
  if $OLD_EXISTS; then $DOCKER start "$CONTAINER" >/dev/null || true; fi
  fail "publicação cancelada; o site anterior continua no ar."
}

# 4) Troca: para o antigo, sobe o novo com a mesma configuração e confere a saúde
$DOCKER rm -f "$CONTAINER-novo" >/dev/null 2>&1 || true
if $OLD_EXISTS; then log "Parando versão atual"; $DOCKER stop "$CONTAINER" >/dev/null; fi
$DOCKER run "${RUN_ARGS[@]}" "$IMAGE:$REV" >/dev/null || rollback
if [ ${#NETWORKS[@]} -gt 1 ]; then
  for n in "${NETWORKS[@]:1}"; do $DOCKER network connect "$n" "$CONTAINER-novo" || rollback; done
fi

ok=false
for _ in $(seq 1 15); do
  if $DOCKER exec "$CONTAINER-novo" wget -q -O /dev/null http://127.0.0.1/healthz 2>/dev/null; then ok=true; break; fi
  sleep 2
done
$ok || rollback

# 5) Conclui
if $OLD_EXISTS; then $DOCKER rm "$CONTAINER" >/dev/null; fi
$DOCKER rename "$CONTAINER-novo" "$CONTAINER"
[ -n "${LABELS_FILE:-}" ] && rm -f "$LABELS_FILE"
$DOCKER image prune -f >/dev/null 2>&1 || true
log "Site no ar com a versão $REV (container '$CONTAINER')."
