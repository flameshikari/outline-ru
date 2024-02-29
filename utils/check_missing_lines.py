import json
import os
import urllib.request

workdir = os.path.abspath(os.path.dirname(__file__))

def workdir(path):
    basepath = os.path.abspath(os.path.dirname(__file__))
    abspath = os.path.abspath(basepath + '/' + path)
    return abspath

en_json_path = 'https://github.com/outline/outline/raw/main/shared/i18n/locales/en_US/translation.json'
ru_json_path = workdir('../shared/i18n/locales/ru_RU/translation.json')
merged_json_path = workdir('merged.json')

missing_lines = {}
merged_json = {}

with urllib.request.urlopen(en_json_path) as response:
    en_json = json.loads(response.read().decode('utf-8'))

with open(ru_json_path) as f:
    ru_json = json.load(f)

for key, value in en_json.items():
    if key in ru_json.keys():
        merged_json[key] = ru_json[key]
    else:
        missing_lines[key] = value
        merged_json[key] = en_json[key]

if missing_lines:
    print('Найдены непереведенные строки:')
    for key, value in missing_lines.items():
        print(f'> {key}')
    with open(merged_json_path, 'w') as target:
        obj = json.dumps(merged_json, indent=2, ensure_ascii=False, sort_keys=True)
        target.write(obj)
    exit(1)
else:
    print('Все строки переведены!')
    exit(0)
