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
 * Authors:
 *   Linda Xiang <linda.xiang@oicr.on.ca>
 *   Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2
version = '0.3.1.0'

params.files_to_upload = ""
params.seq_experiment_analysis = ""
params.read_group_ubam_analysis = ""
params.wf_name = ""
params.wf_version = ""
params.container_version = ''

process payloadGenDnaAlignment {
  container "quay.io/icgc-argo/payload-gen-dna-alignment:payload-gen-dna-alignment.${params.container_version ?: version}"

  input:
    path files_to_upload
    path seq_experiment_analysis
    path read_group_ubam_analysis
    val wf_name
    val wf_version

  output:
    path "*.dna_alignment.payload.json", emit: payload
    path "out/*", emit: alignment_files

  script:
    args_read_group_ubam_analysis = read_group_ubam_analysis.size() > 0 ? "-u ${read_group_ubam_analysis}" : ""
    """
    payload-gen-dna-alignment.py \
      -f ${files_to_upload} \
      -a ${seq_experiment_analysis} \
      -w "${wf_name}" \
      -r ${workflow.runName} \
      -s ${workflow.sessionId} \
      -v ${wf_version} ${args_read_group_ubam_analysis}
    """
}
