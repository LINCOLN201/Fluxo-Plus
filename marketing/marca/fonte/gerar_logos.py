"""Gera os logos da Fluxo (marca-mãe) em SVG, com o texto convertido em curvas.

Os produtos (Fluxo+ e FluxoCheck) mantêm as próprias logos originais; elas
ficam em logos/produtos/ e não são geradas aqui.

Uso (na raiz do repo):  python3 marketing/marca/fonte/gerar_logos.py
Requer: fonttools (pip install fonttools).
"""
import math
import re
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
BRANCO = "#F2F2F0"
SUAVE = "#8A8A8E"

# ---------------------------------------------------------------------------
# Símbolo "três lâminas" — grade de 512.
# Nasce do que os dois apps têm em comum: o F feito de lâminas em forma de
# folha (ponta afiada, lado arredondado) com um corte curvo entre elas.
# A lâmina maior é a raiz (a Fluxo); as outras duas crescem dela, uma para
# cada produto — e o desenho comporta o ecossistema crescendo.
# Todas as lâminas levam a mesma inclinação de 8°, o movimento do fluxo.
# ---------------------------------------------------------------------------
LAMINAS = (
    "M104 452C96 320 110 196 176 130C220 86 286 76 444 76C440 134 402 168 342 168"
    "H290C240 168 212 192 204 240L188 360C178 420 150 452 104 452Z",
    "M232 248C246 234 268 230 304 230H402C398 286 360 314 302 314H212Z",
    "M214 344C224 334 240 330 262 330H322C318 368 294 388 256 388H200Z",
)
INCLINACAO = math.tan(math.radians(8))
DESLOCAMENTO = 64  # recentraliza depois da inclinação


def _inclinar(x, y):
    return x - INCLINACAO * y + DESLOCAMENTO, y


def _limites():
    """Caixa do símbolo já inclinado, amostrando as curvas."""
    xs, ys = [], []
    for d in LAMINAS:
        tokens = re.findall(r"[MCHLZ]|-?\d+(?:\.\d+)?", d)
        i, cx, cy, cmd = 0, 0.0, 0.0, None
        while i < len(tokens):
            if tokens[i].isalpha():
                cmd = tokens[i]
                i += 1
                if cmd == "Z":
                    continue
            n = lambda k: float(tokens[i + k])  # noqa: E731
            if cmd == "M" or cmd == "L":
                cx, cy = n(0), n(1)
                i += 2
                pts = [(cx, cy)]
            elif cmd == "H":
                cx = n(0)
                i += 1
                pts = [(cx, cy)]
            elif cmd == "C":
                p0, p1, p2, p3 = (cx, cy), (n(0), n(1)), (n(2), n(3)), (n(4), n(5))
                i += 6
                pts = []
                for s in range(21):
                    t = s / 20
                    a, b, c, e = (1 - t) ** 3, 3 * t * (1 - t) ** 2, 3 * t * t * (1 - t), t ** 3
                    pts.append((a * p0[0] + b * p1[0] + c * p2[0] + e * p3[0],
                                a * p0[1] + b * p1[1] + c * p2[1] + e * p3[1]))
                cx, cy = p3
            for px, py in pts:
                qx, qy = _inclinar(px, py)
                xs.append(qx)
                ys.append(qy)
    return min(xs), min(ys), max(xs), max(ys)


X0, Y0, X1, Y1 = _limites()
LARG, ALT = X1 - X0, Y1 - Y0


def simbolo(cor):
    """Grupo SVG do símbolo, com origem no canto superior esquerdo da caixa."""
    laminas = "".join(f'<path d="{d}"/>' for d in LAMINAS)
    return (f'<g fill="{cor}" transform="translate({-X0:.2f} {-Y0:.2f}) '
            f'translate({DESLOCAMENTO} 0) skewX(-8)">{laminas}</g>')


# ---------------------------------------------------------------------------
# Logotipo — Manrope ExtraBold (800), minúsculo, espaçamento fechado.
# ---------------------------------------------------------------------------
_fonte = instantiateVariableFont(TTFont(RAIZ / "assets" / "fonts" / "Manrope-Variable.ttf"),
                                 {"wght": 800})
_glifos = _fonte.getGlyphSet()
_cmap = _fonte.getBestCmap()
_upm = _fonte["head"].unitsPerEm


def texto(txt, tamanho, x=0, y=0, rastreio=-0.04):
    """Converte texto em path. `y` é a linha de base; retorna (path, largura)."""
    escala = tamanho / _upm
    caneta = SVGPathPen(_glifos)
    avanco = 0.0
    for ch in txt:
        nome = _cmap[ord(ch)]
        _glifos[nome].draw(TransformPen(caneta, (escala, 0, 0, -escala, x + avanco, y)))
        avanco += _glifos[nome].width * escala + rastreio * tamanho
    return caneta.getCommands(), avanco - rastreio * tamanho


def svg(largura, altura, corpo):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {largura:.0f} {altura:.0f}" '
            f'width="{largura:.0f}" height="{altura:.0f}">{corpo}</svg>\n')


def horizontal(cor):
    """Símbolo + 'fluxo'. Altura do símbolo = 160; texto na linha de base do pé."""
    esc = 160 / ALT
    x = LARG * esc + 30
    d, w = texto("fluxo", 172, x, 158)
    corpo = f'<g transform="scale({esc:.4f})">{simbolo(cor)}</g><path fill="{cor}" d="{d}"/>'
    return svg(x + w, 164, corpo)


def endosso(cor_marca, cor_texto):
    """Assinatura de endosso para peças de produto: 'um produto [F] fluxo'."""
    d1, w1 = texto("um produto", 64, 0, 76, rastreio=-0.01)
    esc = 84 / ALT
    xs = w1 + 26
    d2, w2 = texto("fluxo", 92, xs + LARG * esc + 14, 78)
    corpo = (f'<path fill="{cor_texto}" d="{d1}"/>'
             f'<g transform="translate({xs:.1f} 0) scale({esc:.4f})">{simbolo(cor_marca)}</g>'
             f'<path fill="{cor_marca}" d="{d2}"/>')
    return svg(xs + LARG * esc + 14 + w2, 86, corpo)


def icone_app(fundo, cor):
    esc = 300 / ALT
    tx, ty = (512 - LARG * esc) / 2, (512 - ALT * esc) / 2
    return svg(512, 512, f'<rect width="512" height="512" rx="116" fill="{fundo}"/>'
                         f'<g transform="translate({tx:.1f} {ty:.1f}) scale({esc:.4f})">{simbolo(cor)}</g>')


def gerar():
    SAIDA.mkdir(parents=True, exist_ok=True)
    arquivos = {}
    for var, cor in {"lima": LIMA, "grafite": GRAFITE, "branco": BRANCO}.items():
        arquivos[f"fluxo-simbolo-{var}.svg"] = svg(LARG, ALT, simbolo(cor))
        arquivos[f"fluxo-horizontal-{var}.svg"] = horizontal(cor)
    arquivos["fluxo-endosso-lima.svg"] = endosso(LIMA, SUAVE)
    arquivos["fluxo-endosso-grafite.svg"] = endosso(GRAFITE, "#6E6E72")
    arquivos["fluxo-icone-app.svg"] = icone_app(GRAFITE, LIMA)
    arquivos["fluxo-icone-app-lima.svg"] = icone_app(LIMA, GRAFITE)
    for nome, conteudo in arquivos.items():
        (SAIDA / nome).write_text(conteudo, encoding="utf-8")
    return sorted(arquivos)


if __name__ == "__main__":
    for n in gerar():
        print("logos/" + n)
