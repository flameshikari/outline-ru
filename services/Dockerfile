FROM oven/bun:1-alpine

USER root

RUN apk add --no-cache postgresql17 postgresql17-contrib redis su-exec bash

ENV PGDATA=/var/lib/postgresql/data
RUN mkdir -p "$PGDATA" /run/postgresql /var/log \
 && chown -R postgres:postgres "$PGDATA" /run/postgresql

WORKDIR /app
COPY package.json ./
RUN bun install --production
COPY server.js entrypoint.sh avatar.png ./
RUN chmod +x entrypoint.sh

CMD ["./entrypoint.sh"]
