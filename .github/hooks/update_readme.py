#!/usr/bin/env python

import os
import re
import json

ignore = '0.71.0'

def resolve(path):
    basepath = os.path.abspath(os.path.dirname(__file__))
    abspath = os.path.abspath(basepath + '/' + path)
    return abspath

def get_version(path):
    with open(path, 'r') as f:
        data = json.load(f)
    return data.get('version', None)

def replace_version(path, version):
    with open(path, 'r') as file:
        content = file.read()
    pattern = re.compile(r'(\d+\.\d+\.\d+(-\w+)?)')

    check = lambda x: ignore if ignore == x.group(0) else version

    with open(path, 'w') as file:
        file.write(pattern.sub(check, content))

version = get_version(resolve('../../outline/package.json'))

replace_version(resolve('../../README.md'), version)
