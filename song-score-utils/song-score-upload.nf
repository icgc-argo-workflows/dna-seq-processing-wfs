#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.song_cpus = 1
params.song_mem = 1
params.song_api_token = ''
params.score_cpus = 8
params.score_mem = 20
params.score_transport_mem = 2
params.score_api_token = ''
params.extract_cpus = 1
params.extract_mem = 1

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
    'cpus': params.song_cpus,
    'mem': params.song_mem,
    'container_version': params.song_container_version,
    'api_token': params.song_api_token ?: params.api_token
]

score_params = [
    *:params,
    'cpus': params.score_cpus,
    'mem': params.score_mem,
    'transport_mem': params.score_transport_mem,
    'container_version': params.score_container_version,
    'api_token': params.score_api_token ?: params.api_token
]

extract_params = [
    'cpus': params.extract_cpus,
    'mem': params.extract_mem,
    'container_version': params.extract_container_version
]

// import modules
// TODO: change import for song_manifest after it's updated (use non-root docker image) on the other git repo
include songSubmit from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/master/process/song_submit' params(song_params)
include songManifest from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/master/process/song_manifest' params(song_params)
include scoreUpload from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/master/process/score_upload' params(score_params)
include songPublish from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/master/process/song_publish' params(song_params)
include extractAnalysisId from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/master/process/extract_analysis_id' params(extract_params)

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

