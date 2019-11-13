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

// test case 1
params.bundle_type = "lane_seq_submission"
params.files_to_upload = [
    "../tests/input/C0HVY_2.lane.bam",
    "../tests/input/D0RE2_1.lane.bam"
]
params.payload_schema_version = "0.1.0-rc.2"
params.user_submit_metadata = "../tests/input/seq-rg-bam.json"
params.credentials_file = "/Users/junjun/credentials"
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"
params.wf_version = ""  // optional
params.wf_short_name = ""  // optional
params.analysis_input_payload = [ "NO_FILE" ]


// test case 2
/*
params.bundle_type = "dna_alignment"
params.files_to_upload = [
    "../tests/input/HCC1143_BAM_INPUT.3.20190814.wgs.grch38.bam"
]
params.payload_schema_version = "0.1.0-rc.2"
params.user_submit_metadata = "../tests/input/seq-rg-bam.json"
params.credentials_file = "/Users/junjun/credentials"
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"
params.wf_version = ""  // optional
params.wf_short_name = ""  // optional
params.analysis_input_payload = [
  "../tests/input/lane_seq_submission.C0HVY_2.lane.bam.json",
  "../tests/input/lane_seq_submission.D0RE2_1.lane.bam.json",
  "../tests/input/lane_seq_submission.D0RH0_2.lane.bam.json"
]
*/

// test case 3
/*
params.bundle_type = "somatic_variant_call"
params.files_to_upload = [
    "../tests/input/PCSI_0115_Pa_P_vs_PCSI_0115_Ly_R.flagged.muts.vcf.gz"
]
params.payload_schema_version = "0.1.0-rc.2"
params.user_submit_metadata = "../tests/input/seq-rg-bam.json"  // do we really need this for variant calling payloads
params.credentials_file = "/Users/junjun/credentials"
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"
params.wf_version = "0.1.0"
params.wf_short_name = "sanger-wxs"
params.analysis_input_payload = [
  "../tests/input/aligned_bam.PCSI_0115_Ly_R.normal.json",
  "../tests/input/aligned_bam.PCSI_0115_Pa_P.tumour.json"
]
*/

// import modules
include payloadGeneration from "./raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-generation.0.1.5.1/tools/payload-generation/payload-generation.nf" params(params)
include payloadCephSubmission from "./raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-ceph-submission.0.1.7.0/tools/payload-ceph-submission/payload-ceph-submission.nf" params(params)


def getSecondaryFiles(main_files){  //this is kind of like CWL's secondary files
  secFiles = []
  for (mf in main_files) {
    if (mf.endsWith('.bam')) {
      secFiles.add(mf + '.bai')
    } else if (mf.endsWith('.cram')) {
      secFiles.add(mf + '.crai')
    } else if (mf.endsWith('.vcf.gz')) {
      secFiles.add(mf + '.tbi')
    } else {
      secFiles.add(mf)  // this seems a bit hacky, it's necessary to make main/sec file paired up properly
    }
  }
  return secFiles
}

Channel
  .fromPath(params.files_to_upload, checkIfExists: false)
  .set { files_to_upload_ch }
/*
Channel
  .fromPath(getSecondaryFiles(params.files_to_upload), checkIfExists: false)
  .set { sec_files_to_upload_ch }
*/
/*
Channel
  .fromPath(params.analysis_input_payload, checkIfExists: false)
  .set { analysis_input_payload_ch }
*/
workflow payloadGenAndS3Submit {
  get:
    bundle_type
    payload_schema_version
    user_submit_metadata
    files_to_upload
    sec_files_to_upload
    analysis_input_payload
    wf_short_name
    wf_version
    credentials_file
    endpoint_url
    bucket_name


  main:
    payloadGeneration(
      bundle_type,
      payload_schema_version,
      user_submit_metadata,
      files_to_upload,
      sec_files_to_upload,
      /*
      Channel
        .fromPath(getSecondaryFiles(params.files_to_upload), checkIfExists: false),
      */
      analysis_input_payload.collect(),
      wf_short_name,
      wf_version
    )
    payloadGeneration.out.payload.view()
    payloadGeneration.out[1].view()  // variant call renamed result file (n/a for none variant call)
    payloadGeneration.out[2].view()  // variant call renamed result index file (n/a for none variant call)

    payloadCephSubmission(
      credentials_file,
      payloadGeneration.out.payload,
      user_submit_metadata,
      endpoint_url,
      bucket_name
    )
    payloadCephSubmission.out.payload.view()

  emit:
    payload = payloadCephSubmission.out.payload
}

workflow {
  payloadGenAndS3Submit(
      params.bundle_type,
      params.payload_schema_version,
      file(params.user_submit_metadata),
      files_to_upload_ch,
      Channel
        .fromPath(getSecondaryFiles(params.files_to_upload), checkIfExists: false),
      //analysis_input_payload_ch.collect(),
      Channel.fromPath(params.analysis_input_payload, checkIfExists: false).collect(),
      params.wf_short_name,
      params.wf_version,
      file(params.credentials_file),
      params.endpoint_url,
      params.bucket_name
  )
  publish:
    payloadGenAndS3Submit.out.payload to: "outdir", mode: 'copy', overwrite: true
}
