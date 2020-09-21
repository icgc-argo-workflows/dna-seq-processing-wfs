#!/usr/bin/env nextflow
nextflow.enable.dsl=2

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
params.song_container_version = '4.2.1'
params.score_container_version = '5.0.0'
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
include { songSubmit as songSub } from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/song_submit' params(song_params)
include { songManifest as songMan } from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/song_manifest' params(song_params)
include { scoreUpload as scoreUp } from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/score_upload' params(score_params)
include { songPublish as songPub } from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/song_publish' params(song_params)

workflow songScoreUpload {
    take:
        study_id
        payload
        upload

    main:
        // Create new analysis
        songSub(study_id, payload)

        // Generate file manifest for upload
        songMan(study_id, songSub.out, upload)

        // Upload to SCORE
        scoreUp(songSub.out, songMan.out, upload)

        // Publish the analysis
        songPub(study_id, scoreUp.out.ready_to_publish)

    emit:
        analysis_id = songPub.out.analysis_id
}

