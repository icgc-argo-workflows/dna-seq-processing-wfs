#!/usr/bin/env nextflow
nextflow.preview.dsl=2


process songScoreDownload {
    
    cpus params.cpus
    memory "${params.mem} MB"
 
    container 'icgc-argo/song-score'

    input:
    val apiToken
    val analysisId

    output:
    file 'analysis.json'
    file './out/*'

    // doesn't exist yet, Roberto will make it happen
    // rob will make sing submit extract study from payload
    """
    export ACCESSTOKEN=${apiToken}
    export METADATA_URL=${params.songURI}
    export STORAGE_URL=${params.scoreURI}

    sing configure --server-url ${params.songURI} --access-token ${apiToken}
    sing get --analysisId ${analysisId} > analysis.json
    
    score-client download --analysisId ${analysisId} --output-dir ./out
    """
}
