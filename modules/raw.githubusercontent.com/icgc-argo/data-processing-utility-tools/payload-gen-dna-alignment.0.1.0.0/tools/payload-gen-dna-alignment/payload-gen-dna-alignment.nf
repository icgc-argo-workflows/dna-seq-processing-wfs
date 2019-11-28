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

params.file_to_upload = ""
params.input_payload = ""
params.wf_short_name = ""
params.wf_version = ""


def getSecondaryFile(main_file){  //this is kind of like CWL's secondary files
  if (main_file.endsWith('.bam')) {
    return main_file + '.bai'
  } else if (main_file.endsWith('.cram')) {
    return main_file + '.crai'
  } else if (main_file.endsWith('.vcf.gz')) {
    return main_file + '.tbi'
  }
}

process PayloadGenDnaAlignment {
  container "quay.io/icgc-argo/payload-gen-dna-alignment:payload-gen-dna-alignment.0.1.0.0"

  input:
    path file_to_upload
    path file_to_upload_idx
    path input_payload
    val wf_short_name
    val wf_version

  output:
    path "payload.json", emit: payload

  script:
    args_wf_short_name = wf_short_name.length() > 0 ? "-c ${wf_short_name}" : ""
    args_wf_version = wf_version.length() > 0 ? "-v ${wf_version}" : ""
    """
    payload-gen-dna-alignment.py \
      -f ${file_to_upload} \
      -a ${input_payload} ${args_wf_short_name} ${args_wf_version}
    """
}
