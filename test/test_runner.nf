#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// test data
test_data_dir = "data"

include songScoreUpload as a1Upload from '../workflow/song_score_upload' params(params)
include songScoreUpload as a2Upload from '../workflow/song_score_upload' params(params)
include songScoreDownload from '../workflow/song_score_download' params(params)
include a2PayloadGen from '../process/a2_payload_gen'

a1_payload = file("${test_data_dir}/a1_payload_json.json")
upload = Channel.fromPath("${test_data_dir}/*.bam").collect()

a2_upload_template = file("${test_data_dir}/a2_upload_template.json")
a2_files = Channel.fromPath("${test_data_dir}/a2_files/*").collect()

workflow {
  // Upload files as A1
  a1Upload(params.study_id, a1_payload, upload)

  // Download A1 files
  songScoreDownload(params.study_id, a1Upload.out.analysis_id)

  // A1 to A2 Payload generator
  a2PayloadGen(a2_upload_template, songScoreDownload.out.analysis_json, upload)

  // Upload same files with A2 payload
  a2Upload(params.study_id, a2PayloadGen.out.a2_analysis, upload)
}
