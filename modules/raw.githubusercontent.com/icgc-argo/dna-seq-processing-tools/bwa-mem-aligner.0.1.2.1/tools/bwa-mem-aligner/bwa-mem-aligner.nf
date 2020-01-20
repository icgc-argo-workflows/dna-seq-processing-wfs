#!/bin/bash nextflow

/*
 * Copyright (c) 2019, Ontario Institute for Cancer Research (OICR).
 *                                                                                                               
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * author Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2

params.input_bam = "tests/input/?????_?.lane.bam"
params.cpus = -1  // optional input param
params.aligned_lane_prefix = 'grch38-aligned'
params.ref_genome_gz = "tests/reference/tiny-grch38-chr11-530001-537000.fa.gz"

def getBwaSecondaryFiles(main_file){  //this is kind of like CWL's secondary files
  def all_files = []
  for (ext in ['.fai', '.sa', '.bwt', '.ann', '.amb', '.pac', '.alt']) {
    all_files.add(main_file + ext)
  }
  return all_files
}

process bwaMemAligner {
  container 'quay.io/icgc-argo/bwa-mem-aligner:bwa-mem-aligner.0.1.2'

  input:
    path input_bam
    val aligned_lane_prefix
    val cpus
    path ref_genome_gz
    path ref_genome_gz_secondary_files

  output:
    path "${aligned_lane_prefix}.${input_bam.baseName}.bam", emit: aligned_bam

  script:
    arg_cpus = cpus > 0 ? "-n ${cpus}" : ""
    """
    bwa-mem-aligner.py -i ${input_bam} -r ${ref_genome_gz} -o ${aligned_lane_prefix} ${arg_cpus}
    """
}
