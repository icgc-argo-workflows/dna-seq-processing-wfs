class: Workflow
cwlVersion: v1.1
id: payload-gen-and-s3-submit-wf

requirements:
- class: StepInputExpressionRequirement
- class: MultipleInputFeatureRequirement
- class: SubworkflowFeatureRequirement
- class: ScatterFeatureRequirement

inputs:
  bundle_type: string
  files_to_upload:
    type: File[]
    secondaryFiles:
      - .bai?
      - .crai?
  payload_schema_version: string
  lane_seq_metadata: File?
  aligned_seq_bundle: File?
  credentials_file: File
  endpoint_url: string
  bucket_name: string

outputs: [ ]

steps:
  subwf:
    in:
      bundle_type: bundle_type
      file_to_upload: files_to_upload
      payload_schema_version: payload_schema_version
      lane_seq_metadata: lane_seq_metadata
      aligned_seq_bundle: aligned_seq_bundle
      credentials_file: credentials_file
      endpoint_url: endpoint_url
      bucket_name: bucket_name

    scatter: file_to_upload

    run:
      class: Workflow

      inputs:
        bundle_type: string
        file_to_upload:
          type: File
          secondaryFiles: [ ".bai?", ".crai?" ]
        payload_schema_version: string
        lane_seq_metadata: File?
        aligned_seq_bundle: File?
        credentials_file: File
        endpoint_url: string
        bucket_name: string

      outputs: [ ]

      steps:
        payload_gen:
          run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/payload-generation.initial/tools/payload-generation/payload-generation.cwl
          in:
            bundle_type: bundle_type
            payload_schema_version: payload_schema_version
            file_to_upload: file_to_upload
            lane_seq_metadata: lane_seq_metadata
            aligned_seq_bundle: aligned_seq_bundle
          out: [ payload ]
        payload_s3_submit:
          run: https://raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/payload-ceph-submission.initial/tools/payload-ceph-submission/payload-ceph-submission.cwl
          in:
            metadata:
              source: [ lane_seq_metadata, aligned_seq_bundle ]
              linkMerge: merge_flattened
            payload: payload_gen/payload
            credentials_file: credentials_file
            endpoint_url: endpoint_url
            bucket_name: bucket_name
          out: [ payload ]

    out: [ payload_s3_submit/payload ]
