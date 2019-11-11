#!/usr/bin/env nextflow
nextflow.preview.dsl=2


process songScoreUpload {
    
    cpus params.cpus
    memory "${params.mem} MB"

    container 'icgc-argo/song-score'

    input:
    val apiToken
    file payload
    file uploads

    output:
    stdout()

    // rob will make sing submit extract study from payload
    """
    export ACCESSTOKEN=${apiToken}
    export METADATA_URL=${params.songURL}
    export STORAGE_URL=${params.scoreURL}

    sing configure --server-url ${params.songURL} --access-token ${apiToken}
    sing submit -f ${payload} > output.json
    sing manifest -a `cat output.json | jq .analysisId` -d . -f manifest.txt

    score-client upload --manifest manifest.txt

    sing publish -a `cat output.json | jq .analysisId`\
    
    cat output.json | jq .analysisId
    """
}
