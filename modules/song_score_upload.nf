#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.song_container_version = 'latest'
params.score_container_version = 'edge' // TODO: Use latest once it's fixed

// required params, no default
// --song_url         song url for download process (defaults to main song_url param)
// --score_url        score url for download process (defaults to main score_url param)
// --api_token        song/score API token for download process (defaults to main api_token param)

song_params = [
    *:params,
    'container_version': params.song_container_version
]

score_params = [
    *:params,
    'container_version': params.score_container_version
]

// import modules
include songSubmit from './song_submit' params(song_params)
include songManifest from './song_manifest' params(song_params)
include scoreUpload from './score_upload' params(score_params)
include songPublish from './song_publish' params(song_params)

process extractAnalysisId {
    input:
        val submit_json

    output:
        val result

    exec:
        result = jsonSlurper.parseText(submit_json).analysisId
}

workflow song_score_upload {
    get: studyId
    get: payload
    get: upload

    main:
        songSubmit(studyId, payload)

        // Extract and save analysisId
        analysisId = extractAnalysisId(songSubmit.out)

        songManifest(studyId, analysisId, upload)
        scoreUpload(analysisId, songManifest.out, upload)
        songPublish(studyId, scoreUpload.out.ready_to_publish)

    emit:
        analysis_id = songPublish.out.analysisId
}

