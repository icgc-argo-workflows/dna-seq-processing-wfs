#!/usr/bin/env python3

"""
 Copyright (c) 2019, Ontario Institute for Cancer Research (OICR).

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published
 by the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program. If not, see <https://www.gnu.org/licenses/>.

 Authors:
    Junjun Zhang
    Linda Xiang

 """

import os
import sys
import re
import json
from argparse import ArgumentParser
import hashlib
import uuid
import subprocess
import copy
from datetime import date
import tarfile

workflow_full_name = {
    'dna-seq-alignment': 'DNA Seq Alignment'
}

def calculate_size(file_path):
    return os.stat(file_path).st_size


def calculate_md5(file_path):
    md5 = hashlib.md5()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            md5.update(chunk)
    return md5.hexdigest()


def get_aligned_seq_basename(qc_files):
    # get aligned bam/cram basename from '*.wgs.grch38.(cram|bam).qc_metrics.tgz'
    # or '*.wgs.grch38.(cram|bam).oxog_metrics.tgz'
    for f in qc_files:
        m = re.match(r'(.+?\.(cram|bam))\.(qc_metrics|oxog_metrics)\.tgz$', f)
        if m: return(m.group(1))

    sys.exit('Error: missing DNA alignment QC metrics or oxog metrics file with patten: *.{bam,cram}.{qc_metrics, oxog_metrics}.tgz')


def insert_filename_friendly_rg_id(metadata):
    filename_friendly_rg_ids = set()

    # let's loop it two times, first for the rg id actually doesn't need to convert
    for rg in metadata['read_groups']:
        submitter_read_group_id = rg['submitter_read_group_id']
        filename_friendly_rg_id = "".join([ c if re.match(r"[a-zA-Z0-9\.\-_]", c) else "_" for c in submitter_read_group_id ])

        if filename_friendly_rg_id == submitter_read_group_id:  # no change, safe to use
            rg['filename_friendly_rg_id'] = filename_friendly_rg_id
            filename_friendly_rg_ids.add(filename_friendly_rg_id)

    for rg in metadata['read_groups']:
        submitter_read_group_id = rg['submitter_read_group_id']
        filename_friendly_rg_id = "".join([ c if re.match(r"[a-zA-Z0-9\.\-_]", c) else "_" for c in submitter_read_group_id ])

        if filename_friendly_rg_id == submitter_read_group_id:  # no change, already covered
            continue

        if filename_friendly_rg_id in filename_friendly_rg_ids:  # the converted new friendly ID conflicts with existing one
            for i in range(len(metadata['read_groups'])):
                if not '%s_%s' % (filename_friendly_rg_id, i+1) in filename_friendly_rg_ids:
                    filename_friendly_rg_id += '_%s' % str(i+1)
                    break

        rg['filename_friendly_rg_id'] = filename_friendly_rg_id
        filename_friendly_rg_ids.add(filename_friendly_rg_id)


def get_rg_id_from_ubam_qc(tar, metadata):
    tar_basename = os.path.basename(tar)  # TEST-PR.DO250122.SA610149.D0RE2_1_.6cae87bf9f05cdfaa4a26f2da625f3b2.lane.bam.ubam_qc_metrics.tgz
    md5sum_from_filename = tar_basename.split('.')[-5]
    if not re.match(r'^[a-f0-9]{32}$', md5sum_from_filename):
        sys.exit('Error: ubam naming not expected %s' % tar_basename)

    for rg in metadata.get("read_groups"):
        rg_id_in_bam = rg.get("read_group_id_in_bam") if rg.get("read_group_id_in_bam") else rg.get("submitter_read_group_id")
        seq_file_name = rg.get("file_r1")
        bam_name = seq_file_name if seq_file_name.endswith('.bam') else ''
        md5sum_from_metadata = hashlib.md5(("%s %s" % (bam_name, rg_id_in_bam)).encode('utf-8')).hexdigest()
        if md5sum_from_metadata == md5sum_from_filename:
            return rg.get("filename_friendly_rg_id")

    # up to this point no match found, then something wrong
    sys.exit('Error: unable to match ubam qc metric tar "%s" to read group id' % tar_basename)


def get_dupmetrics(file_to_upload):
    library = []
    with tarfile.open(file_to_upload, 'r') as tar:
        for member in tar.getmembers():
            if member.name.endswith('.duplicates_metrics.txt'):
                f = tar.extractfile(member)
                cols_name = []
                for r in f:
                    row = r.decode('utf-8')                    
                    if row.startswith('LIBRARY'): 
                        cols_name = row.strip().split('\t')
                        continue
                    if cols_name:
                        if not row.strip(): break
                        metric = {}
                        cols = row.strip().split('\t')
                        for n, c in zip(cols_name, cols):
                            if n == "LIBRARY": metric.update({n: c})
                            elif '.' in c or 'e' in c: metric.update({n: float(c)}) 
                            else: metric.update({n: int(c)})
                        library.append(metric)      
    return library

def get_files_info(file_to_upload, seq_experiment_analysis_dict):
    file_info = {
        'fileName': os.path.basename(file_to_upload),
        'fileType': file_to_upload.split(".")[-1].upper(),
        'fileSize': calculate_size(file_to_upload),
        'fileMd5sum': calculate_md5(file_to_upload),
        'fileAccess': 'controlled',
        'info': {
            'data_category': 'Quality Control Metrics',
            'data_subtypes': None,
            'files_in_tgz': []
        }
    }

    if re.match(r'.+?\.ubam_qc_metrics\.tgz$', file_to_upload):
        file_info.update({'dataType': 'Sequencing QC'})
        file_info['info']['data_subtypes'] = ['Read Group Metrics']
        file_info['info'].update({'description': 'Read group level QC metrics generated by Picard CollectQualityYieldMetrics.'})
        file_info['info'].update({'analysis_tools': ['Picard:CollectQualityYieldMetrics']})
    elif re.match(r'.+?\.(cram|bam)\.qc_metrics\.tgz$', file_to_upload):
        file_info.update({'dataType': 'Aligned Reads QC'})
        file_info['info']['data_subtypes'] = ['Alignment Metrics']
        file_info['info'].update({'description': 'Alignment QC metrics generated by Samtools stats.'})
        file_info['info'].update({'analysis_tools': ['Samtools:stats']})
    elif re.match(r'.+?\.duplicates_metrics\.tgz$', file_to_upload):
        file_info.update({'dataType': 'Aligned Reads QC'})
        file_info['info']['data_subtypes'] = ['Duplicates Metrics']
        file_info['info'].update({'description': 'Duplicates metrics generated by biobambam2 bammarkduplicates2.'})
        file_info['info'].update({'analysis_tools': ['biobambam2:bammarkduplicates2']})
    elif re.match(r'.+?\.oxog_metrics\.tgz$', file_to_upload):
        file_info.update({'dataType': 'Aligned Reads QC'})
        file_info['info']['data_subtypes'] = ['OxoG Metrics']
        file_info['info'].update({'description': 'OxoG metrics generated by GATK CollectOxoGMetrics.'})
        file_info['info'].update({'analysis_tools': ['GATK:CollectOxoGMetrics']})
    else:
        sys.exit('Error: unknown QC metrics file: %s' % file_to_upload)

    extra_info = {}
    with tarfile.open(file_to_upload, 'r') as tar:
        for member in tar.getmembers():
            if member.name.endswith('.extra_info.json'):
                f = tar.extractfile(member)
                extra_info = json.load(f)
            else:
                file_info['info']['files_in_tgz'].append(os.path.basename(member.name))

    # retrieve duplicates metrics from the file
    if file_info['info']['data_subtypes'][0] == 'Duplicates Metrics':
        extra_info['libraries'] = get_dupmetrics(file_to_upload)

    if file_info['info']['data_subtypes'][0] == 'Read Group Metrics':
        map_to_new_id = {}
        for rg in seq_experiment_analysis_dict['read_groups']:  # build map read_group_id_in_bam to submitter_read_group_id
            if rg.get('read_group_id_in_bam'):
                map_to_new_id[rg['read_group_id_in_bam']] = rg['submitter_read_group_id']
            else:
                map_to_new_id[rg['submitter_read_group_id']] = rg['submitter_read_group_id']       
        extra_info['read_group_id'] = map_to_new_id[extra_info['read_group_id']]

    extra_info.pop('tool')
    if extra_info:
        file_info['info'].update({'metrics': extra_info})

    return file_info


def get_sample_info(sample_list):
    samples = copy.deepcopy(sample_list)
    for sample in samples:
        for item in ['info', 'sampleId', 'specimenId', 'donorId', 'studyId']:
            sample.pop(item, None)
            sample['specimen'].pop(item, None)
            sample['donor'].pop(item, None)

    return samples


def main(args):
    with open(args.seq_experiment_analysis, 'r') as f:
        seq_experiment_analysis_dict = json.load(f)

    payload = {
        'analysisType': {
            'name': 'qc_metrics'
        },
        'studyId': seq_experiment_analysis_dict.get('studyId'),
        'info': {},
        'workflow': {
            'workflow_name': workflow_full_name.get(args.wf_name, args.wf_name),
            'workflow_version': args.wf_version,
            'genome_build': 'GRCh38_hla_decoy_ebv',
            'run_id': args.wf_run,
            'session_id': args.wf_session,
            'inputs': [
                {
                    'analysis_type': 'sequencing_experiment',
                    'input_analysis_id': seq_experiment_analysis_dict.get('analysisId')
                }
            ]
        },
        'files': [],
        'experiment': seq_experiment_analysis_dict.get('experiment'),
        'samples': get_sample_info(seq_experiment_analysis_dict.get('samples'))
    }

    # pass `info` dict from seq_experiment payload to new payload
    if 'info' in seq_experiment_analysis_dict and isinstance(seq_experiment_analysis_dict['info'], dict):
        payload['info'] = seq_experiment_analysis_dict['info']
    else:
        payload.pop('info')

    if 'library_strategy' in payload['experiment']:
        experimental_strategy = payload['experiment'].pop('library_strategy')
        payload['experiment']['experimental_strategy'] = experimental_strategy

    new_dir = 'out'
    try:
        os.mkdir(new_dir)
    except FileExistsError:
        pass

    insert_filename_friendly_rg_id(seq_experiment_analysis_dict)

    aligned_seq_basename = get_aligned_seq_basename(args.qc_files)

    # get file of the payload
    for f in sorted(args.qc_files):
        # renmame duplicates_metrics file to have the same base name as the aligned seq
        if re.match(r'.+\.duplicates_metrics\.tgz$', f):
            new_name = '%s.duplicates_metrics.tgz' % aligned_seq_basename
            dst = os.path.join(os.getcwd(), new_name)
            os.symlink(os.path.abspath(f), dst)
            f = new_name

        # renmame ubam_qc_metrics file to have the same base name as the aligned seq
        if re.match(r'.+?\.lane\.bam\.ubam_qc_metrics\.tgz$', f):
            rg_id = get_rg_id_from_ubam_qc(f, seq_experiment_analysis_dict)
            new_name = '%s.%s.ubam_qc_metrics.tgz' % (re.sub(r'\.aln\.(cram|bam)$', '', aligned_seq_basename), rg_id)
            dst = os.path.join(os.getcwd(), new_name)
            os.symlink(os.path.abspath(f), dst)
            f = new_name

        payload['files'].append(get_files_info(f, seq_experiment_analysis_dict))

        dst = os.path.join(os.getcwd(), new_dir, f)
        os.symlink(os.path.abspath(f), dst)

    with open("%s.dna_seq_qc.payload.json" % str(uuid.uuid4()), 'w') as f:
        f.write(json.dumps(payload, indent=2))


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-a", "--seq-experiment-analysis", dest="seq_experiment_analysis", required=True,
                        help="Input analysis for sequencing experiment", type=str)
    parser.add_argument("-f", "--qc-files", dest="qc_files", type=str, required=True,
                        nargs="+", help="All QC TGZ files")
    parser.add_argument("-w", "--wf-name", dest="wf_name", required=True, help="Workflow name")
    parser.add_argument("-r", "--wf-run", dest="wf_run", required=True, help="workflow run ID")
    parser.add_argument("-s", "--wf-session", dest="wf_session", required=True, help="workflow session ID")
    parser.add_argument("-v", "--wf-version", dest="wf_version", required=True, help="Workflow version")
    args = parser.parse_args()

    main(args)
