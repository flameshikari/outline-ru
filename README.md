# 📚 [Outline](https://github.com/outline/outline) с русским переводом [![Build Status](https://img.shields.io/github/actions/workflow/status/flameshikari/outline-ru/build.yml)](https://github.com/flameshikari/outline-ru/actions) [![Version](https://img.shields.io/github/v/release/flameshikari/outline-ru?style=)](https://github.com/flameshikari/outline-ru/releases/latest)

## ❓ Зачем

Поддержка русского языка в [Outline](https://github.com/outline/outline) прекращена в версии [0.71.0](https://github.com/outline/outline/releases/tag/v0.71.0) по [некоторым причинам](https://github.com/outline/outline/discussions/5706).

## 📝 Примечания

- образ доступен в [Docker Hub](https://hub.docker.com/r/flameshikari/outline-ru/tags) и [GHCR](https://github.com/flameshikari/outline-ru/pkgs/container/outline-ru)
- за основу взят перевод из [этого коммита](https://github.com/outline/outline/commit/228d1faa9fd3cbb82409d98e1443fed65adc5715)
- сообщить о некорректном переводе можно [тут](https://github.com/flameshikari/outline-ru/discussions/8)

## 🐳 Установка

> Перед установкой **ОБЯЗАТЕЛЬНО** прочтите [про бэкапы перед обновлением](https://docs.getoutline.com/s/hosting/doc/backups-KZtPOADCHG)

Следуйте [официальной инструкции](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t), только в качестве `image` укажите `flameshikari/outline-ru:latest` (желательно зафиксировать версию, заменив `latest` на один из [доступных тегов](https://github.com/flameshikari/outline-ru/tags)). Например:

```yaml
services:
  outline:
    image: flameshikari/outline-ru:0.85.0
    # image: ghcr.io/flameshikari/outline-ru:0.85.0
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

## 🛠️ Разработка

### Описание

Контейнер Outline описан в одном [Dockerfile](./Dockerfile) на основе двух оригинальных с применением [патча](./tools/language.patch) поверх исходного кода Outline (он подключен к этому репозиторию в качестве подмодуля) и копированием [файла перевода](./tools/translation.json). Патч, помимо добавления отсутствующих строк в код, меняет некоторые upstream-ссылки, чтобы Outline мониторил этот контейнер на наличие новых версий, а не оригинальный.

В [docker-compose.yml](./docker-compose.yml) описаны четыре контейнера (кликабельные названия далее — это localhost-ссылки): [Outline](http://localhost:10240), Redis, Postgres и [тестовый OIDC-сервер](http://localhost:10241) (логин/пароль: `outline`). Также там описана вся конфигурация контейнеров; настраивайте под себя по желанию. После первой сборки контейнера большинство слоёв берётся из кэша, сам Outline после изменений пересобирается около полминуты-минуты (тут зависит от железа). Пайплайн примерно такой: перевёл → собрал → проверил.

Скрипт [diff.py](./tools/diff.py) используется для объединения переводов [английского](https://github.com/outline/outline/blob/main/shared/i18n/locales/en_US/translation.json) с [русским](./tools/translation.json) во временный файл `./tools/translation.tmp.json`. Скрипт не имеет интерактивного режима и каких-либо аргументов/опций, он просто запускается (с выводом некоторой полезной информации) и делает следующее:

- сохраняет актуальные переведённые строки
- удаляет неактуальные переведённые строки
- если в файле перевода есть одинаковые key/value пары, то они считаются исключениями (например, `HTML` или `API`) и переносятся как есть
- новые непереведённые строки добавляются в конец

> Возможно, для коллективного перевода стоило использовать [Crowdin](https://crowdin.com), но что-то руки не дошли ¯\\_(ツ)_/¯

Во временном файле вручную делается перевод новых строк, а затем [файл перевода](./tools/translation.json) вручную заменяется временным файлом.

> Если во временном файле присутствуют две одинаковые непереведённые строки, но одна из них с суффиксом `_plural` (множественное число), например:
> 
> ```json
> {
>   "{{ count }} comment": "{{ count }} comment",
>   "{{ count }} comment_plural": "{{ count }} comments"
> }
> ```
> …то нужно заменить эти строки на следующие (для справки: [множественное число](https://www.i18next.com/translation-function/plurals#languages-with-multiple-plurals) в [i18next](https://www.i18next.com) с [JSON-форматом версии 3](https://www.i18next.com/misc/json-format#i18next-json-v3)):
> 
> ```json
> {
>   "{{ count }} comment_0": "{{ count }} комментарий",
>   "{{ count }} comment_1": "{{ count }} комментария",
>   "{{ count }} comment_2": "{{ count }} комментариев"
> }
> ```

### Команды

0. Клонирование репозитория с подмодулем
    ```sh
    git clone --recurse-submodules git@github.com:flameshikari/outline-ru.git
    ```

1. Пулл изменений в подмодуле и переключение на коммит с целевой версией
    ```sh
    cd outline
    git pull --rebase --tags
    git checkout v0.85.0
    cd -
    ```

2. Формирование временного файла с помощью [diff.py](./tools/diff.py)
    ```sh
    python ./tools/diff.py
    ```

3. Замена [файла перевода](./tools/translation.json) после перевода строк во временном файле
    ```
    cp ./tools/translation.tmp.json ./tools/translation.json
    ```

4. Сборка контейнера
    ```sh
    docker compose up -d --build
    ```