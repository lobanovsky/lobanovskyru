import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile, access } from 'node:fs/promises';

test('homepage has working section targets, local assets and contact links', async () => {
  const html = await readFile('dist/index.html', 'utf8');
  assert.match(html, /<html lang="ru"/);
  assert.equal((html.match(/<h1[ >]/g) || []).length, 1);
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) {
    assert.ok(html.includes(`id="${id}"`), `Missing section ${id}`);
  }
  for (const [, path] of html.matchAll(/(?:href|src)="(\/[^"#?]+)"/g)) {
    await access(`dist${path}`);
  }
  assert.ok(html.includes('https://basket.lobanovsky.ru'));
  assert.ok(html.includes('mailto:e.lobanovsky@ya.ru'));
  assert.ok(html.includes('https://t.me/e_lobanovsky'));
  assert.doesNotMatch(html, /<form[ >]/);
});

test('missing page and crawler policy are built', async () => {
  assert.match(await readFile('dist/404.html', 'utf8'), /noindex/);
  assert.match(await readFile('dist/robots.txt', 'utf8'), /User-agent: \*/);
});
