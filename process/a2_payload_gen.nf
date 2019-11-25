#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = 'latest'

process a2PayloadGen {

    cpus params.cpus
    memory "${params.mem} MB"

    container "lepsalex/a2-payload-gen:${params.container_version}"

    tag "${a1_payload.baseName}"
 
    input:
        path template
        path a1_payload
        path upload

    output:
        path 'a2_payload.json', emit: a2_analysis


    """
    a2_payload_generator.py ${template} ${a1_payload} ${upload}
    """
}