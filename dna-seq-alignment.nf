#!/bin/bash nextflow

/*
 * Copyright (c) 2019, Ontario Institute for Cancer Research (OICR).
 *                                                                                                               
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * author Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2
version = "0.2.3.0"

params.meta_format = "tsv"
params.exp_tsv = ""
params.rg_tsv = ""
params.file_tsv = ""
params.exp_json = ""  // optional json string of exp metadata
params.seq_exp_json_name = "seq_exp.json"
params.seq_rg_json_name = "seq_rg.json"
params.seq_files = "NO_FILE"
params.repository = "collab"
params.token_file = ""
params.credentials_file =""
params.ref_genome_gz = ""
params.ref_genome = ""
params.cpus_align = 1
params.cpus_mkdup = 1
params.reads_max_discard_fraction = 0.08
params.aligned_lane_prefix = "grch38-aligned"
params.markdup = true
params.lossy = false
params.aligned_seq_output_format = "cram"
params.payload_schema_version = "0.1.0-rc.2"
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"


include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.0.1.3.1/tools/metadata-validation/metadata-validation.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-download.0.1.5.1/tools/score-download/score-download.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-validation.0.1.4.1/tools/seq-validation/seq-validation.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.1.5.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.2.1/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.4.1/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(params)

include payloadCephSubmission as payloadCephSubmission_RG from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-ceph-submission.0.1.7.0/tools/payload-ceph-submission/payload-ceph-submission.nf" params(params)

include payloadGenAndS3Submit as payloadGenAndS3Submit_LS from "./payload-gen-and-s3-submit.nf" params(params)
include payloadGenAndS3Submit as payloadGenAndS3Submit_AS from "./payload-gen-and-s3-submit.nf" params(params)

include s3Upload as s3Upload_LS from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/s3-upload.0.1.6.0/tools/s3-upload/s3-upload.nf" params(params)
include s3Upload as s3Upload_AS from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/s3-upload.0.1.6.0/tools/s3-upload/s3-upload.nf" params(params)


workflow DnaSeqAlignmentWf {
  get:
    meta_format
    exp_tsv
    rg_tsv
    file_tsv
    exp_json
    seq_exp_json_name
    seq_rg_json_name
    seq_files
    repository
    token_file
    ref_genome_gz
    ref_genome
    cpus_align
    cpus_mkdup
    reads_max_discard_fraction
    aligned_lane_prefix
    markdup
    lossy
    aligned_seq_output_format
    payload_schema_version
    credentials_file
    endpoint_url
    bucket_name

  main:
    metadataValidation(
      meta_format,
      exp_json,
      file(exp_tsv),
      file(rg_tsv),
      file(file_tsv),
      seq_exp_json_name,
      seq_rg_json_name
    )

    payloadCephSubmission_RG(
      file(credentials_file),
      metadataValidation.out.payload,
      metadataValidation.out.metadata,
      endpoint_url,
      bucket_name
    )

    if (seq_files != 'NO_FILE') {
      Channel
        .fromPath(seq_files, checkIfExists: true)
        .set { input_files }
    } else {
      scoreDownload(
        file(seq_files),
        file(file_tsv),
        repository,
        file(token_file)
      )
      input_files = scoreDownload.out.download_file
    }

    seqValidation(
      metadataValidation.out.metadata,
      input_files.collect()
    )

    seqDataToLaneBamWf(
       metadataValidation.out.metadata,
       input_files.collect(),
       reads_max_discard_fraction
    )
    // seqDataToLaneBamWf.out.lane_bams.view()
    // seqDataToLaneBamWf.out.bundle_type.view()

    payloadGenAndS3Submit_LS(
      seqDataToLaneBamWf.out.bundle_type,
      payload_schema_version,
      metadataValidation.out.metadata,  // user submitted metadata
      seqDataToLaneBamWf.out.lane_bams.flatten(),  // files_to_upload_ch
      Channel.fromPath('NO_FILE').first(),  // sec_file, first() turns it to singleton channnel
      Channel.fromPath('NO_FILE_2').first(),  // analysis_input_payload, no need here
      "",  // wf_short_name, optional
      "",  // wf_version, optional
      file(credentials_file),
      endpoint_url,
      bucket_name
    )

    s3Upload_LS(
      endpoint_url,
      bucket_name,
      seqDataToLaneBamWf.out.bundle_type,
      payloadGenAndS3Submit_LS.out.payload.collect(),
      file(credentials_file),
      seqDataToLaneBamWf.out.lane_bams.flatten(),
      Channel.fromPath('NO_FILE').first()
    )

    bwaMemAligner(
      seqDataToLaneBamWf.out.lane_bams.flatten(),
      aligned_lane_prefix,
      cpus_align,
      file(ref_genome_gz),
      Channel.fromPath(getBwaSecondaryFiles(ref_genome_gz), checkIfExists: true).collect()
    )
    // bwaMemAligner.out.aligned_bam.view()

    bamMergeSortMarkdup(
      bwaMemAligner.out.aligned_bam.collect(),
      file(ref_genome),
      Channel.fromPath(getFaiFile(ref_genome), checkIfExists: true).collect(),
      cpus_mkdup,
      seqDataToLaneBamWf.out.aligned_basename,
      markdup,
      aligned_seq_output_format,
      lossy
    )
    // bamMergeSortMarkdup.out.merged_seq.view()
    // bamMergeSortMarkdup.out.merged_seq_idx.view()
    // bamMergeSortMarkdup.out.duplicates_metrics.view()

    payloadGenAndS3Submit_AS(
      'dna_alignment',
      payload_schema_version,
      metadataValidation.out.metadata,  // user submitted metadata
      bamMergeSortMarkdup.out.merged_seq,  // files_to_upload_ch
      bamMergeSortMarkdup.out.merged_seq_idx,  // sec_files_to_upload
      payloadGenAndS3Submit_LS.out.payload,  // analysis_input_payload, these are lane-seq payloads
      "",  // wf_short_name, optional
      "",  // wf_version, optional
      file(credentials_file),
      endpoint_url,
      bucket_name
    )

    s3Upload_AS(
      endpoint_url,
      bucket_name,
      'dna_alignment',
      payloadGenAndS3Submit_AS.out.payload,
      file(credentials_file),
      bamMergeSortMarkdup.out.merged_seq,
      bamMergeSortMarkdup.out.merged_seq_idx
    )
  emit:
    metadata = metadataValidation.out.metadata
    rg_payload = payloadCephSubmission_RG.out.payload
    ls_payload = payloadGenAndS3Submit_LS.out.payload
    as_payload = payloadGenAndS3Submit_AS.out.payload

}

workflow {
  main:
    DnaSeqAlignmentWf(
      params.meta_format,
      params.exp_tsv,
      params.rg_tsv,
      params.file_tsv,
      params.exp_json,
      params.seq_exp_json_name,
      params.seq_rg_json_name,
      params.seq_files,
      params.repository,
      params.token_file,
      params.ref_genome_gz,
      params.ref_genome,
      params.cpus_align,
      params.cpus_mkdup,
      params.reads_max_discard_fraction,
      params.aligned_lane_prefix,
      params.markdup,
      params.lossy,
      params.aligned_seq_output_format,
      params.payload_schema_version,
      params.credentials_file,
      params.endpoint_url,
      params.bucket_name
    )

  publish:
    DnaSeqAlignmentWf.out.metadata to: "outdir", mode: 'copy', overwrite: true
    DnaSeqAlignmentWf.out.rg_payload to: "outdir", mode: 'copy', overwrite: true
    DnaSeqAlignmentWf.out.ls_payload to: "outdir", mode: 'copy', overwrite: true
    DnaSeqAlignmentWf.out.as_payload to: "outdir", mode: 'copy', overwrite: true
}
