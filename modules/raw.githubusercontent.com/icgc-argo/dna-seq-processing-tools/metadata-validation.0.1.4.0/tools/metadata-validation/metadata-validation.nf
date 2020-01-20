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
 * author Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2
version = '0.1.4.0'

params.exp_tsv = "tests/input/experiment-fq.tsv"
params.rg_tsv = "tests/input/read_group-fq.tsv"
params.file_tsv = "tests/input/file-fq.tsv"
params.container_version = ''


process metadataValidation {
  container "quay.io/icgc-argo/metadata-validation:metadata-validation.${params.container_version ?: version}"

  input:
    path exp_tsv
    path rg_tsv
    path file_tsv

  output:
    path "metadata.json", emit: metadata

  script:
    """
    metadata-validation.py \
      -e ${exp_tsv} \
      -r ${rg_tsv} \
      -f ${file_tsv}
    """
}
