FROM node:24-alpine AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM dependencies AS development
COPY astro.config.mjs ./
COPY src ./src
COPY public ./public
EXPOSE 4321
CMD ["./node_modules/.bin/astro", "dev", "--host", "0.0.0.0"]

FROM development AS build
COPY scripts/build.test.mjs ./scripts/build.test.mjs
RUN npm run build && npm test

FROM caddy:2.11.4-alpine AS production
RUN setcap -r /usr/bin/caddy
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/dist /srv
USER 1000:1000
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/index.html || exit 1
