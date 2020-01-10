#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = 'latest'

// required params, no default
// --song_url         song url for upload process
// --score_url        score url for upload process
// --api_token        song/score API token for upload process

process scoreUpload {
    
    cpus params.cpus
    memory "${params.mem} MB"
 
    container "overture/score:${params.container_version}"

    tag "${analysis_id}"

    input:
        val analysis_id
        path manifest
        path upload

    output:
        val analysis_id, emit: ready_to_publish

    """
    export METADATA_URL=${params.song_url}
    export STORAGE_URL=${params.score_url}
    export ACCESSTOKEN=${params.api_token}
    
    score-client upload --manifest ${manifest}
    """
}
