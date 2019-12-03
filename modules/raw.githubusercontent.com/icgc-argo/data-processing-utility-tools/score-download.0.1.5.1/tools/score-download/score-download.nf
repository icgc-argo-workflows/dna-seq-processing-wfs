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

params.seq_files = "NO_FILE"
params.file_tsv = "NO_FILE"
params.repository = ""
params.token_file = "NO_FILE"


process scoreDownload {
  container "quay.io/icgc-argo/score-download:score-download.0.1.5.1"

  input:
    path seq_files
    path file_tsv
    val repository
    path token_file

  output:
    //path "*.{bam,cram,fastq,fq,fastq.gz,fq.gz,fastq.bz2,fq.bz2,vcf.gz}", emit: download_file
    //path "*.@(bam|cram|fastq|fq|fastq.gz|fq.gz|fastq.bz2|fq.bz2|vcf.gz)", emit: download_file
    path "*", emit: download_file
    path "*.@(bam.bai|cram.crai|vcf.gz.tbi)" optional true
    //path "*.bam.bai" optional true

  script:
    args_seq_files = seq_files.name != "NO_FILE" ? "-s ${seq_files}" : ""
    args_file_tsv = file_tsv.name != "NO_FILE" ? "-f ${file_tsv}" : ""
    args_repository = repository != "" ? "-r ${repository}" : ""
    args_token_file = token_file.name != "NO_FILE" ? "-t ${token_file}" : ""

    if( seq_files.name != "NO_FILE" )
      """
      mv ${seq_files} cp.${seq_files} && ln -s cp.${seq_files} ${seq_files}
      """
    else
      """
      score-download.py ${args_seq_files} ${args_file_tsv} ${args_repository} ${args_token_file}
      """
}
