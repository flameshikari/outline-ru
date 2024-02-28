ARG APP_PATH=/opt/outline

FROM node:20-alpine as base
ARG APP_PATH
WORKDIR $APP_PATH

FROM base AS build
COPY ./src/package.json ./src/yarn.lock ./
COPY ./src/patches ./patches
RUN yarn install --no-optional --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean
COPY src .
COPY shared ./shared
RUN yarn build
RUN rm -rf node_modules
RUN yarn install --production=true --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean

FROM base AS release
RUN apk add --no-cache curl ca-certificates
ENV NODE_ENV production
COPY --from=build $APP_PATH/build ./build
COPY --from=build $APP_PATH/server ./server
COPY --from=build $APP_PATH/public ./public
COPY --from=build $APP_PATH/.sequelizerc ./.sequelizerc
COPY --from=build $APP_PATH/node_modules ./node_modules
COPY --from=build $APP_PATH/package.json ./package.json
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs $APP_PATH/build && \
    mkdir -p /var/lib/outline && \
    chown -R nodejs:nodejs /var/lib/outline
ENV FILE_STORAGE_LOCAL_ROOT_DIR /var/lib/outline/data
RUN mkdir -p "$FILE_STORAGE_LOCAL_ROOT_DIR" && \
    chown -R nodejs:nodejs "$FILE_STORAGE_LOCAL_ROOT_DIR" && \
    chmod 1777 "$FILE_STORAGE_LOCAL_ROOT_DIR"
VOLUME /var/lib/outline/data
USER nodejs
EXPOSE 3000
CMD ["yarn", "start"]