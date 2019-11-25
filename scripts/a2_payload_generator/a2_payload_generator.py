#!/usr/bin/env python3
 
import os
import json
import hashlib
import argparse

# Get input
parser = argparse.ArgumentParser(description='Generates analysis type A2 from the provided template, A1 payload, and the files to be uploaded')

parser.add_argument('template', type=argparse.FileType('r'), nargs='?',
                   help='template json file')

parser.add_argument('a1_payload', type=argparse.FileType('r'), nargs='?',
                   help='A1 payload json file')
                   
parser.add_argument('upload_files', nargs='+',
                   help='Files to generate metadata for')

parser.add_argument('--output', default='a2_payload.json', nargs='?',
                   help='Output file name, defaults to %(default)s')

args = parser.parse_args()

def generate_file_meta(upload_file):
    return {
        'fileName': os.path.basename(upload_file),
        'fileSize': os.path.getsize(upload_file),
        'fileMd5sum': generateMD5Hash(upload_file),
        'fileType': 'BAM' if os.path.splitext(upload_file)[1] == '.cram' else 'BAI',
        'fileAccess': 'open'
    }

def generateMD5Hash(file_path):
    md5_hash = hashlib.md5()
    with open(file_path, 'rb') as f:
        # Read and update hash in chunks of 4K
        for byte_block in iter(lambda: f.read(4096), b""):
            md5_hash.update(byte_block)
        return md5_hash.hexdigest()

payload_json = json.load(args.template)
a1_payload_json = json.load(args.a1_payload)

# Transfer data from A1 to A2
for key in ['sample', 'study', 'experiment']:
    payload_json[key] = a1_payload_json[key]

# Build file data
payload_json['file'] = []

for upload_file in args.upload_files:
    payload_json['file'].append(generate_file_meta(upload_file))

# Write to file
with open(args.output, 'w') as payload_file:
    json.dump(payload_json, payload_file)
