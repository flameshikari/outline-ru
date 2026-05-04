# 📚 [Outline](https://github.com/outline/outline) с русским переводом [![Build Status](https://img.shields.io/github/actions/workflow/status/flameshikari/outline-ru/build.yml)](https://github.com/flameshikari/outline-ru/actions) [![Version](https://img.shields.io/github/v/release/flameshikari/outline-ru?style=)](https://github.com/flameshikari/outline-ru/releases/latest)

## ❓ Зачем

Поддержка русского языка в [Outline](https://github.com/outline/outline) прекращена в версии [0.71.0](https://github.com/outline/outline/releases/tag/v0.71.0) по [некоторым причинам](https://github.com/outline/outline/discussions/5706).

## 📝 Примечания

- образ доступен в [Docker Hub](https://hub.docker.com/r/flameshikari/outline-ru/tags) и [GHCR](https://github.com/flameshikari/outline-ru/pkgs/container/outline-ru)
- за основу взят перевод из [этого коммита](https://github.com/outline/outline/commit/228d1faa9fd3cbb82409d98e1443fed65adc5715)
- сообщить о некорректном переводе можно [тут](https://github.com/flameshikari/outline-ru/discussions/8)

## 🐳 Установка

> [!WARNING]
> Перед обновлением **ОБЯЗАТЕЛЬНО** делайте [бэкап](https://docs.getoutline.com/s/hosting/doc/backups-KZtPOADCHG)!

Следуйте [официальной инструкции](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t), только в качестве `image` укажите `flameshikari/outline-ru:latest` (желательно зафиксировать версию, заменив `latest` на один из [доступных тегов](https://github.com/flameshikari/outline-ru/tags)). Например:

```yaml
services:
  outline:
    image: flameshikari/outline-ru:1.7.1
    # image: ghcr.io/flameshikari/outline-ru:1.7.1
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

### Ключевые файлы

- русский перевод — [translation/ru.json](./translation/ru.json)
- английский перевод — [outline/shared/i18n/locales/en_US/translation.json](https://github.com/outline/outline/blob/main/shared/i18n/locales/en_US/translation.json)
- временный файл — [translation/tmp.json]() (существует только локально)

### Описание работы скрипта

Скрипт [translation/merge.py](./translation/merge.py) используется для объединения английского и русского переводов во временный файл. Скрипт не имеет интерактивного режима и каких-либо аргументов/опций, он просто запускается (с выводом некоторой полезной информации) и делает следующее:

- сохраняет актуальные переведённые строки
- удаляет неактуальные переведённые строки
- если в русском переводе есть одинаковые key/value пары, то они считаются исключениями (например, `HTML` или `API`) и переносятся как есть
- новые непереведённые строки добавляются в конец

> Также скрипт конвертирует строки с суффиксом `_plural` (англ. множественное число) в строки с числовыми суффиксами, поддерживающие склонение по падежам. Например, имеем исходные данные:
> 
> ```jsonc
> {
>   // ...
>   "{{ count }} comment": "{{ count }} comment",
>   "{{ count }} comment_plural": "{{ count }} comments"
>   // ...
> }
> ```
> Строки после конвертации скриптом:
> ```jsonc
> {
>   // ...
>   "{{ count }} comment_0": "[NOT TRANSLATED]",
>   "{{ count }} comment_1": "[NOT TRANSLATED]",
>   "{{ count }} comment_2": "[NOT TRANSLATED]"
>   // ...
> }
> ```
> Конвертированные строки после перевода:
> ```jsonc
> {
>   // ...
>   "{{ count }} comment_0": "{{ count }} комментарий", // ед. число, им. падеж
>   "{{ count }} comment_1": "{{ count }} комментария", // ед. число, род. падеж
>   "{{ count }} comment_2": "{{ count }} комментариев" // мн. число, род. падеж
>   // ...
> }
> ```
> Документация: [множественное число](https://www.i18next.com/translation-function/plurals#languages-with-multiple-plurals) в [i18next](https://www.i18next.com) с [JSON-форматом версии 3](https://www.i18next.com/misc/json-format#i18next-json-v3)


### Быстрый старт

1. Клонирование репозитория с подмодулем:
    ```sh
    git clone --recurse-submodules git@github.com:flameshikari/outline-ru.git
    ```

2. Пулл изменений в подмодуле и переключение на последний доступный тег:
    ```sh
    git submodule foreach 'git pull --rebase --tags && git checkout v1.7.1'
    ```

3. Запуск контейнеров:
    ```sh
    docker compose up -d --build
    ```
    Веб-интерфейс Outline будет доступен по [этой ссылке](http://localhost:10240); входить с помощью OpenID Connect под логином/паролем `outline`.

4. Формирование временного файла с помощью [translation/merge.py](./translation/merge.py):
    ```sh
    python translation/merge.py
    ```
    После можно приступить к переводу сфомированного временного файла. После перевода временного файла скопируйте его в файл русского перевода. Любые изменения в русском переводе обновят [открытую веб-страницу](http://localhost:10240) через пару секунд.
