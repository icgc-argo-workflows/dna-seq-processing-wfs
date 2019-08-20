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
  payload_schema_version
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
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.update/tools/metadata-validation/metadata-validation.cwl
    in:
      exp_tsv: exp_tsv
      rg_tsv: rg_tsv
      file_tsv: file_tsv
      seq_exp_json_name: seq_exp_json_name
      seq_rg_json_name: seq_rg_json_name
    out:
      [ seq_exp_json, seq_rg_json ]

  sequence_validation:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/sequence_validation.update/tools/seq-validation/seq-validation.cwl
    in:
      seq_rg_json: metadata_validation/seq_rg_json
      seq_files: seq_files
    out:
      [  ]

  preprocess:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.update/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.cwl
    in:
      seq_rg_json: metadata_validation/seq_rg_json
      seq_files: seq_files
    out:
      [ lane_bams, aligned_basename, bundle_type ]

  lane_seq_payload_gen_and_s3_submit_wf:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-wfs/dna-seq-alignment.download-and-metadata/workflows/payload-gen-and-s3-submit-wf/cwl/payload-gen-and-s3-submit-wf.cwl
    in:
      bundle_type: preprocess/bundle_type
      file_to_upload: preprocess/lane_bams
      payload_schema_version: payload_schema_version
      input_metadata_lane_seq: metadata_validation/seq_rg_json
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name
    out:
      [ payload ]

  lane_seq_s3_upload:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/s3-upload.init/tools/s3-upload/s3-upload.cwl
    scatter: upload_file
    input:
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      s3_credential_file: credentials_file
      bundle_type: preprocess/bundle_type
      payload_jsons: lane_seq_payload_gen_and_s3_submit_wf/payload
      upload_file: preprocess/lane_bams

  alignment:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-wfs/0.1.0/workflows/bwa-mem-subwf/cwl/bwa-mem-subwf.cwl
    in:
      input_bam: preprocess/lane_bams
      ref_genome_gz: ref_genome_gz
      cpus: cpus
      aligned_lane_prefix: aligned_lane_prefix
    out: [ aligned_lane_bam ]

  markdup:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.update/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.cwl
    in:
      aligned_lane_bams: alignment/aligned_lane_bam
      aligned_basename: preprocess/aligned_basename
      ref_genome: ref_genome
      cpus: cpus
      markdup: markdup
      cram: cram

    out: [ aligned_bam, aligned_bam_duplicate_metrics, aligned_cram, bundle_type]

  aligned_bam_payload_gen_and_s3_submit_wf:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-wfs/dna-seq-alignment.download-and-metadata/workflows/payload-gen-and-s3-submit-wf/cwl/payload-gen-and-s3-submit-wf.cwl
    input:
      bundle_type: markdup/bundle_type
      payload_schema_version: payload_schema_version
      files_to_upload: markdup/aligned_bam
      input_metadata_lane_seq: metadata_validation/seq_rg_json
      input_metadata_aligned_seq: lane_seq_payload_gen_and_s3_submit_wf/payload
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name

  aligned_bam_s3_upload:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/s3-upload.init/tools/s3-upload/s3-upload.cwl
    scatter: upload_file
    input:
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      s3_credential_file: credentials_file
      bundle_type: markdup/bundle_type
      payload_jsons: aligned_bam_payload_gen_and_s3_submit_wf/payload
      upload_file: markdup/aligned_bam

  aligned_cram_payload_gen_and_s3_submit_wf:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-wfs/dna-seq-alignment.download-and-metadata/workflows/payload-gen-and-s3-submit-wf/cwl/payload-gen-and-s3-submit-wf.cwl
    input:
      bundle_type: markdup/bundle_type
      payload_schema_version: payload_schema_version
      files_to_upload: markdup/aligned_cram
      input_metadata_lane_seq: metadata_validation/seq_rg_json
      input_metadata_aligned_seq: lane_seq_payload_gen_and_s3_submit_wf/payload
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name

  aligned_cram_s3_upload:
    run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/s3-upload.init/tools/s3-upload/s3-upload.cwl
    scatter: upload_file
    input:
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      s3_credential_file: credentials_file
      bundle_type: markdup/bundle_type
      payload_jsons: aligned_bam_payload_gen_and_s3_submit_wf/payload
      upload_file: markdup/aligned_cram



