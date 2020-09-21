#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// processes resources
params.cpus = 8
params.mem = 20

// required params w/ default
params.container_version = "5.0.0"
params.transport_mem = 2 // Transport memory is in number of GBs

// optional if secret mounted from pod else required
params.api_token = "" // song/score API token for download process

// required params, no default
// --song_url         song url for download process
// --score_url        score url for download process

// TODO: Replace with score container once it can download files via analysis_id
process scoreDownload {
    pod = [secret: workflow.runName + "-secret", mountPath: "/tmp/rdpc_secret"]
    
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
        path analysis, emit: analysis_json
        path 'out/*', emit: files


    script:
        accessToken = params.api_token ? params.api_token : "`cat /tmp/rdpc_secret/secret`"
        """
        export METADATA_URL=${params.song_url}
        export STORAGE_URL=${params.score_url}
        export TRANSPORT_PARALLEL=${params.cpus}
        export TRANSPORT_MEMORY=${params.transport_mem}
        export ACCESSTOKEN=${accessToken}
        
        score-client download --analysis-id ${analysis_id} --study-id ${study_id} --output-dir ./out 
        """
}
