# RF Consultoria Bancária — Site institucional

Site da **RF Consultoria Bancária** (uma empresa **RF GROUP®**): revisão técnica de juros e contratos bancários.

Linguagem de filme: abertura em plano-sequência orbital sobre um globo 3D (WebGL) com a imagem real da Terra à noite da NASA, câmera guiada pela rolagem que desce até Balneário Camboriú, enquadramentos fotográficos 2.39:1 com movimento de câmera, timecode, granulação de película e tipografia editorial. Sem ícones e sem efeitos genéricos. Preparado para telas 2K e 4K.

## Estrutura

```
index.html              # página completa (HTML + CSS + JS)
img/
  logo-rf.png           # logo RF / RF GROUP®
  terra-noite-nasa.jpg  # Terra à noite (NASA Earth Observatory, domínio público)
  capa-reuniao.jpg      # foto da equipe (reserva)
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
