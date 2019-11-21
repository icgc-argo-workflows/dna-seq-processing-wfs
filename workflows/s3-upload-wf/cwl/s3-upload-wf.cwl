class: Workflow
cwlVersion: v1.1
id: s3-upload-wf

requirements:
- class: StepInputExpressionRequirement
- class: ScatterFeatureRequirement

inputs:
  endpoint_url: string
  bucket_name: string
  bundle_type: string
  payload_jsons: File[]
  s3_credential_file: File
  upload_files:
    type: File[]
    secondaryFiles: [ ".bai?", ".crai?", ".tbi?", ".idx?" ]

outputs: [ ]

steps:
  alignment:
    run: https://raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/s3-upload.0.1.6.0/tools/s3-upload/s3-upload.cwl
    scatter: upload_file
    in:
      upload_file: upload_files
      endpoint_url: endpoint_url
      bucket_name: bucket_name
      bundle_type: bundle_type
      payload_jsons: payload_jsons
      s3_credential_file: s3_credential_file
    out: [ ]
