#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = 'latest'

// required params, no default
// --song_url         song url for download process (defaults to main song_url param)
// --api_token        song/score API token for download process (defaults to main api_token param)

process songPublish {
    
    cpus params.cpus
    memory "${params.mem} MB"
 
    container "overture/song-client:${params.container_version}"

    tag "${analysis_id}"
    
    input:
        val study_id
        val analysis_id

    output:
        val analysis_id, emit: analysis_id

    """
    export CLIENT_SERVER_URL=${params.song_url}
    export CLIENT_ACCESS_TOKEN=${params.api_token}
    export CLIENT_STUDY_ID=${study_id}

    sing publish -a  ${analysis_id}
    """
}
