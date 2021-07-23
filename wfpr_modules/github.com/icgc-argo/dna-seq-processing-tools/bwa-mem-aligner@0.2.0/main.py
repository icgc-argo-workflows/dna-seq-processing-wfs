#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
  Copyright (C) 2021,  icgc-argo

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  Authors:
    Junjun Zhang
    Linda Xiang
"""

import subprocess
import argparse
from multiprocessing import cpu_count
import sys
import os
import json
import hashlib


def get_read_group_info(metadata_file, rg_id_in_bam, lane_bam_name):
    if metadata_file and metadata_file != 'NO_FILE':
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
    else:
        return {}

    # example lane_bam_name: TEST-PR.DO250122.SA610149.C0HVY.2.2adf885152f5f6d41d5193bd01164372.lane.bam
    md5sum_from_filename = lane_bam_name.split('.')[-3]

    read_group = {}
    for rg in metadata['read_groups']:
        rg_id_in_bam_from_metadata = rg.get("read_group_id_in_bam") if rg.get("read_group_id_in_bam") else rg.get("submitter_read_group_id")
        if rg_id_in_bam != rg_id_in_bam_from_metadata:
            continue

        seq_file_name = rg.get("file_r1")
        original_bam_name = seq_file_name if seq_file_name.endswith('.bam') else ''
        md5sum_from_metadata = hashlib.md5(("%s %s" % (original_bam_name, rg_id_in_bam)).encode('utf-8')).hexdigest()

        if md5sum_from_metadata == md5sum_from_filename:
            read_group = rg
            break

    if not read_group:
        sys.exit("Error: unable to find read group info for rg_id_in_bam '%s' from BAM '%s' in the supplied metadata" %
                 (rg_id_in_bam, lane_bam_name))

    experiment = metadata['experiment']
    if 'library_strategy' in experiment:
        experimental_strategy = experiment.pop('library_strategy')
        experiment['experimental_strategy'] = experimental_strategy

    read_group_info = {
        'ID': read_group['submitter_read_group_id'],
        'SM': metadata['samples'][0]['sampleId'],
        'LB': read_group['library_name'],
        'PU': read_group['platform_unit']
    }

    if read_group.get('insert_size'):
        read_group_info.update({'PI': read_group['insert_size']})
    if read_group.get('sample_barcode'):
        read_group_info.update({'BC': read_group['sample_barcode']})
    if experiment.get('sequencing_center'):
        read_group_info.update({'CN': experiment['sequencing_center']})
    if experiment.get('platform'):
        read_group_info.update({'PL': experiment['platform']})
    if experiment.get('platform_model'):
        read_group_info.update({'PM': experiment['platform_model']})
    if experiment.get('sequencing_date'):
        read_group_info.update({'DT': experiment['sequencing_date']})

    description = '|'.join([
                                experiment['experimental_strategy'],
                                metadata['studyId'],
                                metadata['samples'][0]['specimenId'],
                                metadata['samples'][0]['donor']['donorId'],
                                metadata['samples'][0]['specimen']['specimenType'],
                                metadata['samples'][0]['specimen']['tumourNormalDesignation']
                            ])

    read_group_info.update({'DS': description})

    return read_group_info


def main():
    """ Main program """
    parser = argparse.ArgumentParser(description='BWA alignment')
    parser.add_argument('-i','--input-bam', dest='input_bam', type=str,
                        help='Input bam file', required=True)
    parser.add_argument('-r','--ref-genome', dest='ref_genome', type=str,
                        help='Reference genome file (eg, .fa.gz), make sure BWA index files '
                             '(eg. .alt, .ann, .bwt etc) are all present at the same location', required=True)
    parser.add_argument('-o','--aligned_lane_prefix', dest='aligned_lane_prefix', type=str,
                        help='Output aligned lane bam file prefix', required=True)
    parser.add_argument('-t','--tempdir', dest='tempdir', type=str, default='.',
                        help='Directory to keep temporary files')
    parser.add_argument("-n", "--cpus", type=int, default=cpu_count())
    parser.add_argument('-m','--metadata', dest='metadata', type=str,
                        help='Sequencing experiment metadata')
    args = parser.parse_args()

    if not os.path.isdir(args.tempdir):
        sys.exit('Error: specified tempdir %s does not exist!' % args.tempdir)

    # retrieve the @RG from BAM header
    try:
        header = subprocess.check_output(['samtools', 'view', '-H', args.input_bam])

    except Exception as e:
        sys.exit('\n%s: Retrieve BAM header failed: %s' % (e, args.input_bam))

    # get @RG
    header_array = header.decode('utf-8').rstrip().split('\n')
    rg_array = []
    for line in header_array:
        if not line.startswith("@RG"): continue
        rg_array.append(line.rstrip().replace('\t', '\\t'))

    if not len(rg_array) == 1: sys.exit('\n%s: The input bam should only contain one readgroup ID: %s' % args.input_bam)

    # get rg_id from BAM header
    rg_id_in_bam = ':'.join([ kv for kv in rg_array[0].split('\\t') if kv.startswith('ID:') ][0].split(':')[1:])

    if len(rg_id_in_bam) == 0:  # should never happen, but still need to make sure
        sys.exit('Error: no read group ID defined the in BAM: %s' % args.input_bam)

    # retrieve read_group_info from metadata
    read_group_info = get_read_group_info(args.metadata, rg_id_in_bam, os.path.basename(args.input_bam))

    if read_group_info:  # use what's in metadata instead of in BAM header
        rg_kv = [ '@RG' ] + [ '%s:%s' % (k, v) for k, v in read_group_info.items() ]
        rg_array = [ '\\t'.join(rg_kv) ]

    sort_qname = 'samtools sort -l 0 -n -O BAM -T %s/tmp1 -@ %s %s ' % (args.tempdir, str(args.cpus), args.input_bam)

    # discarding supplementary and secondary reads.
    bam2fastq = ' samtools fastq -O -F 0x900 -@ %s - ' % (str(args.cpus))

    #Command with header
    alignment = ' bwa mem -K 100000000 -Y -T 0 -t %s -p -R "%s" %s - ' % (str(args.cpus), rg_array[0], args.ref_genome)

    # Sort the SAM output by coordinate from bwa and save to BAM file
    sort_coordinate = ' samtools sort -O BAM -T %s/tmp2 -@ %s -o %s /dev/stdin' % (args.tempdir, str(args.cpus), args.aligned_lane_prefix + "." + os.path.basename(args.input_bam))

    cmd = ' | '.join([sort_qname, bam2fastq, alignment, sort_coordinate])

    try:
        subprocess.run([cmd], shell=True, check=True)

    except Exception as e:
        sys.exit('\nExecution failed: %s' % e)


if __name__ == "__main__":
    main()
