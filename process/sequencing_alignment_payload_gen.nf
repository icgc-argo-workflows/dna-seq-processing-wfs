#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// processes resources
params.cpus = 1
params.mem = 1024

// required params w/ default
params.container_version = 'payload-gen-dna-alignment.0.1.1.0'

process sequencingAlignmentPayloadGen {

    cpus params.cpus
    memory "${params.mem} MB"

    container "quay.io/icgc-argo/payload-gen-dna-alignment:${params.container_version}"

    tag "${seq_experiment_analysis.baseName}"
 
    input:
        path seq_experiment_analysis
        path upload

    output:
        path '*.dna_alignment.payload.json', emit: analysis
        path "out/*", emit: upload_files
    
    // dna-seq-alignment is the only accepted value currently, should this be loosened?
    // this could be a thing: ${workflow.repository ? workflow.repository : workflow.scriptName}
    """
    payload-gen-dna-alignment.py \
      -a ${seq_experiment_analysis} \
      -f ${upload} \
      -w dna-seq-alignment \
      -r $workflow.runName \
      -v ${workflow.revision ? workflow.revision : 'latest'}
    """
}