#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// test data
test_data_dir = "data"

include song_score_upload from '../modules/song_score_upload' params(params)
include song_score_download from '../modules/song_score_download' params(params)

payload = file("${test_data_dir}/payload.json")
upload = Channel.fromPath("${test_data_dir}/*.bam").collect()

workflow {
  // Upload files with payload
  song_score_upload(params.study_id, payload, upload)

  // Download same files
  song_score_download(params.study_id, song_score_upload.out.analysis_id)
}
