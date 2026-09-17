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
  assert.ok(html.includes('tel:+79267936363'));
  for (const product of ['TripPip', 'Билеты в продаже', 'Дом под управлением', 'Въезд под контролем', 'Корзина Лобановского', 'Робот-Рита']) {
    assert.ok(html.includes(product), `Missing product ${product}`);
  }
  for (const bot of ['nations_ticket_bot', 'ramt_ticket_bot', 'fomenkiru_bot', 'vakhtangov_ticket_bot', 'lensov_ticket_bot', 'mxt_ticket_bot', 'satirikon_ticket_bot']) {
    assert.ok(html.includes(`https://t.me/${bot}`), `Missing theatre bot ${bot}`);
  }
  assert.ok(html.includes('https://trippip.ru'));
  assert.ok(html.includes('https://lobanovsky.ru/og.png'));
  await access('dist/og.png');
  assert.doesNotMatch(html, /<form[ >]/);
});

test('missing page and crawler policy are built', async () => {
  assert.match(await readFile('dist/404.html', 'utf8'), /noindex/);
  assert.match(await readFile('dist/robots.txt', 'utf8'), /User-agent: \*/);
});


test('basket page has its own canonical, product details and local photos', async () => {
  const html = await readFile('dist/basket/index.html', 'utf8');
  assert.ok(html.includes('href="https://basket.lobanovsky.ru/"'));
  assert.ok(html.includes('Корзина Лобановского'));
  assert.ok(html.includes('https://t.me/e_lobanovsky'));
  assert.equal((html.match(/<h1[ >]/g) || []).length, 1);
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) {
    assert.ok(html.includes(`id="${id}"`), `Missing basket section ${id}`);
  }
  for (const [, path] of html.matchAll(/(?:href|src)="(\/[^"#?]+)"/g)) {
    await access(`dist${path}`);
  }
  assert.doesNotMatch(html, /static\.tildacdn|tilda-forms|<form[ >]/);
});
