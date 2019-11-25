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

params.bundle_type = ""
params.payload_schema_version = ""
params.user_submit_metadata = ""
params.file_to_upload = ""
params.analysis_input_payload = ""
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

process payloadGeneration {
  container "quay.io/icgc-argo/payload-generation:payload-generation.0.1.5.1"

  input:
    val bundle_type
    val payload_schema_version
    path user_submit_metadata
    path file_to_upload
    path file_to_upload_idx
    path analysis_input_payload
    val wf_short_name
    val wf_version

  output:
    path "${bundle_type}.*.json", emit: payload
    path "*.${wf_short_name}.${wf_version}.somatic.*.vcf.gz" optional true
    path "*.${wf_short_name}.${wf_version}.somatic.*.vcf.gz.{tbi,idx}" optional true

  script:
    args_user_submit_metadata = user_submit_metadata.name != "NO_FILE" ? "-m ${user_submit_metadata}" : ""
    args_wf_short_name = wf_short_name.length() > 0 ? "-c ${wf_short_name}" : ""
    args_wf_version = wf_version.length() > 0 ? "-v ${wf_version}" : ""
    """
    payload-generation.py \
      -t ${bundle_type} \
      -p ${payload_schema_version} ${args_user_submit_metadata} \
      -f ${file_to_upload} \
      -a ${analysis_input_payload} ${args_wf_short_name} ${args_wf_version}
    """
}
