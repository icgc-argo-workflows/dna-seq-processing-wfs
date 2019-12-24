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
 * Authors: Junjun Zhang <junjun.zhang@oicr.on.ca>
 *          Linda Xiang <linda.xiang@oicr.on.ca>
 */

nextflow.preview.dsl=2
name = 'dna-seq-alignment'

params.exp_tsv = "data/experiment-fq.v2.tsv"
params.rg_tsv = "data/read_group-fq.v2.tsv"
params.file_tsv = "data/file-fq.v2.tsv"
params.token_file = "/home/ubuntu/.access_token"
params.token_file_legacy_data = ""
params.ref_genome_fa = "reference/tiny-grch38-chr11-530001-537000.fa"
params.cpus_align = -1  // negative means use default
params.cpus_mkdup = -1  // negative means use default
params.reads_max_discard_fraction = 0.08
params.upload_ubam = false
params.aligned_lane_prefix = "grch38-aligned"
params.markdup = true
params.lossy = false
params.aligned_seq_output_format = "bam"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"


include "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.1.6.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(params)
include "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.2.1/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(params)
include "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.4.1/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(params)

include SequencingDataSubmission as SequencingDataMigration from "../sequencing-data-submission/main.nf" params(
  "song_url": params.song_url, "score_url": params.score_url, "token_file": params.token_file
)

include ReadGroupUbamUpload from "../read-group-ubam-upload/read-group-ubam-upload.nf" params(
  "wf_name": name, "wf_version": workflow.manifest.version, "song_url": params.song_url,
  "score_url": params.score_url, "token_file": params.token_file, "upload_ubam": params.upload_ubam
)

include DnaAlignmentUpload from "../dna-alignment-upload/dna-alignment-upload.nf" params(
  "wf_name": name, "wf_version": workflow.manifest.version, "song_url": params.song_url,
  "score_url": params.score_url, "token_file": params.token_file
)

workflow DnaSeqAlignmentWf {
  get:
    exp_tsv
    rg_tsv
    file_tsv
    reads_max_discard_fraction

  main:
    SequencingDataMigration(exp_tsv, rg_tsv, file_tsv)

    // prepare unmapped BAM
    seqDataToLaneBam(
      SequencingDataMigration.out.seq_expriment_analysis,
      SequencingDataMigration.out.files_to_submit.collect(),
      reads_max_discard_fraction
    )

    // create SONG entry for read group ubam (and upload data if upload_ubam set to true)
    ReadGroupUbamUpload(SequencingDataMigration.out.seq_expriment_analysis,
        seqDataToLaneBam.out.lane_bams.flatten(), seqDataToLaneBam.out.lane_bams.collect())

    // BWA alignment for each ubam in scatter
    bwaMemAligner(seqDataToLaneBam.out.lane_bams.flatten(), params.aligned_lane_prefix,
        params.cpus_align, file(params.ref_genome_fa + ".gz"),
        Channel.fromPath(getBwaSecondaryFiles(params.ref_genome_fa + ".gz"), checkIfExists: true).collect())

    // merge aligned lane BAM and mark dups, convert to CRAM if specified
    bamMergeSortMarkdup(bwaMemAligner.out.aligned_bam.collect(), file(params.ref_genome_fa),
        Channel.fromPath(getFaiFile(params.ref_genome_fa), checkIfExists: true).collect(),
        params.cpus_mkdup, 'aligned_seq_basename', params.markdup,
        params.aligned_seq_output_format, params.lossy)

    // Create SONG entry for final aligned/merged BAM/CRAM and upload to SCORE server
    DnaAlignmentUpload(
        bamMergeSortMarkdup.out.merged_seq.concat(bamMergeSortMarkdup.out.merged_seq_idx).collect(),
        SequencingDataMigration.out.seq_expriment_analysis,
        ReadGroupUbamUpload.out.read_group_ubam_analysis.collect())

  emit: // outputs
    metadata = SequencingDataMigration.out.metadata
    seq_expriment_payload = SequencingDataMigration.out.seq_expriment_payload
    seq_expriment_analysis = SequencingDataMigration.out.seq_expriment_analysis
    read_group_ubam = seqDataToLaneBam.out.lane_bams
    read_group_ubam_analysis = ReadGroupUbamUpload.out.read_group_ubam_analysis
    alignment_files = DnaAlignmentUpload.out.alignment_files
    dna_seq_alignment_analysis = DnaAlignmentUpload.out.dna_seq_alignment_analysis
}

workflow {
  main:
    DnaSeqAlignmentWf(
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv),
      params.reads_max_discard_fraction
    )

  publish:
    DnaSeqAlignmentWf.out.metadata to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.seq_expriment_payload to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.seq_expriment_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.alignment_files to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.dna_seq_alignment_analysis to: "outdir", overwrite: true
}
