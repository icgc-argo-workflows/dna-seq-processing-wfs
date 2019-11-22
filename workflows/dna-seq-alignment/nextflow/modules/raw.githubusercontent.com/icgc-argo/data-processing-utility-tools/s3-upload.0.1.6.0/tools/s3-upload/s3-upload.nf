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

params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"
params.bundle_type = "dna_alignment"
params.payload_jsons = "tests/data/dna_alignment.test.json"
params.s3_credential_file = "/Users/junjun/credentials"
params.upload_file = "tests/data/HCC1143.3.20190726.wgs.grch38.bam"
params.sec_upload_file = "tests/data/HCC1143.3.20190726.wgs.grch38.bam.bai"

def getSecondaryFile(main_file){  //this is kind of like CWL's secondary files
  if (main_file.endsWith('.bam')) {
    return main_file + '.bai'
  } else if (main_file.endsWith('.cram')) {
    return main_file + '.crai'
  } else if (main_file.endsWith('.vcf.gz')) {
    return main_file + '.tbi'
  }
}

process s3UploadTool {
  container "quay.io/icgc-argo/s3-upload:s3-upload.0.1.6.0"

  input:
    val endpoint_url
    val bucket_name
    val bundle_type
    path payload_json
    path s3_credential_file
    path upload_file
    path upload_file_secondary

  script:
    """
    s3-upload.py \
      -s ${endpoint_url} \
      -b ${bucket_name} \
      -t ${bundle_type} \
      -p ${payload_json} \
      -c ${s3_credential_file} \
      -f ${upload_file}
    """
}

workflow s3Upload {
  get:
    endpoint_url
    bucket_name
    bundle_type
    payload_jsons
    s3_credential_file
    upload_file
    sec_upload_file

  main:
    s3UploadTool(
      endpoint_url,
      bucket_name,
      bundle_type,
      payload_jsons,
      s3_credential_file,
      upload_file,
      sec_upload_file
    )
}

workflow {
  s3Upload(
    params.endpoint_url,
    params.bucket_name,
    params.bundle_type,
    file(params.payload_jsons),
    file(params.s3_credential_file),
    file(params.upload_file),
    file(params.sec_upload_file)
  )
}
