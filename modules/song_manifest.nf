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

process songManifest {
    
    cpus params.cpus
    memory "${params.mem} MB"
 
    container "overture/song-client:${params.container_version}"

    input:
        val studyId
        val analysisId
        path upload
    
    output:
        path 'manifest.txt'

    """
    export CLIENT_SERVER_URL=${params.song_url}
    export CLIENT_ACCESS_TOKEN=${params.api_token}
    export CLIENT_STUDY_ID=${studyId}

    export DATADIR=\$PWD
    cd /song-client/bin
    ./sing manifest -a ${analysisId} -d \$DATADIR -f \$DATADIR/manifest.txt
    """
}