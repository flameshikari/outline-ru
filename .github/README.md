# [Outline](https://github.com/outline/outline) с русским переводом

## Зачем?

Ну, возможно потому, что русский — [язык террористов](https://github.com/outline/outline/discussions/5706)? Шучу, конечно. Их право, но немного обидно. Наверняка есть форки с переводом, но я не нашёл ничего.

## Примечания

По возможности буду поддерживать контейнер, обновлять до текущей версии и добавлять переводы новых строк.

Перевод взят из [этого коммита](https://github.com/outline/outline/commit/228d1faa9fd3cbb82409d98e1443fed65adc5715), были допереведены новые строки. Возможно, перевод не самый точный; буду рад помощи в его улучшении.

Доступны только две архитектуры: `amd64` и `arm64`. QEMU на GitHub Actions очень медленный, сборки на других платформах зависают намертво.

## Установка

Всё делается по [официальной инструкции](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t), только в качестве `image` нужно использовать `flameshikari/outline-ru:latest` или `ghcr.io/flameshikari/outline-ru:latest` (вместо `latest` можно указать версию; доступные смотреть в [Docker Hub](https://hub.docker.com/r/flameshikari/outline-ru/tags) или [здесь в разделе пакетов](https://github.com/flameshikari/outline-ru/pkgs/container/outline-ru)).

```yaml
  ...

  outline:
    image: flameshikari/outline-ru:latest
    env_file: ./docker.env
    ports:
      - "3000:3000"
    volumes:
      - storage-data:/var/lib/outline/data
    depends_on:
      - postgres
      - redis

  ...
```
