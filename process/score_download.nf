#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = 'latest'

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

    tag "${analysis.baseName}"

    input:
        path analysis

    output:
        tuple path(analysis), path('out/*'), emit: analysis_json_and_files


    """
    export METADATA_URL=${params.song_url}
    export STORAGE_URL=${params.score_url}
    export ACCESSTOKEN=${params.api_token}
    
    mkdir out
    cat ${analysis} | jq -r '.files[].objectId' | while IFS=\$'\\\t' read -r objectId; do score-client download --object-id "\$objectId" --output-dir ./out; done
    """
}
