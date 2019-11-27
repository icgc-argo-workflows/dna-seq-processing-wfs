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

params.aligned_lane_bams = "tests/input/grch38-aligned.*.lane.bam"
params.ref_genome = "tests/reference/tiny-grch38-chr11-530001-537000.fa"
params.cpus = -1  // optional input param
params.aligned_basename = "HCC1143.3.20190726.wgs.grch38"
params.markdup = true
params.output_format = 'cram'
params.lossy = false

def getFaiFile(main_file){  //this is kind of like CWL's secondary files
  return main_file + '.fai'
}

process bamMergeSortMarkdup {
  container 'quay.io/icgc-argo/bam-merge-sort-markdup:bam-merge-sort-markdup.0.1.4.1'

  input:
    path aligned_lane_bams
    path ref_genome
    path ref_genome_fai
    val cpus
    val aligned_basename
    val markdup
    val output_format
    val lossy

  output:
    path "${aligned_basename}*.{bam,cram}", emit: merged_seq
    path "${aligned_basename}*.{bam.bai,cram.crai}", emit: merged_seq_idx
    path "${aligned_basename}.duplicates-metrics.txt", emit: duplicates_metrics

  script:
    arg_cpus = cpus > 0 ? "-n ${cpus}" : ""
    arg_markdup = markdup ? "-d" : ""
    arg_lossy = lossy ? "-l" : ""
    """
    bam-merge-sort-markdup.py \
      -i ${aligned_lane_bams} \
      -r ${ref_genome} ${arg_cpus} \
      -b ${aligned_basename} ${arg_markdup} \
      -o ${output_format} ${arg_lossy}
    """
}
