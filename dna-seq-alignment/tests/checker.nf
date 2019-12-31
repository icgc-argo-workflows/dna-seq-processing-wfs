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
 */

nextflow.preview.dsl=2

// params for starting from migrating legacy ICGC data
params.exp_tsv = ""
params.rg_tsv = ""
params.file_tsv = ""
params.token_file_legacy_data = "/home/ubuntu/access_token"

// params for starting from submitted ARGO data
params.seq_expriment_analysis_id = ""
params.program_id = ""
params.token_file = "/home/ubuntu/.access_token"

// params for preprocessing: bam to ubam
params.reads_max_discard_fraction = 0.08

include "../main" params(params)


workflow {
  main:
    DnaSeqAlignmentWf(
      params.seq_expriment_analysis_id,
      params.exp_tsv,
      params.rg_tsv,
      params.file_tsv,
      params.reads_max_discard_fraction
    )

  publish:
    DnaSeqAlignmentWf.out.seq_expriment_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.alignment_files to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.dna_seq_alignment_analysis to: "outdir", overwrite: true
}
