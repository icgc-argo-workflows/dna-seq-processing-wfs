#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.song_cpu = 1
params.song_mem = 1024
params.score_cpu = 8
params.score_mem = 19264
params.score_transport_mem = 2
params.extract_cpu = 1
params.extract_mem = 1024

// required params w/ default
params.song_container_version = '4.0.0'
params.score_container_version = '3.0.1'
params.extract_container_version = 'latest'

// required params, no default
// --song_url         song url for download process (defaults to main song_url param)
// --score_url        score url for download process (defaults to main score_url param)
// --api_token        song/score API token for download process (defaults to main api_token param)

song_params = [
    *:params,
    'cpu': params.song_cpu,
    'mem': params.song_mem,
    'container_version': params.song_container_version
]

score_params = [
    *:params,
    'cpu': params.score_cpu,
    'mem': params.score_mem,
    'transport_mem': params.score_transport_mem,
    'container_version': params.score_container_version
]

extract_params = [
    'cpu': params.extract_cpu,
    'mem': params.extract_mem,
    'container_version': params.extract_container_version
]

// import modules
include songSubmit from '../process/song_submit' params(song_params)
include songManifest from '../process/song_manifest' params(song_params)
include scoreUpload from '../process/score_upload' params(score_params)
include songPublish from '../process/song_publish' params(song_params)
include extractAnalysisId from '../process/extract_analysis_id' params(extract_params)

workflow songScoreUpload {
    get: study_id
    get: payload
    get: upload

    main:
        // Create new analysis
        songSubmit(study_id, payload)

        // Extract and save analysis_id
        extractAnalysisId(songSubmit.out)

        // Generate file manifest for upload
        songManifest(study_id, extractAnalysisId.out, upload)

        // Upload to SCORE
        scoreUpload(extractAnalysisId.out, songManifest.out, upload)

        // Publish the analysis
        songPublish(study_id, scoreUpload.out.ready_to_publish)

    emit:
        analysis_id = songPublish.out.analysis_id
}

