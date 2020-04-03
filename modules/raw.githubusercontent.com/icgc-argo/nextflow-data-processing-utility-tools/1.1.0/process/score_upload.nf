#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 8
params.mem = 20

// required params w/ default
params.container_version = '3.1.1'
params.transport_mem = 2 // Transport memory is in number of GBs

// required params, no default
// --song_url         song url for upload process
// --score_url        score url for upload process
// --api_token        song/score API token for upload process

process scoreUpload {
    
    cpus params.cpus
    memory "${params.mem} GB"
 
    container "overture/score:${params.container_version}"

    tag "${analysis_id}"

    input:
        val analysis_id
        path manifest
        path upload
        env ACCESSTOKEN

    output:
        val analysis_id, emit: ready_to_publish

    """
    export METADATA_URL=${params.song_url}
    export STORAGE_URL=${params.score_url}
    export TRANSPORT_PARALLEL=${params.cpus}
    export TRANSPORT_MEMORY=${params.transport_mem}
    
    score-client upload --manifest ${manifest}
    """
}
