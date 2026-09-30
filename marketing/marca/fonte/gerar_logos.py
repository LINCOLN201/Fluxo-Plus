"""Gera todos os logos da marca Fluxo em SVG (texto convertido em curvas).

Uso (na raiz do repo):  python3 marketing/marca/fonte/gerar_logos.py
Requer: fonttools (pip install fonttools).
"""
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

RAIZ = Path(__file__).resolve().parents[3]
SAIDA = RAIZ / "marketing" / "marca" / "logos"

# Paleta oficial (identidade Grafite).
LIMA = "#C6FF5E"
GRAFITE = "#0A0A0B"
SUPERFICIE = "#151516"
BRANCO = "#F2F2F0"

# ---------------------------------------------------------------------------
# Símbolo — grade de 512. Linguagem "folha": cada forma tem um canto reto e o
# canto oposto arredondado. Haste + braço superior formam uma só faixa que
# flui para a direita; o braço do meio fica solto, como um canal de fluxo.
# ---------------------------------------------------------------------------
F_HASTE = ("M104 432V212C104 136 160 80 236 80H424C424 138 386 176 328 176H240"
           "C213 176 196 193 196 220V372C196 405 169 432 136 432Z")
F_BRACO = "M228 244H372C372 295 336 322 290 322H228Z"

# Selos dos produtos, no quadrante inferior direito (vazio no F).
SELO_MAIS = ("M338 338h40v-40a10 10 0 0 1 10-10h28a10 10 0 0 1 10 10v40h40a10 10 0 0 1 10 10"
             "v28a10 10 0 0 1-10 10h-40v40a10 10 0 0 1-10 10h-28a10 10 0 0 1-10-10v-40h-40"
             "a10 10 0 0 1-10-10v-28a10 10 0 0 1 10-10z")
SELO_CHECK_CIRCULO = (402, 386, 74)
SELO_CHECK = "M366 388l24 24 46-54"

PRODUTOS = {
    # id: (sufixo do nome, selo)
    "fluxo": ("", None),
    "fluxo-plus": ("+", "mais"),
    "fluxocheck": ("check", "check"),
}


def caixa(selo):
    """Limites (x0, y0, x1, y1) do símbolo na grade de 512."""
    return (104, 80, 424, 432) if selo is None else (104, 80, 476, 460)


def simbolo(cor, selo=None):
    """Desenha o F (e o selo do produto). O check é vazado por máscara: funciona sobre qualquer fundo."""
    partes = [f'<path fill="{cor}" d="{F_HASTE}"/>', f'<path fill="{cor}" d="{F_BRACO}"/>']
    if selo == "mais":
        partes.append(f'<path fill="{cor}" d="{SELO_MAIS}"/>')
    elif selo == "check":
        cx, cy, r = SELO_CHECK_CIRCULO
        partes.append(
            f'<mask id="vazado-check"><rect x="0" y="0" width="512" height="512" fill="#fff"/>'
            f'<path fill="none" stroke="#000" stroke-width="22" stroke-linecap="round" '
            f'stroke-linejoin="round" d="{SELO_CHECK}"/></mask>'
            f'<circle fill="{cor}" cx="{cx}" cy="{cy}" r="{r}" mask="url(#vazado-check)"/>')
    return "".join(partes)


# ---------------------------------------------------------------------------
# Logotipo — Manrope ExtraBold (800), minúsculo, espaçamento fechado.
# ---------------------------------------------------------------------------
_fonte = TTFont(RAIZ / "assets" / "fonts" / "Manrope-Variable.ttf")
_fonte = instantiateVariableFont(_fonte, {"wght": 800})
_glifos = _fonte.getGlyphSet()
_cmap = _fonte.getBestCmap()
_upm = _fonte["head"].unitsPerEm
ALTURA_X = _fonte["OS/2"].sxHeight


def texto(txt, tamanho, x=0, y=0, rastreio=-0.04):
    """Converte texto em path. `y` é a linha de base; retorna (path, largura)."""
    escala = tamanho / _upm
    caneta = SVGPathPen(_glifos)
    avanco = 0.0
    for ch in txt:
        nome = _cmap[ord(ch)]
        t = TransformPen(caneta, (escala, 0, 0, -escala, x + avanco, y))
        _glifos[nome].draw(t)
        avanco += _glifos[nome].width * escala + rastreio * tamanho
    return caneta.getCommands(), avanco - rastreio * tamanho


def svg(largura, altura, corpo, fundo=None):
    bg = f'<rect width="100%" height="100%" fill="{fundo}"/>' if fundo else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {largura:.0f} {altura:.0f}" '
            f'width="{largura:.0f}" height="{altura:.0f}">{bg}{corpo}</svg>\n')


def horizontal(prod, cor_marca, cor_texto, fundo=None):
    """Símbolo + nome. 'fluxo' na cor da marca, sufixo do produto na cor do texto."""
    sufixo, selo = PRODUTOS[prod]
    x0, y0, x1, y1 = caixa(selo)
    esc = 160 / 352  # o F (y 80–432) sempre com 160 de altura
    corpo = [f'<g transform="translate({-x0 * esc:.2f} {-y0 * esc:.2f}) scale({esc:.4f})">'
             f'{simbolo(cor_marca, selo)}</g>']
    tam = 172
    base = 160  # linha de base do texto = pé da haste
    x = (x1 - x0) * esc + 44
    d, w1 = texto("fluxo", tam, x, base)
    corpo.append(f'<path fill="{cor_marca}" d="{d}"/>')
    largura = x + w1
    if sufixo:
        folga = 6 if sufixo == "+" else 16
        d2, w2 = texto(sufixo, tam, largura + folga, base)
        corpo.append(f'<path fill="{cor_texto}" d="{d2}"/>')
        largura += w2 + folga
    # +4 para a sobra óptica do "o" abaixo da linha de base
    return svg(largura, max((y1 - y0) * esc, base + 4), "".join(corpo), fundo)


def icone_app(prod, fundo, cor):
    _, selo = PRODUTOS[prod]
    return svg(512, 512,
               f'<rect width="512" height="512" rx="116" fill="{fundo}"/>'
               f'<g transform="translate(64 64) scale(.75)">{simbolo(cor, selo)}</g>')


def gerar():
    SAIDA.mkdir(parents=True, exist_ok=True)
    arquivos = {}
    variantes = {
        # nome: (cor da marca, cor do texto, fundo do arquivo)
        "lima": (LIMA, BRANCO, None),        # para fundos escuros
        "grafite": (GRAFITE, GRAFITE, None),  # para fundos claros / sobre lima
        "branco": (BRANCO, BRANCO, None),     # monocromático claro
    }
    for prod, (_, selo) in PRODUTOS.items():
        x0, y0, x1, y1 = caixa(selo)
        for var, (cm, ct, fd) in variantes.items():
            arquivos[f"{prod}-simbolo-{var}.svg"] = svg(
                x1 - x0, y1 - y0,
                f'<g transform="translate({-x0} {-y0})">{simbolo(cm, selo)}</g>')
            arquivos[f"{prod}-horizontal-{var}.svg"] = horizontal(prod, cm, ct, fd)
        arquivos[f"{prod}-icone-app.svg"] = icone_app(prod, GRAFITE, LIMA)
        arquivos[f"{prod}-icone-app-lima.svg"] = icone_app(prod, LIMA, GRAFITE)
    for nome, conteudo in arquivos.items():
        (SAIDA / nome).write_text(conteudo, encoding="utf-8")
    return sorted(arquivos)


if __name__ == "__main__":
    for n in gerar():
        print("logos/" + n)
