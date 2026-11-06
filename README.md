# RF Consultoria Bancária — Site institucional

Site da **RF Consultoria Bancária** (uma empresa **RF GROUP®**): revisão técnica de juros e contratos bancários.

Linguagem de filme: abertura em plano-sequência orbital sobre um globo 3D (WebGL) com a imagem real da Terra à noite da NASA, câmera guiada pela rolagem que desce até Balneário Camboriú, enquadramentos fotográficos 2.39:1 com movimento de câmera, timecode, granulação de película e tipografia editorial. Sem ícones e sem efeitos genéricos. Preparado para telas 2K e 4K.

## Estrutura

```
index.html              # página completa (HTML + CSS + JS)
Dockerfile              # imagem nginx:alpine que publica o site
deploy/deploy.sh        # troca segura do container no VPS (com retorno automático)
.github/workflows/      # publicação automática a cada envio para a main
nginx.conf              # gzip, cache, cabeçalhos de segurança (CSP) e /healthz
robots.txt, sitemap.xml # SEO
img/
  logo-rf.png           # logo RF / RF GROUP®
  terra-noite-nasa.jpg  # Terra à noite (NASA Earth Observatory, domínio público)
  dr-reinaldo.webp      # foto do responsável técnico
  dor-endividamento.jpg # foto da seção "Diagnóstico"
```

Não há etapa de build: o site é um único `index.html` com Tailwind CSS e Lucide carregados por CDN (versões fixas).

## Ver localmente

Abra o `index.html` no navegador com dois cliques, ou rode um servidor local:

```bash
python -m http.server 5510
```

e acesse `http://localhost:5510`.

## Publicar com Docker

O `Dockerfile` copia `index.html`, `robots.txt`, `sitemap.xml` e a pasta `img/` para um nginx:

```bash
docker build -t rf-site .
docker run -p 8080:80 rf-site
```

## Publicação automática no VPS (GitHub Actions)

A cada envio para a `main`, o fluxo `.github/workflows/deploy.yml` entra no VPS por SSH e roda `deploy/deploy.sh`, que:

1. atualiza o código no servidor (padrão: `/opt/rf-consultoria-bancaria`);
2. gera a imagem Docker nova (se falhar, nada muda no ar);
3. copia do container atual as portas, redes, rótulos (ex.: Traefik) e a política de reinício;
4. troca o container e confere `/healthz`; se o site novo não responder, **religa a versão anterior** e marca o fluxo como falho.

Enquanto os segredos não forem cadastrados, o fluxo só mostra um aviso e não faz nada.

### Configurar (uma única vez)

1. **Criar uma chave SSH só para publicação** (no seu computador):
   ```bash
   ssh-keygen -t ed25519 -f rf-deploy -N "" -C "github-deploy-rf"
   ```
2. **Autorizar a chave no VPS**: copie o conteúdo de `rf-deploy.pub` para `~/.ssh/authorized_keys` do usuário que roda o Docker no servidor (ele precisa estar no grupo `docker`).
3. **Descobrir o nome do container atual do site** (no VPS): `docker ps`.
4. **Cadastrar no GitHub** em *Settings → Secrets and variables → Actions*:

   | Tipo | Nome | Valor |
   |---|---|---|
   | Secret | `VPS_HOST` | IP ou host do VPS |
   | Secret | `VPS_USER` | usuário SSH |
   | Secret | `VPS_SSH_KEY` | conteúdo do arquivo `rf-deploy` (chave privada) |
   | Secret (opcional) | `VPS_PORT` | porta SSH, se não for 22 |
   | Secret (opcional) | `VPS_KNOWN_HOSTS` | linha do `known_hosts` do servidor (mais seguro que a leitura automática) |
   | Variable | `CONTAINER_NAME` | nome do container do site (passo 3) |
   | Variable (opcional) | `DEPLOY_PATH` | pasta do código no servidor |
   | Variable (opcional) | `HOST_PORT` | porta, só se ainda não existir container |
   | Variable (opcional) | `SITE_URL` | endereço conferido ao final |

5. **Rodar a primeira vez**: aba *Actions → Publicar no VPS → Run workflow*. Depois disso, cada envio para a `main` publica sozinho.

Apague o arquivo `rf-deploy` do computador depois de cadastrá-lo no GitHub.

## Publicar no GitHub Pages

1. No repositório, vá em **Settings → Pages**.
2. Em **Source**, escolha **Deploy from a branch**, branch `main` e pasta `/ (root)`.
3. Salve. Em cerca de 1 minuto o site fica disponível em `https://SEU-USUARIO.github.io/NOME-DO-REPOSITORIO/`.

Para usar o domínio próprio (`rfconsultoriabancaria.com.br`), informe-o em **Settings → Pages → Custom domain** e aponte o DNS conforme a documentação do GitHub Pages.

## Onde editar

| O que | Onde |
|---|---|
| Número do WhatsApp | `CONFIG.whatsapp` no `<script>` do `index.html` |
| Perguntas do FAQ | constante `FAQ` |
| Perfis "Para quem é" | constante `PERFIS` |
| Regra do simulador (40% a 70%) | função `initSimulator` |
| Cores e fontes | `tailwind.config` e variáveis `:root` no topo do `index.html` |

## Observações

- O globo 3D precisa do site servido por um servidor (GitHub Pages ou `python -m http.server`). Aberto direto do disco, o navegador bloqueia a textura e o site usa um globo alternativo em CSS.
- Os links de **Política de Privacidade** e **Termos de Uso** apontam para o site atual.
- Percentuais e valores do site e do simulador são ilustrativos e não representam garantia de resultado.

© RF Consultoria Bancária · RF GROUP® é marca registrada.
