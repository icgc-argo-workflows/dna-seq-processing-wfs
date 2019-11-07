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
    export METADATA_URL=${params.songURI}
    export STORAGE_URL=${params.scoreURI}

    sing configure --server-url ${params.songURI} --access-token ${apiToken}
    sing submit -f ${payload} > output.json
    sing manifest -a `cat output.json | jq .analysisId` -d . -f manifest.txt

    score-client upload --manifest manifest.txt

    sing publish -a `cat output.json | jq .analysisId`\
    
    cat output.json | jq .analysisId
    """
}
