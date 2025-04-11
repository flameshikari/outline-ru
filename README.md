# 📚 [Outline](https://github.com/outline/outline) с русским переводом [![Build Status](https://img.shields.io/github/actions/workflow/status/flameshikari/outline-ru/build.yml)](https://github.com/flameshikari/outline-ru/actions) [![Version](https://img.shields.io/github/v/release/flameshikari/outline-ru?style=)](https://github.com/flameshikari/outline-ru/releases/latest)

## ❓ Зачем

Поддержка русского языка в [Outline](https://github.com/outline/outline) прекращена в версии [0.71.0](https://github.com/outline/outline/releases/tag/v0.71.0) по [некоторым причинам](https://github.com/outline/outline/discussions/5706).

## 📝 Примечания

- образ доступен в [Docker Hub](https://hub.docker.com/r/flameshikari/outline-ru/tags) и [GHCR](https://github.com/flameshikari/outline-ru/pkgs/container/outline-ru)
- за основу взят перевод из [этого коммита](https://github.com/outline/outline/commit/228d1faa9fd3cbb82409d98e1443fed65adc5715)
- сообщить о некорректном переводе можно [тут](https://github.com/flameshikari/outline-ru/discussions/8)

## 🐳 Установка

> перед установкой **ОБЯЗАТЕЛЬНО** прочтите [про бэкапы перед обновлением](https://docs.getoutline.com/s/hosting/doc/backups-KZtPOADCHG)

Следуйте [официальной инструкции](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t), только в качестве `image` укажите `flameshikari/outline-ru:latest` (желательно зафиксировать версию, заменив `latest` на один из [доступных тегов](https://github.com/flameshikari/outline-ru/tags)). Например:

```yaml
services:
  outline:
    image: flameshikari/outline-ru:0.83.0
    # image: ghcr.io/flameshikari/outline-ru:0.83.0
    env_file: ./docker.env
    expose:
      - 3000
    volumes:
      - storage-data:/var/lib/outline/data
    depends_on:
      - postgres
      - redis

  ...
```
