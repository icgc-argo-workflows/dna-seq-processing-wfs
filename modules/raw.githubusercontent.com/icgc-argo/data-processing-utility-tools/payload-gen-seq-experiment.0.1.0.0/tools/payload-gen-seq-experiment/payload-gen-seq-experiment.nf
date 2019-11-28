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

params.user_submit_metadata = ""
params.wf_short_name = ""
params.wf_version = ""

process PayloadGenSeqExperiment {
  container "quay.io/icgc-argo/payload-gen-seq-experiment:payload-gen-seq-experiment.0.1.0.0"

  input:
    path user_submit_metadata
    val wf_short_name
    val wf_version

  output:
    path "payload.json", emit: payload

  script:
    args_wf_short_name = wf_short_name.length() > 0 ? "-c ${wf_short_name}" : ""
    args_wf_version = wf_version.length() > 0 ? "-v ${wf_version}" : ""
    """
    payload-gen-seq-experiment.py \
         -m ${user_submit_metadata} \
         ${args_wf_short_name} ${args_wf_version}
    """
}
