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

params.sequencing_experiment_analysis = ""
params.file_to_upload = ""
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

process PayloadGenReadGroupUbam {
  container "quay.io/icgc-argo/payload-gen-read-group-ubam:payload-gen-read-group-ubam.0.1.0.0"

  input:
    path sequencing_experiment_analysis
    path file_to_upload
    path file_to_upload_idx
    val wf_short_name
    val wf_version

  output:
    path "*.json", emit: payload

  script:
    args_wf_short_name = wf_short_name.length() > 0 ? "-c ${wf_short_name}" : ""
    args_wf_version = wf_version.length() > 0 ? "-v ${wf_version}" : ""
    """
    payload-gen-read-group-ubam.py \
      -a ${sequencing_experiment_analysis} \
      -f ${file_to_upload} \
      ${args_wf_short_name} ${args_wf_version}
    """
}
