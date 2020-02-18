#!/usr/bin/env nextflow

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

params.exp_tsv = ""
params.rg_tsv = ""
params.file_tsv = ""
params.token_file = "/home/ubuntu/.access_token"

include SequencingDataSubmission from "../main" params(params)


workflow {
  main:
    SequencingDataSubmission(
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv)
    )

  publish:
    SequencingDataSubmission.out.metadata to: "outdir", overwrite: true
    SequencingDataSubmission.out.files_to_submit to: "outdir", overwrite: true
    SequencingDataSubmission.out.seq_expriment_payload to: "outdir", overwrite: true
    SequencingDataSubmission.out.seq_expriment_analysis to: "outdir", overwrite: true
}
