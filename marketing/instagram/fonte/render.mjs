// Gera os PNGs do Instagram a partir de pecas.html.
// Uso (na raiz do repo): node marketing/instagram/fonte/render.mjs
// Requer o pacote `playwright` (local ou global: NODE_PATH="$(npm root -g)").
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const aqui = path.dirname(fileURLToPath(import.meta.url));
const saida = path.join(aqui, '..', 'imagens');

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 2000 } });
await page.goto(pathToFileURL(path.join(aqui, 'pecas.html')).href);
await page.evaluate(() => document.fonts.ready);

const ids = await page.$$eval('.peca[id]', (els) => els.map((e) => e.id));
for (const id of ids) {
  await page.locator(`#${id}`).screenshot({ path: path.join(saida, `${id}.png`) });
  console.log(`imagens/${id}.png`);
}
await browser.close();
