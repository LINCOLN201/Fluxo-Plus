# Marca Fluxo

Identidade visual proprietária da **Fluxo**, a empresa por trás do
**Fluxo+** e do **FluxoCheck**.

📘 **[Manual da marca (PDF)](manual-da-marca-fluxo.pdf)** — essência,
arquitetura, símbolo, versões, área de proteção, cores, tipografia, usos
incorretos, aplicações e tom de voz.

## Logos — [`logos/`](logos/)

### Fluxo (empresa)

Símbolo **"três lâminas"**: nasce do F de lâminas em forma de folha que o
Fluxo+ e o FluxoCheck têm em comum. A lâmina maior é a raiz (a Fluxo); as
menores crescem dela, uma por produto.

| Arquivo | Uso |
|---|---|
| `fluxo-horizontal-*.svg` | Logo principal (símbolo + "fluxo") |
| `fluxo-simbolo-*.svg` | Espaços pequenos, avatar, favicon |
| `fluxo-icone-app*.svg` | Ícone quadrado arredondado |
| `fluxo-endosso-*.svg` | Assinatura **"um produto fluxo"** para peças dos apps |

Cores (`*`): **lima** (fundos escuros), **grafite** (fundos claros ou lima) e
**branco** (fotos e 1 cor). SVG com texto em curvas + PNG de 1024 px em
[`logos/png/`](logos/png/).

### Produtos — [`logos/produtos/`](logos/produtos/)

Cada app **mantém a logo original** — o símbolo da Fluxo nunca a substitui.
A ligação com a empresa é feita pela assinatura de endosso.

| Arquivo | Origem |
|---|---|
| `fluxo-plus-simbolo-branco.png` | Original do app (`assets/icon/fluxo_mark.png`) |
| `fluxo-plus-icone.png` | Original do app (`assets/icon/fluxo_plus_monochrome.png`) |
| `fluxo-plus-simbolo-lima/grafite.png`, `fluxo-plus-horizontal-*.png` | Derivados: só cor e nome ao lado |
| `fluxocheck-icone.png` | Original do app (repositório fluxocheck, `app/icon.png`) |
| `fluxocheck-horizontal-*.png` | Derivado: ícone original + nome |

## Templates — [`templates/`](templates/)

| Arquivo | Formato | Uso |
|---|---|---|
| `ig-institucional` | 1080×1350 | Post da marca-mãe |
| `ig-produto-fluxo-plus` | 1080×1350 | Post de produto (B2C) |
| `ig-produto-fluxocheck` | 1080×1350 | Post de produto (B2B, versão clara) |
| `ig-dica` | 1080×1350 | Conteúdo educativo em passos |
| `ig-frase` | 1080×1350 | Frase/manifesto (fundo lima) |
| `ig-novidade` | 1080×1350 | Nova versão de app |
| `ig-carrossel-capa` / `ig-carrossel-interna` | 1080×1350 | Carrossel |
| `story-padrao` / `story-chamada` | 1080×1920 | Stories |
| `capa-linkedin` | 1584×396 | Capa da página no LinkedIn |
| `og-compartilhamento` | 1200×630 | Imagem de link (site, WhatsApp) |
| `slide-capa` / `slide-conteudo` | 1920×1080 | Apresentações |
| `cartao-frente` / `cartao-verso` | 90×50 mm, 300 dpi | Cartão de visita |
| `assinatura-email` (+ `.html`) | 600×160 | Assinatura de e-mail |

## Como editar e gerar de novo

Tudo é gerado a partir de código neste repositório — sem depender de Canva
ou de licença de terceiros.

1. **Logos:** o desenho do símbolo está em `fonte/gerar_logos.py`
   (constante `LAMINAS`). Os derivados dos produtos vêm de `fonte/produtos.html`.
2. **Templates:** edite os textos em `fonte/templates.html` (instruções no
   topo do arquivo). Estilo comum em `fonte/base.css`.
3. **Manual:** `fonte/manual.html`.
4. Gere tudo:

```bash
pip install fonttools
python3 marketing/marca/fonte/gerar_logos.py   # SVGs dos logos
node marketing/marca/fonte/render.mjs          # PNGs, templates e PDF (requer playwright)
node marketing/instagram/fonte/render.mjs      # peças do Instagram
```

Para editar em Figma, Illustrator ou Inkscape, importe os SVGs de `logos/`.

## Fonte

**Manrope** (SIL Open Font License, uso comercial livre) —
`assets/fonts/Manrope-Variable.ttf`.
