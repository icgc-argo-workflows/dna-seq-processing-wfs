#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 8
params.mem = 10240

// required params w/ default
params.container_version = 'latest'
params.transport_mem = 2 // Transport memory is in number of GBs

// required params, no default
// --song_url         song url for download process
// --score_url        score url for download process
// --api_token        song/score API token for download process

// TODO: Replace with score container once it can download files via analysis_id
process scoreDownload {
    
    cpus params.cpus
    memory "${params.mem} MB"
 
    // TODO: Update to official container  
    container "lepsalex/song-score-jq:${params.container_version}"

    label "scoreDownload"

    input:
        path analysis

    output:
        tuple path(analysis), path('out/*'), emit: analysis_json_and_files


    """
    export METADATA_URL=${params.song_url}
    export STORAGE_URL=${params.score_url}
    export ACCESSTOKEN=${params.api_token}
    export TRANSPORT_PARALLEL=${params.cpus}
    export TRANSPORT_MEMORY=${params.transport_mem}
    
    mkdir out
    cat ${analysis} | jq -r '.files[].objectId' | while IFS=\$'\\\t' read -r objectId; do score-client download --object-id "\$objectId" --output-dir ./out; done
    """
}
