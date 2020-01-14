#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.song_cpu = 1
params.song_mem = 1024
params.score_cpu = 8
params.score_mem = 19264
params.score_transport_mem = 2

// required params w/ default
params.song_container_version = '15b6559f' // TODO: Use latest once it's fixed
params.score_container_version = 'latest'

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

// import modules
include songGetAnalysis from '../process/song_get_analysis' params(song_params)
include scoreDownload from '../process/score_download' params(score_params)

workflow songScoreDownload {
    get: study_id
    get: analysis_id

    main:
        songGetAnalysis(study_id, analysis_id)
        scoreDownload(songGetAnalysis.out.json)

    emit:
        analysis_json = songGetAnalysis.out.json
        analysis_json_and_files = scoreDownload.out.analysis_json_and_files
}
