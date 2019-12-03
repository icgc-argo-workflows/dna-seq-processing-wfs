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
 * authors: Junjun Zhang <junjun.zhang@oicr.on.ca>
 *          Linda Xiang <linda.xiang@oicr.on.ca>
 */

nextflow.preview.dsl=2

params.meta_format = "tsv"
params.exp_tsv = ""
params.rg_tsv = ""
params.file_tsv = ""
params.seq_files = "NO_FILE"
params.repository = "collab"
params.token_file = "/home/ubuntu/.access_token"
params.token_file_legacy_data = "/home/ubuntu/access_token"
params.ref_genome_gz = "reference/tiny-grch38-chr11-530001-537000.fa.gz"
params.ref_genome = "reference/tiny-grch38-chr11-530001-537000.fa"
params.cpus_align = -1  // negative means use default
params.cpus_mkdup = -1  // negative means use default
params.reads_max_discard_fraction = 0.08
params.upload_ubam = false
params.aligned_lane_prefix = "grch38-aligned"
params.markdup = true
params.lossy = false
params.aligned_seq_output_format = "cram"
params.payload_schema_version = "0.1.0-rc.2"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"

include "../dna-seq-alignment" params(params)

workflow {
  main:
    DnaSeqAlignmentWf(
      params.meta_format,
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv),
      params.seq_files,
      params.repository,
      params.token_file,
      params.token_file_legacy_data,
      params.ref_genome_gz,
      params.ref_genome,
      params.cpus_align,
      params.cpus_mkdup,
      params.reads_max_discard_fraction,
      params.upload_ubam,
      params.aligned_lane_prefix,
      params.markdup,
      params.lossy,
      params.aligned_seq_output_format,
      params.payload_schema_version,
      params.song_url,
      params.score_url
    )

  publish:
    DnaSeqAlignmentWf.out.metadata to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.seq_expriment_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.dna_seq_alignment_analysis to: "outdir", overwrite: true
    //DnaSeqAlignmentWf.out.read_group_ubam to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.aligned_seq to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.aligned_seq_index to: "outdir", overwrite: true
}
