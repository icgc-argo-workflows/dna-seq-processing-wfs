#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// test data
test_data_dir = "data"

include songScoreUpload from '../workflow/song_score_upload' params(params)
include songScoreDownload from '../workflow/song_score_download' params(params)

payload = file("${test_data_dir}/payload.json")
upload = Channel.fromPath("${test_data_dir}/*.bam").collect()

workflow {
  // Upload files with payload
  songScoreUpload(params.study_id, payload, upload)

  // Download same files
  songScoreDownload(params.study_id, songScoreUpload.out.analysis_id)
}
