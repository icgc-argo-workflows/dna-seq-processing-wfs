#!/usr/bin/env cwl-runner

class: Workflow
cwlVersion: v1.0
id: bwa-mem-subwf

requirements:
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement
- class: MultipleInputFeatureRequirement
- class: ScatterFeatureRequirement

inputs:
  - id: input_bam
    type: File[]
  - id: ref_genome_gz
    type: File
    secondaryFiles:
      - .amb
      - .ann
      - .bwt
      - .fai
      - .pac
      - .sa
      - .alt
  - id: cpus
    type: int?
  - id: aligned_lane_prefix
    type: string

outputs:
  aligned_lane_bam:
    type: File[]
    outputSource: alignment/aligned_lane_bam

steps:
  alignment:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/0.1.1/tools/bwa-mem-aligner/bwa-mem-aligner.cwl
    scatter: input_bam
    in:
      input_bam: input_bam
      ref_genome_gz: ref_genome_gz
      cpus: cpus
      aligned_lane_prefix: aligned_lane_prefix
    out: [ aligned_lane_bam ]


