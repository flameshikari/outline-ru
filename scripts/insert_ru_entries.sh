#!/usr/bin/env bash

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

cat $CWD/src/shared/utils/date.ts | \
    sed '/^  pl,/a\ \ ru,' | \
    sed '/^  pl_PL: pl,/a\ \ ru_RU: ru,' \
    > $CWD/shared/utils/date.ts

cat $CWD/src/shared/i18n/index.ts | \
    sed '/^export const languageOptions = \[/a\ \ {\n    label: "Русский (Russian)",\n    value: "ru_RU",\n  },' \
    > $CWD/shared/i18n/index.ts
