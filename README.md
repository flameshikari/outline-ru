![](.github/assets/opengraph.png)

# 📚 [Outline](https://github.com/outline/outline) с русским переводом [![Build Status](https://img.shields.io/github/actions/workflow/status/flameshikari/outline-ru/build.yml)](https://github.com/flameshikari/outline-ru/actions) [![Version](https://img.shields.io/github/v/release/flameshikari/outline-ru?style=)](https://github.com/flameshikari/outline-ru/releases/latest)

## ❓ Зачем

Поддержка русского языка в [Outline](https://github.com/outline/outline) прекращена в версии [0.71.0](https://github.com/outline/outline/releases/tag/v0.71.0) по [некоторым причинам](https://github.com/outline/outline/discussions/5706).

## 📝 Примечания

За основу взят перевод из [данного коммита](https://github.com/outline/outline/commit/228d1faa9fd3cbb82409d98e1443fed65adc5715), который впоследствии улучшается и переводится здесь.

Буду рад помощи в улучшении перевода или сборки; сообщить о некорректном переводе можно [здесь](https://github.com/flameshikari/outline-ru/discussions/8).

Из доступных архитектур контейнера имеются только `amd64` и `arm64`.

## ⚠️ Дисклеймер

Данное программное обеспечение предоставляется «как есть», без каких-либо гарантий, явно выраженных или подразумеваемых, включая гарантии товарной пригодности, соответствия по его конкретному назначению и отсутствия нарушений, но не ограничиваясь ими. Ни в каком случае авторы или правообладатели не несут ответственности по каким-либо искам, за ущерб или по иным требованиям, в том числе, при действии контракта, деликте или иной ситуации, возникшим из-за использования программного обеспечения или иных действий с программным обеспечением.

## 🐳 Установка

>  Перед установкой **ОБЯЗАТЕЛЬНО** прочтите [про бэкапы перед обновлением](https://docs.getoutline.com/s/hosting/doc/backups-KZtPOADCHG).

Всё делается по [официальной документации](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t), только в качестве `image` укажите `flameshikari/outline-ru:latest` или `ghcr.io/flameshikari/outline-ru:latest` (вместо `latest` желательно указать версию; доступные смотреть [здесь](https://github.com/flameshikari/outline-ru/tags)), а также задайте переменную `DEFAULT_LANGUAGE=ru_RU` в [docker.env](https://github.com/outline/outline/blob/main/.env.sample) или в `environments` (в зависимости от вашей конфигурации).

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
