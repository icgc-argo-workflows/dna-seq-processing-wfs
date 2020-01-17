#!/usr/bin/env python

import sys
import argparse
import os
import re
import requests

PIPELINE_ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCAL_MODULE_DIR = os.path.join(PIPELINE_ROOT_DIR, 'modules')

# path pattern can be modified to cover for other remote repo servers, such as gitlab and bitbucket
NF_REMOTE_INCLUDE_PATTERN = r'^\s*include[\s\w]+?(\'|")\.{1,2}\/modules\/(raw.githubusercontent.com\/\S+)(\'|")'


def collect_included_remote_modules(nf_file):
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


def search_for_remote_module_includes():
  remote_module_paths = set([])
  for root, _, files in os.walk(PIPELINE_ROOT_DIR):
    if root.startswith(LOCAL_MODULE_DIR) or os.path.basename(root).startswith('.'):
      continue

    for file in files:
      if not os.path.basename(file).endswith('.nf'):
        continue

      remote_module_paths = remote_module_paths | collect_included_remote_modules(os.path.join(root, file))

  return remote_module_paths


def install_modules(remote_module_paths):
  for p in remote_module_paths:
    url = 'https://%s' % p
    local_path = os.path.join(LOCAL_MODULE_DIR, p)

    try:
      r = requests.get(url, allow_redirects=True)
    except:
      sys.exit('Error: unable to fetch remote module file at: %s' % url)

    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    open(local_path, 'wb').write(r.content)


def clean_up_unused_modules(remote_module_paths):
  # to be implemented
  pass


def main():
  parser = argparse.ArgumentParser(description='Synchronize local Nextflow modules from remote Git repositories')
  parser.add_argument('-c','--clean-up', dest='clean_up', action='store_true',
                      help='Remove unused local modules')

  args = parser.parse_args()

  remote_module_paths = search_for_remote_module_includes()

  install_modules(remote_module_paths)

  if args.clean_up:
    clean_up_unused_modules(remote_module_paths)


if __name__ == '__main__':
  main()
