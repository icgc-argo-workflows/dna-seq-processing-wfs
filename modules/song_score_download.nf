#!/usr/bin/env nextflow
nextflow.preview.dsl=2


process songScoreDownload {
    
    cpus params.cpus
    memory "${params.mem} MB"
 
    container 'icgc-argo/song-score'

    input:
    val analysisId

    output:
    file 'analysis.json'
    file './out/*'

    // doesn't exist yet, Roberto will make it happen
    // rob will make sing submit extract study from payload
    """
    export ACCESSTOKEN=${params.apiToken}
    export METADATA_URL=${params.songURL}
    export STORAGE_URL=${params.scoreURL}

    sing configure --server-url ${params.songURL} --access-token ${params.apiToken}
    sing get --analysisId ${analysisId} > analysis.json
    
    score-client download --analysisId ${analysisId} --output-dir ./out
    """
}
