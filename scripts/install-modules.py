#!/usr/bin/env python3

import sys
import argparse
import os
import re
import requests

PIPELINE_ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMPORTED_MODULE_DIR = os.path.join(PIPELINE_ROOT_DIR, 'modules')

# path pattern can be modified to cover for other remote repo servers, such as gitlab and bitbucket
NF_REMOTE_INCLUDE_PATTERN = r'^\s*include[\s\w\d_;\{\}]+?(\'|")\.{1,2}\/modules\/(raw.githubusercontent.com\/\S+)(\'|")'


def extract_remote_module_path_from_include_statements(nf_file):
  remote_module_paths = set([])
  with open(nf_file, 'r') as f:
    for l in f:
      m = re.search(NF_REMOTE_INCLUDE_PATTERN, l)
      if m:
        path = m.group(2)
        if not path.endswith('.nf'):
          path = path + '.nf'
        remote_module_paths.add(path)

  return remote_module_paths


def collect_remote_module_paths():
  remote_module_paths = set([])
  for root, dirs, files in os.walk(PIPELINE_ROOT_DIR):
    # skip file starts with '.'
    files = [f for f in files if not f[0] == '.']

    # skip folder starts with '.' and local installation of nf modules
    dirs[:] = [d for d in dirs if not (d[0] == '.' or (root == PIPELINE_ROOT_DIR and d == 'modules'))]

    for file in files:
      if not os.path.basename(file).endswith('.nf'):
        continue

      remote_module_paths = remote_module_paths | extract_remote_module_path_from_include_statements(os.path.join(root, file))

  return remote_module_paths


def install_modules(remote_module_paths):
  for p in remote_module_paths:
    url = 'https://%s' % p
    local_path = os.path.join(IMPORTED_MODULE_DIR, p)

    try:
      r = requests.get(url, allow_redirects=True)
    except:
      sys.exit('Error: unable to fetch remote module file at: %s' % url)

    if r.status_code != 200:
      sys.exit('Error: unable to download remote file at: %s' % url)

    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    open(local_path, 'wb').write(r.content)
    print("Installed: %s" % local_path)


def clean_up_unused_modules(remote_module_paths):
  for root, _, files in os.walk(IMPORTED_MODULE_DIR):
    for file in files:
      if not os.path.basename(file).endswith('.nf'):
        continue

      relative_root = root.replace(IMPORTED_MODULE_DIR + os.sep, '')

      if os.path.join(relative_root, file) not in remote_module_paths:
        os.remove(os.path.join(root, file))
        print('Deleted unused module file: %s' % os.path.join(root, file))


def main():
  parser = argparse.ArgumentParser(description='Synchronize local Nextflow modules from remote Git repositories')
  parser.add_argument('-c','--clean-up', dest='clean_up', action='store_true',
                      help='Remove unused local modules')

  args = parser.parse_args()

  remote_module_paths = collect_remote_module_paths()

  install_modules(remote_module_paths)

  if args.clean_up:
    clean_up_unused_modules(remote_module_paths)


if __name__ == '__main__':
  main()
