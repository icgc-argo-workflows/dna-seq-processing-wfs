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

params.meta_format = "tsv"  // tsv or json
params.exp_json = ""  // optional json string of exp metadata
params.exp_tsv = "tests/input/experiment-fq.tsv"
params.rg_tsv = "tests/input/read_group-fq.tsv"
params.file_tsv = "tests/input/file-fq.tsv"
params.seq_exp_json_name = "seq_exp-fq.json"
params.seq_rg_json_name = "seq_rg-fq.json"


process metadataValidation {
  container 'quay.io/icgc-argo/metadata-validation:metadata-validation.0.1.3.1'

  input:
    val meta_format
    val exp_json
    file exp_tsv
    file rg_tsv
    file file_tsv
    val seq_exp_json_name
    val seq_rg_json_name

  output:
    path "${seq_exp_json_name}", emit: payload
    path "${seq_rg_json_name}", emit: metadata

  script:
    args_exp_json = exp_json.length() > 0 ? "-j ${exp_json}" : ""
    """
    metadata-validation.py ${args_exp_json} \
      -m ${meta_format} \
      -e ${exp_tsv} \
      -r ${rg_tsv} \
      -f ${file_tsv} \
      -o ${seq_exp_json_name} \
      -p ${seq_rg_json_name}
    """
}
