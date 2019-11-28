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

params.credentials_file = ""
params.payload = ""
params.metadata = ""
params.endpoint_url = ""
params.bucket_name = ""


process payloadCephSubmission {
  container "quay.io/icgc-argo/payload-ceph-submission:payload-ceph-submission.0.1.7.0"

  input:
    path credentials_file
    path payload
    path metadata
    val endpoint_url
    val bucket_name

  output:
    path "????????-????-????-????-????????????.json", emit: payload  // <uuid>.json

  script:
    """
    export AWS_SHARED_CREDENTIALS_FILE=${credentials_file}
    payload-ceph-submission.py \
      -p ${payload} \
      -m ${metadata} \
      -s ${endpoint_url} \
      -b ${bucket_name}
    """
}
