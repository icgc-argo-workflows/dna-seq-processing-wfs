#!/usr/bin/env cwl-runner

class: Workflow
cwlVersion: v1.1
id: dna-seq-alignment

requirements:
- class: StepInputExpressionRequirement
- class: MultipleInputFeatureRequirement
- class: SubworkflowFeatureRequirement
- class: ScatterFeatureRequirement

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
  seq_files:
    type: File[]?
  repository:
    type: string?
  token_file:
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
  payload_schema_version:
    type: string
  credentials_file:
    type: File
  endpoint_url:
    type: string
  bucket_name:
    type: string


outputs:
  aligned_bam:
    type: File
    secondaryFiles: [.bai]
    outputSource: merge_markdup/aligned_bam
  aligned_bam_duplicate_metrics:
    type: File
    outputSource: merge_markdup/aligned_bam_duplicate_metrics
  aligned_cram:
    type: File
    secondaryFiles: [.crai]
    outputSource: merge_markdup/aligned_cram
  aligned_bam_payload:
    type: File
    outputSource: aligned_bam_payload_s3_submit/payload
  aligned_cram_payload:
    type: File
    outputSource: aligned_cram_payload_s3_submit/payload

steps:
  metadata_validation:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.0.1.2/tools/metadata-validation/metadata-validation.cwl
    in:
      exp_tsv: exp_tsv
      rg_tsv: rg_tsv
      file_tsv: file_tsv
      seq_exp_json_name: seq_exp_json_name
      seq_rg_json_name: seq_rg_json_name
    out:
      [ seq_exp_json, seq_rg_json ]

  sequence_download:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/score-download.0.1.2/tools/score-download/score-download.cwl
    in:
      seq_files: seq_files
      files_tsv: file_tsv
      repository: repository
      token_file: token_file
    out: [ seq_files ]

  sequence_validation:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-validation.0.1.2/tools/seq-validation/seq-validation.cwl
    in:
      seq_rg_json: metadata_validation/seq_rg_json
      seq_files: sequence_download/seq_files
    out:
      [  ]

  preprocess:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.1.2/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.cwl
    in:
      seq_rg_json: metadata_validation/seq_rg_json
      seq_files: sequence_download/seq_files
    out:
      [ lane_bams, aligned_basename, bundle_type ]

  lane_seq_payload_gen_and_s3_submit_wf:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-wfs/0.2.0/workflows/payload-gen-and-s3-submit-wf/cwl/payload-gen-and-s3-submit-wf.cwl
    in:
      bundle_type: preprocess/bundle_type
      files_to_upload: preprocess/lane_bams
      payload_schema_version: payload_schema_version
      input_metadata_lane_seq: metadata_validation/seq_rg_json
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name
    out:
      [ payload ]

  lane_seq_s3_upload:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/s3-upload.0.1.2/tools/s3-upload/s3-upload.cwl
    scatter: upload_file
    in:
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      s3_credential_file: credentials_file
      bundle_type: preprocess/bundle_type
      payload_jsons: lane_seq_payload_gen_and_s3_submit_wf/payload
      upload_file: preprocess/lane_bams
    out: [ ]

  alignment:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-wfs/0.2.0/workflows/bwa-mem-subwf/cwl/bwa-mem-subwf.cwl
    in:
      input_bam: preprocess/lane_bams
      ref_genome_gz: ref_genome_gz
      cpus: cpus
      aligned_lane_prefix: aligned_lane_prefix
    out: [ aligned_lane_bam ]

  merge_markdup:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.2/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.cwl
    in:
      aligned_lane_bams: alignment/aligned_lane_bam
      aligned_basename: preprocess/aligned_basename
      ref_genome: ref_genome
      cpus: cpus
      markdup: markdup
      cram: cram

    out: [ aligned_bam, aligned_bam_duplicate_metrics, aligned_cram, bundle_type]

  aligned_bam_payload_generate:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/payload-generation.0.1.2/tools/payload-generation/payload-generation.cwl
    in:
      bundle_type: merge_markdup/bundle_type
      payload_schema_version: payload_schema_version
      file_to_upload: merge_markdup/aligned_bam
      input_metadata_lane_seq: metadata_validation/seq_rg_json
      input_metadata_aligned_seq: lane_seq_payload_gen_and_s3_submit_wf/payload
    out: [ payload ]

  aligned_bam_payload_s3_submit:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/payload-ceph-submission.0.1.2/tools/payload-ceph-submission/payload-ceph-submission.cwl
    in:
      metadata: metadata_validation/seq_rg_json
      payload: aligned_bam_payload_generate/payload
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name
    out: [ payload ]

  aligned_bam_s3_upload:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/s3-upload.0.1.2/tools/s3-upload/s3-upload.cwl
    in:
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      s3_credential_file: credentials_file
      bundle_type: merge_markdup/bundle_type
      upload_file: merge_markdup/aligned_bam
      payload_jsons:
        source:
         - aligned_bam_payload_s3_submit/payload
        linkMerge: merge_flattened

    out: [ ]

  aligned_cram_payload_generate:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/payload-generation.0.1.2/tools/payload-generation/payload-generation.cwl
    in:
      bundle_type: merge_markdup/bundle_type
      payload_schema_version: payload_schema_version
      file_to_upload: merge_markdup/aligned_cram
      input_metadata_lane_seq: metadata_validation/seq_rg_json
      input_metadata_aligned_seq: lane_seq_payload_gen_and_s3_submit_wf/payload
    out: [ payload ]

  aligned_cram_payload_s3_submit:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/payload-ceph-submission.0.1.2/tools/payload-ceph-submission/payload-ceph-submission.cwl
    in:
      metadata: metadata_validation/seq_rg_json
      payload: aligned_cram_payload_generate/payload
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name
    out: [ payload ]

  aligned_cram_s3_upload:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/s3-upload.0.1.2/tools/s3-upload/s3-upload.cwl
    in:
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      s3_credential_file: credentials_file
      bundle_type: merge_markdup/bundle_type
      upload_file: merge_markdup/aligned_cram
      payload_jsons:
        source:
         - aligned_cram_payload_s3_submit/payload
        linkMerge: merge_flattened

    out: [ ]


