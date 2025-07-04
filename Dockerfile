ARG APP_PATH=/opt/outline
ARG SRC_PATH=./outline

FROM node:20 AS deps
ARG APP_PATH
ARG SRC_PATH
WORKDIR $APP_PATH
COPY ${SRC_PATH}/package.json ${SRC_PATH}/yarn.lock ./
RUN yarn install --production=true --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean

FROM node:20 AS build
ARG APP_PATH
ARG SRC_PATH
WORKDIR $APP_PATH
RUN apt-get update && \
    apt-get install -y patch cmake && \
    rm -rf /var/lib/apt/lists/*
COPY ${SRC_PATH}/patches ./patches
COPY ${SRC_PATH}/package.json ${SRC_PATH}/yarn.lock ./
ENV NODE_OPTIONS="--max-old-space-size=24000"
RUN yarn install --no-optional --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean
COPY ${SRC_PATH} .
COPY ./tools/language.patch .
RUN patch -p1 < language.patch
COPY ./tools/translation.json ./shared/i18n/locales/ru_RU/translation.json
ARG CDN_URL
RUN yarn build && rm -rf node_modules

FROM node:22-slim AS release
ARG APP_PATH
ARG SRC_PATH
WORKDIR $APP_PATH
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
ARG DATA_PATH=/var/lib/outline/data
ARG USER=nodejs
RUN useradd -U ${USER} && \
    mkdir -p ${DATA_PATH} && \
    chown -R ${USER}:${USER} ${APP_PATH} ${DATA_PATH}/.. && \
    chmod 1777 ${DATA_PATH}
COPY --chown=${USER} --from=deps  $APP_PATH/node_modules ./node_modules
COPY --chown=${USER} --from=build $APP_PATH/build ./build
COPY --chown=${USER} --from=build $APP_PATH/server ./server
COPY --chown=${USER} --from=build $APP_PATH/public ./public
COPY --chown=${USER} --from=build $APP_PATH/.sequelizerc .
COPY --chown=${USER} --from=build $APP_PATH/package.json .
ENV NODE_ENV=production
ENV PORT=3000
USER ${USER}
EXPOSE ${PORT}
VOLUME ${DATA_PATH}
HEALTHCHECK --interval=1m CMD curl -fs localhost:${PORT}/_health | grep -q OK || exit 1
CMD ["yarn", "start"]
