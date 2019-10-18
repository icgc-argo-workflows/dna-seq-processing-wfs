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
  user_submit_metadata: File?
  analysis_input_payload: File[]?
  wf_short_name: string?
  wf_version: string?
  credentials_file: File
  endpoint_url: string
  bucket_name: string

outputs:
  payload:
    type: File[]
    outputSource: subwf/payload

  variant_call_renamed_result:
    type:
      - "null"
      - type: array
        items: File
    outputSource: subwf/variant_call_renamed_result

steps:
  subwf:
    in:
      bundle_type: bundle_type
      file_to_upload: files_to_upload
      payload_schema_version: payload_schema_version
      user_submit_metadata: user_submit_metadata
      analysis_input_payload: analysis_input_payload
      wf_short_name: wf_short_name
      wf_version: wf_version
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
        user_submit_metadata: File?
        analysis_input_payload: File[]?
        wf_short_name: string?
        wf_version: string?
        credentials_file: File
        endpoint_url: string
        bucket_name: string

      outputs:
        payload:
          type: File
          outputSource: payload_s3_submit/payload
        variant_call_renamed_result:
          type: ["null", File]
          outputSource: payload_gen/variant_call_renamed_result

      steps:
        payload_gen:
          run: https://raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-generation.0.1.5/tools/payload-generation/payload-generation.cwl
          in:
            bundle_type: bundle_type
            payload_schema_version: payload_schema_version
            file_to_upload: file_to_upload
            user_submit_metadata: user_submit_metadata
            analysis_input_payload: analysis_input_payload
            wf_short_name: wf_short_name
            wf_version: wf_version
          out: [ payload, variant_call_renamed_result]
        payload_s3_submit:
          run: https://raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-ceph-submission.0.1.6/tools/payload-ceph-submission/payload-ceph-submission.cwl
          in:
            metadata: user_submit_metadata
            payload: payload_gen/payload
            credentials_file: credentials_file
            endpoint_url: endpoint_url
            bucket_name: bucket_name
          out: [ payload ]

    out: [ payload, variant_call_renamed_result ]
