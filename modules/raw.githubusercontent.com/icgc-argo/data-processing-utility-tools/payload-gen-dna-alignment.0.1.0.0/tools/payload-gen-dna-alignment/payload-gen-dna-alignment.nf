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
 * Authors:
 *   Linda Xiang <linda.xiang@oicr.on.ca>
 *   Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2

params.files_to_upload = ""
params.input_payloads = ""
params.wf_short_name = ""
params.wf_version = ""


process payloadGenDnaAlignment {
  container "quay.io/icgc-argo/payload-gen-dna-alignment:payload-gen-dna-alignment.0.1.0.0"

  input:
    path files_to_upload
    path input_payloads
    val wf_short_name
    val wf_version

  output:
    path "payload.json", emit: payload

  script:
    args_wf_short_name = wf_short_name.length() > 0 ? "-c ${wf_short_name}" : ""
    args_wf_version = wf_version.length() > 0 ? "-v ${wf_version}" : ""
    """
    payload-gen-dna-alignment.py \
      -f ${files_to_upload} \
      -a ${input_payloads} ${args_wf_short_name} ${args_wf_version}
    """
}
