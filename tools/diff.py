#!/usr/bin/env python

import json
import os

def resolve(path):
    basepath = os.path.abspath(os.path.dirname(__file__))
    abspath = os.path.abspath(basepath + '/' + path)
    return abspath


en_json_path = resolve('../outline/shared/i18n/locales/en_US/translation.json')
ru_json_path = resolve('./translation.json')

out_json_name = 'translation.tmp.json'
out_json_path = resolve(out_json_name)

translated_lines = {}
untranslated_lines = {}
exception_lines = {}

placeholder = '[NOT TRANSLATED]'

with open(en_json_path) as target:
    en_json = json.load(target)

with open(ru_json_path) as target:
    ru_json = json.load(target)

for key, value in en_json.items():
    
    # skip x_plural strings
    if key.endswith('_plural'):
        continue

    # keep translated strings
    elif key in ru_json.keys():
        translated_lines[key] = ru_json[key]

    # process plurals
    elif key in en_json.keys() and f'{key}_plural' in en_json.keys():
        for i in range(0, 3):
            plural = f'{key}_{i}'
            if plural in ru_json.keys():
                translated_lines[plural] = ru_json[plural]
            else:
                untranslated_lines[plural] = placeholder

    else:
        untranslated_lines[key] = placeholder

for key, value in ru_json.items():
    if key == value:
        exception_lines[key] = value

out_json = {**translated_lines, **untranslated_lines}

if (exception_lines):
    print('Исключения:')
    print(json.dumps(exception_lines, indent=2, ensure_ascii=False))
    print()

if (untranslated_lines):
    print('Непереведённые строки:')
    print(json.dumps(untranslated_lines, indent=2, ensure_ascii=False))
    print()

with open(out_json_path, 'w') as target:
    obj = json.dumps(out_json, indent=2, ensure_ascii=False)
    target.write(obj + '\n')
    print(f'Переведенные и непереведенные строки смержены в {out_json_name}')
