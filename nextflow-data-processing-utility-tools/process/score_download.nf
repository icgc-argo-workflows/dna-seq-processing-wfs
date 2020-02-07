#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 8
params.mem = 20

// required params w/ default
params.container_version = '3.0.1'
params.transport_mem = 2 // Transport memory is in number of GBs

// required params, no default
// --song_url         song url for download process
// --score_url        score url for download process
// --api_token        song/score API token for download process

// TODO: Replace with score container once it can download files via analysis_id
process scoreDownload {
    
    cpus params.cpus
    memory "${params.mem} GB"
 
    container "overture/score:${params.container_version}"

    label "scoreDownload"
    tag "${analysis_id}"

    input:
        path analysis
        val study_id
        val analysis_id

    output:
        path analysis, emit: song_analysis
        path 'out/*', emit: files


    """
    export METADATA_URL=${params.song_url}
    export STORAGE_URL=${params.score_url}
    export ACCESSTOKEN=${params.api_token}
    export TRANSPORT_PARALLEL=${params.cpus}
    export TRANSPORT_MEMORY=${params.transport_mem}
    
    mkdir out
    score-client download --analysis-id ${analysis_id} --study-id ${study_id} --output-dir ./out 
    """
}
