#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1

// required params w/ default
params.container_version = '4.2.0'

// required params, no default
// --song_url         song url for download process (defaults to main song_url param)
// --api_token        song/score API token for download process (defaults to main api_token param)

process songGetAnalysis {
    
    cpus params.cpus
    memory "${params.mem} GB"
 
    container "overture/song-client:${params.container_version}"

    tag "${analysis_id}"

    input:
        val study_id
        val analysis_id
        env CLIENT_ACCESS_TOKEN

    output:
        path '*.analysis.json', emit: json


    """
    export CLIENT_SERVER_URL=${params.song_url}
    export CLIENT_STUDY_ID=${study_id}

    sing search -a ${analysis_id} > ${analysis_id}.analysis.json
    """
}
