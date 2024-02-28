# Зачем?

[Потому что русский — язык террористов](https://github.com/outline/outline/discussions/5706).

# Примечания

По возможности буду поддерживать контейнер, обновлять до текущей версии, добавлять переводы для новых пунктов (но ничего не обещаю). Перевод может быть неточным, буду рад помощи.

# Установка

Всё делается по [официальной инструкции](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t), только в качестве `image` нужно использовать `flameshikari/outline-ru`.

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