#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// groovy goodness
import groovy.json.JsonSlurper
def jsonSlurper = new JsonSlurper()

process extractAnalysisId {
    input:
        val submit_json

    output:
        val result

    exec:
        result = jsonSlurper.parseText(submit_json)['analysisId']
}