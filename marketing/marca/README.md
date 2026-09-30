# Marca Fluxo

Identidade visual proprietária do ecossistema Fluxo e dos produtos **Fluxo+**
e **FluxoCheck**.

📘 **[Manual da marca (PDF)](manual-da-marca-fluxo.pdf)** — essência,
arquitetura, símbolo, versões, área de proteção, cores, tipografia, usos
incorretos, aplicações e tom de voz.

## Logos — [`logos/`](logos/)

Vetores em SVG (texto convertido em curvas, não depende da fonte instalada) e
PNG transparente de 1024 px em [`logos/png/`](logos/png/).

| Marca | Horizontal | Símbolo | Ícone de app |
|---|---|---|---|
| Fluxo (marca-mãe) | `fluxo-horizontal-*.svg` | `fluxo-simbolo-*.svg` | `fluxo-icone-app*.svg` |
| Fluxo+ | `fluxo-plus-horizontal-*.svg` | `fluxo-plus-simbolo-*.svg` | `fluxo-plus-icone-app*.svg` |
| FluxoCheck | `fluxocheck-horizontal-*.svg` | `fluxocheck-simbolo-*.svg` | `fluxocheck-icone-app*.svg` |

Variações de cor (`*`): **lima** (fundos escuros), **grafite** (fundos claros
ou lima) e **branco** (fotos e impressão em 1 cor). Ícones: grafite com F lima
(padrão) ou `-lima` (fundo lima, F grafite).

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
   (constantes `F_HASTE`, `F_BRACO` e selos).
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
