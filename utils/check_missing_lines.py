import json
import os

def workdir(path):
    basepath = os.path.abspath(os.path.dirname(__file__))
    abspath = os.path.abspath(basepath + '/' + path)
    return abspath

en_json_path = workdir('../src/shared/i18n/locales/en_US/translation.json')
ru_json_path = workdir('../shared/i18n/locales/ru_RU/translation.json')
merged_json_path = workdir('./merged.json')

translated_lines = {}
untranslated_lines = {}

exceptions = [
    'Google Analytics',
    'HTML',
    'Markdown',
    'PDF',
    'URL'
]

with open(en_json_path) as target:
    en_json = json.load(target)

with open(ru_json_path) as target:
    ru_json = json.load(target)

for key, value in en_json.items():
    if key in exceptions:
        translated_lines[key] = en_json[key]
    if key in ru_json.keys():
        translated_lines[key] = ru_json[key]
    else:
        untranslated_lines[key] = en_json[key]

merged_json = {**translated_lines, **untranslated_lines}

print(json.dumps(untranslated_lines, indent=2, ensure_ascii=False))

with open(merged_json_path, 'w') as target:
    obj = json.dumps(merged_json, indent=2, ensure_ascii=False)
    target.write(obj)
