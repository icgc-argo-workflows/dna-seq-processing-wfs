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

// required params w/ default
params.song_container_version = '4.2.1'
params.score_container_version = '5.0.0'

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

// import modules
// TODO: change import for score_download after it's updated on the other git repo
include { songGetAnalysis as songGet } from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/song_get_analysis' params(song_params)
include { scoreDownload as scoreDn } from '../modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/score_download' params(score_params)

workflow songScoreDownload {
    take:
        study_id
        analysis_id

    main:
        songGet(study_id, analysis_id)
        scoreDn(songGet.out.json, study_id, analysis_id)

    emit:
        song_analysis = songGet.out.json
        files = scoreDn.out.files
}
