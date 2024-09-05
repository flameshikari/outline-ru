#!/usr/bin/env python

import json
import os

def workdir(path):
    basepath = os.path.abspath(os.path.dirname(__file__))
    abspath = os.path.abspath(basepath + '/' + path)
    return abspath

en_json_path = workdir('../src/shared/i18n/locales/en_US/translation.json')
ru_json_path = workdir('../shared/i18n/locales/ru_RU/translation.json')
out_json_path = workdir('./translation.json')

translated_lines = {}
untranslated_lines = {}
exception_lines = {}

with open(en_json_path) as target:
    en_json = json.load(target)

with open(ru_json_path) as target:
    ru_json = json.load(target)

for key, value in en_json.items():
    if key in ru_json.keys():
        translated_lines[key] = ru_json[key]
    else:
        untranslated_lines[key] = en_json[key]


for key, value in ru_json.items():
    if key == value:
        exception_lines[key] = value
    

out_json = {**translated_lines, **untranslated_lines}

if (exception_lines):
    print('Потенциально непереведённые строки или исключения:')
    print(json.dumps(exception_lines, indent=2, ensure_ascii=False))
    print()

if (untranslated_lines):
    print('Непереведённые строки:')
    print(json.dumps(untranslated_lines, indent=2, ensure_ascii=False))
    print()

with open(out_json_path, 'w') as target:
    obj = json.dumps(out_json, indent=2, ensure_ascii=False)
    target.write(obj + '\n')
    print('Переведенные и непереведенные строки смержены в translation.json')
