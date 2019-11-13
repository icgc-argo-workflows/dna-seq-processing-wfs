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

params.meta_format = "tsv"
params.exp_tsv = "tests/input/experiment-fq.sm.tsv"
params.rg_tsv = "tests/input/read_group-fq.sm.tsv"
params.file_tsv = "tests/input/file-fq.sm.tsv"
params.exp_json = ""  // optional json string of exp metadata
params.seq_exp_json_name = "seq_exp.json"
params.seq_rg_json_name = "seq_rg.json"
params.seq_files = "NO_FILE"
params.repository = "collab"
params.token_file = "/Users/junjun/access_token"
params.ref_genome_gz = "tests/reference/tiny-grch38-chr11-530001-537000.fa.gz"
params.ref_genome = "tests/reference/tiny-grch38-chr11-530001-537000.fa"
params.cpus_align = 1
params.cpus_mkdup = 1
params.reads_max_discard_fraction = 0.08
params.aligned_lane_prefix = "grch38-aligned"
params.markdup = true
params.aligned_seq_output_format = "cram"
params.payload_schema_version = "0.1.0-rc.2"
params.credentials_file ="/Users/junjun/credentials"
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "argo-test"


include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.0.1.3.1/tools/metadata-validation/metadata-validation.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-download.0.1.5.1/tools/score-download/score-download.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-validation.0.1.4.1/tools/seq-validation/seq-validation.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.1.5.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.2.1/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.4.1/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(params)

include payloadCephSubmission as payloadCephSubmission_RG from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-ceph-submission.0.1.7.0/tools/payload-ceph-submission/payload-ceph-submission.nf" params(params)

include payloadGenAndS3Submit as payloadGenAndS3Submit_LS from "./modules/payload-gen-and-s3-submit.nf" params(params)
include payloadGenAndS3Submit as payloadGenAndS3Submit_AS from "./modules/payload-gen-and-s3-submit.nf" params(params)

include s3Upload as s3Upload_LS from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/s3-upload.0.1.6.0/tools/s3-upload/s3-upload.nf" params(params)
include s3Upload as s3Upload_AS from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/s3-upload.0.1.6.0/tools/s3-upload/s3-upload.nf" params(params)
include getSecondaryFile as getUploadSecondaryFile from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/s3-upload.0.1.6.0/tools/s3-upload/s3-upload.nf" params(params)


workflow {
  main:
    metadataValidation(
      params.meta_format,
      params.exp_json,
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv),
      params.seq_exp_json_name,
      params.seq_rg_json_name
    )
    payloadCephSubmission_RG(
      file(params.credentials_file),
      metadataValidation.out.payload,
      metadataValidation.out.metadata,
      params.endpoint_url,
      params.bucket_name
    )
    if (params.seq_files != 'NO_FILE') {
      Channel
        .fromPath(params.seq_files, checkIfExists: true)
        .set { input_files }
    } else {
      scoreDownload(
        file(params.seq_files),
        file(params.file_tsv),
        params.repository,
        file(params.token_file)
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
       params.reads_max_discard_fraction
    )

    payloadGenAndS3Submit_LS(
      seqDataToLaneBamWf.out.bundle_type,
      params.payload_schema_version,
      metadataValidation.out.metadata,  // user submitted metadata
      seqDataToLaneBamWf.out.lane_bams,  // files_to_upload_ch
      Channel.fromPath('NO_FILE'),  // sec_file
      Channel.fromPath('NO_FILE_2'),  // analysis_input_payload, no need here
      "",  // wf_short_name, optional
      "",  // wf_version, optional
      file(params.credentials_file),
      params.endpoint_url,
      params.bucket_name
    )

    s3Upload_LS(
      params.endpoint_url,
      params.bucket_name,
      seqDataToLaneBamWf.out.bundle_type,
      payloadGenAndS3Submit_LS.out.payload,
      file(params.credentials_file),
      seqDataToLaneBamWf.out.lane_bams,
      Channel.fromPath('NO_FILE')
    )

    Channel
      .fromPath(getBwaSecondaryFiles(params.ref_genome_gz), checkIfExists: true)
      .set { ref_genome_gz_ch }

    bwaMemAligner(
      seqDataToLaneBamWf.out.lane_bams,
      params.aligned_lane_prefix,
      params.cpus_align,
      file(params.ref_genome_gz),
      ref_genome_gz_ch.collect()
    )
    bwaMemAligner.out.aligned_bam.view()

    Channel
      .fromPath(getFaiFile(params.ref_genome), checkIfExists: true)
      .set { ref_genome_fai_ch }

    bamMergeSortMarkdup(
      bwaMemAligner.out.aligned_bam.collect(),
      file(params.ref_genome),
      ref_genome_fai_ch.collect(),
      params.cpus_mkdup,
      seqDataToLaneBamWf.out.aligned_basename,
      params.markdup,
      params.aligned_seq_output_format,
      false
    )
    bamMergeSortMarkdup.out.merged_seq.view()
    bamMergeSortMarkdup.out.merged_seq_idx.view()
    bamMergeSortMarkdup.out.duplicates_metrics.view()

    payloadGenAndS3Submit_AS(
      'dna_alignment',
      params.payload_schema_version,
      metadataValidation.out.metadata,  // user submitted metadata
      bamMergeSortMarkdup.out.merged_seq,  // files_to_upload_ch
      bamMergeSortMarkdup.out.merged_seq_idx,  // sec_files_to_upload
      payloadGenAndS3Submit_LS.out.payload,  // analysis_input_payload, these are lane-seq payloads
      "",  // wf_short_name, optional
      "",  // wf_version, optional
      file(params.credentials_file),
      params.endpoint_url,
      params.bucket_name
    )

    s3Upload_AS(
      params.endpoint_url,
      params.bucket_name,
      'dna_alignment',
      payloadGenAndS3Submit_AS.out.payload,
      file(params.credentials_file),
      bamMergeSortMarkdup.out.merged_seq,
      bamMergeSortMarkdup.out.merged_seq_idx
    )

  publish:
    metadataValidation.out.metadata to: "outdir", mode: 'copy', overwrite: true
    metadataValidation.out.payload to: "outdir", mode: 'copy', overwrite: true
    payloadGenAndS3Submit_LS.out.payload to: "outdir", mode: 'copy', overwrite: true
    payloadGenAndS3Submit_AS.out.payload to: "outdir", mode: 'copy', overwrite: true
}
