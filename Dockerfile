ARG APP_PATH=/opt/outline

FROM node:20-slim AS base
ARG APP_PATH
WORKDIR $APP_PATH

FROM base AS build
RUN apt-get update && \
    apt-get install -y patch && \
    rm -rf /var/lib/apt/lists/*
COPY ./outline/package.json ./outline/yarn.lock ./
COPY ./outline/patches ./patches
RUN yarn install --no-optional --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean
COPY ./outline .
COPY ./tools/translation.json ./shared/i18n/locales/ru_RU/translation.json
COPY ./tools/return_ru.patch .
RUN patch -p1 < return_ru.patch
ARG CDN_URL
RUN yarn build
RUN rm -rf node_modules
RUN yarn install --production=true --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean
ENV PORT=3000

FROM base AS release
ENV NODE_ENV=production
COPY --from=build $APP_PATH/build ./build
COPY --from=build $APP_PATH/server ./server
COPY --from=build $APP_PATH/public ./public
COPY --from=build $APP_PATH/.sequelizerc ./.sequelizerc
COPY --from=build $APP_PATH/node_modules ./node_modules
COPY --from=build $APP_PATH/package.json ./package.json
RUN apt-get update && \
    apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/*
RUN addgroup --gid 1001 nodejs && \
    adduser --uid 1001 --ingroup nodejs nodejs && \
    chown -R nodejs:nodejs $APP_PATH/build && \
    mkdir -p /var/lib/outline && \
    chown -R nodejs:nodejs /var/lib/outline
ENV FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
RUN mkdir -p "$FILE_STORAGE_LOCAL_ROOT_DIR" && \
    chown -R nodejs:nodejs "$FILE_STORAGE_LOCAL_ROOT_DIR" && \
    chmod 1777 "$FILE_STORAGE_LOCAL_ROOT_DIR"
VOLUME /var/lib/outline/data
USER nodejs
HEALTHCHECK --interval=1m CMD wget -qO- "http://localhost:${PORT:-3000}/_health" | grep -q "OK" || exit 1
EXPOSE 3000
CMD ["yarn", "start"]
