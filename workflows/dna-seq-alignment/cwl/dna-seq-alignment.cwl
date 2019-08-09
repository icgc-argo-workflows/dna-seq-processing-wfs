#!/usr/bin/env cwl-runner

class: Workflow
cwlVersion: v1.0
id: dna-seq-alignment

requirements:
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement
- class: MultipleInputFeatureRequirement
- class: SubworkflowFeatureRequirement

inputs:
  exp_tsv:
    type: File
  rg_tsv:
    type: File
  file_tsv:
    type: File
  seq_exp_json_name:
    type: string
  seq_rg_json_name:
    type: string
  seq_files_dir:
    type: Directory
  picard_jar:
    type: File?
  ref_genome_gz:
    type: File
    secondaryFiles:
      - .amb
      - .ann
      - .bwt
      - .fai
      - .pac
      - .sa
      - .alt
  ref_genome:
    type: File
    secondaryFiles:
      - .fai
  cpus:
    type: int?
  aligned_lane_prefix:
    type: string
  markdup:
    type: boolean
  cram:
    type: boolean

outputs:
  aligned_bam:
    type: File
    secondaryFiles: [.bai]
    outputSource: markdup/aligned_bam
  aligned_bam_duplicate_metrics:
    type: File
    outputSource: markdup/aligned_bam_duplicate_metrics
  aligned_cram:
    type: File
    secondaryFiles: [.crai]
    outputSource: markdup/aligned_cram

steps:
  metadata_validation:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/0.1.1/tools/metadata-validation/metadata-validation.cwl
    in:
      exp_tsv: exp_tsv
      rg_tsv: rg_tsv
      file_tsv: file_tsv
      seq_exp_json_name: seq_exp_json_name
      seq_rg_json_name: seq_rg_json_name
    out:
      [ seq_exp_json, seq_rg_json, input_format]

  sequence_validation:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/0.1.1/tools/seq-validation/seq-validation.cwl
    in:
      seq_rg_json: metadata_validation/seq_rg_json
      seq_files_dir: seq_files_dir
      seq_format: metadata_validation/input_format
    out:
      [  ]

  preprocess:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/0.1.1/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.cwl
    in:
      picard_jar: picard_jar
      seq_rg_json: metadata_validation/seq_rg_json
      seq_format: metadata_validation/input_format
      seq_files_dir: seq_files_dir
    out:
      [ lane_bams, aligned_basename ]

  alignment:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/0.1.1/workflows/bwa-mem-subwf/cwl/bwa-mem-subwf.cwl
    in:
      input_bam: preprocess/lane_bams
      ref_genome_gz: ref_genome_gz
      cpus: cpus
      aligned_lane_prefix: aligned_lane_prefix
    out: [ aligned_lane_bam ]

  markdup:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/0.1.1/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.cwl
    in:
      aligned_lane_bams: alignment/aligned_lane_bam
      aligned_basename: preprocess/aligned_basename
      ref_genome: ref_genome
      cpus: cpus
      markdup: markdup
      cram: cram

    out: [ aligned_bam, aligned_bam_duplicate_metrics, aligned_cram]

