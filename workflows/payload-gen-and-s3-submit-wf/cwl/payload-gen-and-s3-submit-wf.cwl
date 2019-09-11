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
      - .tbi?
      - .idx?
  payload_schema_version: string
  input_metadata_lane_seq: File
  input_metadata_aligned_seq: File[]?
  credentials_file: File
  endpoint_url: string
  bucket_name: string

outputs:
  payload:
    type: File[]
    outputSource: subwf/payload

steps:
  subwf:
    in:
      bundle_type: bundle_type
      file_to_upload: files_to_upload
      payload_schema_version: payload_schema_version
      input_metadata_lane_seq: input_metadata_lane_seq
      input_metadata_aligned_seq: input_metadata_aligned_seq
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
          secondaryFiles: [ ".bai?", ".crai?", ".tbi?", ".idx?" ]
        payload_schema_version: string
        input_metadata_lane_seq: File?
        input_metadata_aligned_seq: File[]?
        credentials_file: File
        endpoint_url: string
        bucket_name: string

      outputs:
        payload:
          type: File
          outputSource: payload_s3_submit/payload

      steps:
        payload_gen:
          run: https://raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-generation.0.1.3/tools/payload-generation/payload-generation.cwl
          in:
            bundle_type: bundle_type
            payload_schema_version: payload_schema_version
            file_to_upload: file_to_upload
            input_metadata_lane_seq: input_metadata_lane_seq
            input_metadata_aligned_seq: input_metadata_aligned_seq
          out: [ payload ]
        payload_s3_submit:
          run: https://raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-ceph-submission.0.1.4/tools/payload-ceph-submission/payload-ceph-submission.cwl
          in:
            metadata: input_metadata_lane_seq
            payload: payload_gen/payload
            credentials_file: credentials_file
            endpoint_url: endpoint_url
            bucket_name: bucket_name
          out: [ payload ]

    out: [ payload ]
