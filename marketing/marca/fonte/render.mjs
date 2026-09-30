// Gera PNGs dos logos e templates e o PDF do manual da marca Fluxo.
// Uso (na raiz do repo):
//   python3 marketing/marca/fonte/gerar_logos.py   # 1º: SVGs dos logos
//   node marketing/marca/fonte/render.mjs          # 2º: PNGs + PDF
// Requer o pacote `playwright` (local ou global: NODE_PATH="$(npm root -g)").
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const aqui = path.dirname(fileURLToPath(import.meta.url));
const marca = path.join(aqui, '..');
const url = (arquivo) => pathToFileURL(path.join(aqui, arquivo)).href;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 2000, height: 2000 } });

// 1. Logos SVG → PNG (1024 px de largura; fundo transparente)
const logos = readdirSync(path.join(marca, 'logos')).filter((f) => f.endsWith('.svg'));
for (const svg of logos) {
  const src = pathToFileURL(path.join(marca, 'logos', svg)).href;
  await page.setContent(`<body style="margin:0;background:transparent">
    <img id="l" src="${src}" style="width:1024px;display:block"></body>`);
  await page.waitForFunction(() => document.getElementById('l').complete);
  await page.locator('#l').screenshot({
    path: path.join(marca, 'logos', 'png', svg.replace('.svg', '.png')),
    omitBackground: true,
  });
}
console.log(`${logos.length} logos em logos/png/`);

// 2. Logos dos produtos: só derivados das logos ORIGINAIS (cor e composição).
//    Chromium não aplica `mask` com imagem de file://; o Fluxo+ vai como data URI.
await page.goto(url('produtos.html'));
const marcaFp = readFileSync(path.join(marca, 'logos', 'produtos', 'fluxo-plus-simbolo-branco.png')).toString('base64');
await page.addStyleTag({ content: `:root { --fp: url(data:image/png;base64,${marcaFp}); }` });
await page.evaluate(() => document.fonts.ready);
const derivados = await page.$$eval('.p[id]', (els) => els.map((e) => e.id));
for (const id of derivados) {
  await page.locator(`#${id}`).screenshot({
    path: path.join(marca, 'logos', 'produtos', `${id}.png`), omitBackground: true,
  });
}
console.log(`${derivados.length} derivados em logos/produtos/`);

// 3. Templates → PNG
await page.goto(url('templates.html'));
await page.evaluate(() => document.fonts.ready);
const ids = await page.$$eval('.peca[id]', (els) => els.map((e) => e.id));
for (const id of ids) {
  await page.locator(`#${id}`).screenshot({ path: path.join(marca, 'templates', `${id}.png`) });
}
console.log(`${ids.length} templates em templates/`);

// 4. Manual da marca → PDF (A4 paisagem)
await page.goto(url('manual.html'));
await page.evaluate(() => document.fonts.ready);
await page.pdf({
  path: path.join(marca, 'manual-da-marca-fluxo.pdf'),
  width: '297mm', height: '210mm', printBackground: true,
  margin: { top: 0, right: 0, bottom: 0, left: 0 },
});
console.log('manual-da-marca-fluxo.pdf');

await browser.close();
