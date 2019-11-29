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

params.meta_format = "tsv"
params.exp_tsv = ""
params.rg_tsv = ""
params.file_tsv = ""
params.exp_json = ""  // optional json string of exp metadata
params.seq_exp_json_name = "seq_exp.json"
params.seq_rg_json_name = "seq_rg.json"
params.seq_files = "NO_FILE"
params.repository = "collab"
//params.token_file = "/home/ubuntu/.accessToken"
//params.credentials_file ="/home/ubuntu/.aws/credentials"
params.token_file = "/Users/junjun/.access_token"
params.credentials_file ="/Users/junjun/credentials"
params.ref_genome_gz = "tests/reference/tiny-grch38-chr11-530001-537000.fa.gz"
params.ref_genome = "tests/reference/tiny-grch38-chr11-530001-537000.fa"
params.cpus_align = 1
params.cpus_mkdup = 1
params.reads_max_discard_fraction = 0.08
params.aligned_lane_prefix = "grch38-aligned"
params.markdup = true
params.lossy = false
params.aligned_seq_output_format = "cram"
params.payload_schema_version = "0.1.0-rc.2"
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"

include "./dna-seq-alignment" params(params)

workflow {
  main:
    DnaSeqAlignmentWf(
      params.meta_format,
      params.exp_tsv,
      params.rg_tsv,
      params.file_tsv,
      params.exp_json,
      params.seq_exp_json_name,
      params.seq_rg_json_name,
      params.seq_files,
      params.repository,
      params.token_file,
      params.ref_genome_gz,
      params.ref_genome,
      params.cpus_align,
      params.cpus_mkdup,
      params.reads_max_discard_fraction,
      params.aligned_lane_prefix,
      params.markdup,
      params.lossy,
      params.aligned_seq_output_format,
      params.payload_schema_version,
      params.credentials_file,
      params.endpoint_url,
      params.bucket_name,
      params.song_url,
      params.score_url
    )

  publish:
    DnaSeqAlignmentWf.out.metadata to: "outdir", mode: 'copy', overwrite: true
    DnaSeqAlignmentWf.out.seq_expriment_analysis to: "outdir", mode: 'copy', overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam_analysis to: "outdir", mode: 'copy', overwrite: true
    DnaSeqAlignmentWf.out.dna_seq_alignment_analysis to: "outdir", mode: 'copy', overwrite: true
}
