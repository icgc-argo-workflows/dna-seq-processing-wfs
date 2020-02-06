#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1

// required params w/ default
params.container_version = 'latest'

process extractAnalysisId {

    cpus params.cpus
    memory "${params.mem} GB"
 
    // TODO: replace with an ICGC-ARGO container
    container "cfmanteiga/alpine-bash-curl-jq:${params.container_version}"

    label "extractAnalysisId"

    input:
        path submit_json

    output:
        stdout()

    """
    cat ${submit_json} | jq --raw-output '.analysisId' | tr -d '\\n'
    """
}
