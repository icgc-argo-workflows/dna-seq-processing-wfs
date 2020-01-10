#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.song_container_version = '15b6559f' // TODO: Use latest once it's fixed
params.score_container_version = 'edge' // TODO: Use latest once it's fixed
params.extract_container_version = 'latest'

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

extract_params = [
    *:params,
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

