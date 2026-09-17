# Бюро Лобановского

Информационный сайт на Astro. Сборка и тесты выполняются в Docker; готовую статику обслуживает Caddy. На сервере HTTPS и маршрутизацией управляет существующий Traefik. `basket.lobanovsky.ru` пока остаётся на Тильде.

## Разработка в Docker

Нужны Docker Engine/Desktop и Docker Compose v2.20+.

```sh
docker compose -f compose.dev.yaml up --build
```

Открыть http://localhost:4321. Если порт занят: `DEV_PORT=4322 docker compose -f compose.dev.yaml up --build` и открыть localhost:4322. Изменения в `src/` и `public/` видны при сохранении. После изменения зависимостей пересобрать контейнер. Остановка:

```sh
docker compose -f compose.dev.yaml down
```

## Сборка и проверки

```sh
docker build -t lobanovskyru:check .
bash scripts/smoke-test.sh lobanovskyru:check
bash scripts/deploy.test.sh
```

Сборка выполняет `npm ci`, `npm run build` и `npm test` внутри Node.js 24. HTTP-проверка требует Bash и curl; проверяет главную, ресурс, 404 и редирект www. Тесты деплоя требуют Docker и проверяют ошибки и откат в изолированном контейнере без production-доступов.

Альтернатива без Docker: Node.js 24, `npm ci`, затем `npm run dev`. Для проверки сборки: `npm run build && npm test`. Отдельный тест: `node --test --test-name-pattern="missing page" scripts/build.test.mjs` после сборки.

## Где менять сайт

- `src/pages/` — страницы, тексты и метаданные.
- `src/styles/global.css` — оформление; `public/` — статические ресурсы.
- `deploy/Caddyfile` — HTTP внутри контейнера; `compose.yaml` — production и маршруты Traefik.

## Публикация

Push в `main` запускает Docker-сборку, тесты, публикацию `lobanovsky/lobanovskyru` в Docker Hub и SSH-деплой по digest образа. Pull request запускает только проверки. Настройка секретов, откат и DNS: [docs/deployment.md](docs/deployment.md).

Секреты и приватные ключи не коммитить: `private/` и `.env*` исключены из Git, Docker использует разрешённый список файлов контекста.
