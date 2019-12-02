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
version = "0.2.3.0"

params.meta_format = "tsv"
params.exp_tsv = ""
params.rg_tsv = ""
params.file_tsv = ""
params.seq_files = "NO_FILE"
params.repository = "collab"
params.token_file = ""
params.token_file_legacy_data = ""
params.ref_genome_gz = ""
params.ref_genome = ""
params.cpus_align = -1  // negative means use default
params.cpus_mkdup = -1  // negative means use default
params.reads_max_discard_fraction = 0.08
params.upload_ubam = false
params.aligned_lane_prefix = "grch38-aligned"
params.markdup = true
params.lossy = false
params.aligned_seq_output_format = "cram"
params.payload_schema_version = "0.1.0-rc.2"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"


include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.0.1.3.1/tools/metadata-validation/metadata-validation.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-download.0.1.5.1/tools/score-download/score-download.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-validation.0.1.4.1/tools/seq-validation/seq-validation.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.1.5.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.2.1/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.4.1/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(params)

include SeqExperimentUpload from "./seq-experiment-upload" params(params)
include ReadGroupUbamUpload from "./read-group-ubam-upload" params(params)
include DnaAlignmentUpload from "./dna-alignment-upload" params(params)

workflow DnaSeqAlignmentWf {
  get:
    meta_format
    exp_tsv
    rg_tsv
    file_tsv
    seq_files
    repository
    token_file
    token_file_legacy_data
    ref_genome_gz
    ref_genome
    cpus_align
    cpus_mkdup
    reads_max_discard_fraction
    upload_ubam
    aligned_lane_prefix
    markdup
    lossy
    aligned_seq_output_format
    payload_schema_version
    song_url
    score_url

  main:
    // Validate metadata
    metadataValidation(meta_format, '', exp_tsv, rg_tsv,
        file_tsv, "seq_exp.json", "seq_rg.json")

    is_submission = false
    if (seq_files != 'NO_FILE') {  // submitting local files
      Channel.fromPath(seq_files, checkIfExists: true).set { input_files }
      is_submission = true
    } else {  // downloading files from Collab (mostly EGA files)
      scoreDownload(file(seq_files), file(file_tsv), repository, file(token_file_legacy_data))
      input_files = scoreDownload.out.download_file
    }

    // create SONG entry for sequencing experiment and (upload if it's submission)
    SeqExperimentUpload(metadataValidation.out.metadata, name, version,
        input_files.collect(), song_url, score_url, token_file, is_submission)

    // validate sequencing files (FASTQ or BAM)
    seqValidation(metadataValidation.out.metadata, input_files.collect())

    // prepare unmapped BAM
    seqDataToLaneBamWf(metadataValidation.out.metadata, input_files.collect(), reads_max_discard_fraction)

    // create SONG entry for read group ubam (and upload data if upload_ubam set to true)
    ReadGroupUbamUpload(SeqExperimentUpload.out.seq_expriment_analysis,
        seqDataToLaneBamWf.out.lane_bams.flatten(), seqDataToLaneBamWf.out.lane_bams.collect(),
        name, version, song_url, score_url, token_file, upload_ubam)

    // BWA alignment for each ubam in scatter
    bwaMemAligner(seqDataToLaneBamWf.out.lane_bams.flatten(), aligned_lane_prefix,
        cpus_align, file(ref_genome_gz),
        Channel.fromPath(getBwaSecondaryFiles(ref_genome_gz), checkIfExists: true).collect())

    // merge aligned lane BAM and mark dups, convert to CRAM if specified
    bamMergeSortMarkdup(bwaMemAligner.out.aligned_bam.collect(), file(ref_genome),
        Channel.fromPath(getFaiFile(ref_genome), checkIfExists: true).collect(),
        cpus_mkdup, seqDataToLaneBamWf.out.aligned_basename, markdup, aligned_seq_output_format, lossy)

    // Create SONG entry for final aligned/merged BAM/CRAM and upload to SCORE server
    DnaAlignmentUpload(
        bamMergeSortMarkdup.out.merged_seq.concat(bamMergeSortMarkdup.out.merged_seq_idx).collect(),
        ReadGroupUbamUpload.out.read_group_ubam_analysis.collect(), name,
        version, song_url, score_url, token_file)

  emit: // outputs
    metadata = metadataValidation.out.metadata
    seq_expriment_analysis = SeqExperimentUpload.out.seq_expriment_analysis
    read_group_ubam_analysis = ReadGroupUbamUpload.out.read_group_ubam_analysis
    read_group_ubam = seqDataToLaneBamWf.out.lane_bams
    dna_seq_alignment_analysis = DnaAlignmentUpload.out.dna_seq_alignment_analysis
    aligned_seq = bamMergeSortMarkdup.out.merged_seq
    aligned_seq_index  = bamMergeSortMarkdup.out.merged_seq_idx
}

workflow {
  main:
    DnaSeqAlignmentWf(
      params.meta_format,
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv),
      params.seq_files,
      params.repository,
      params.token_file,
      params.token_file_legacy_data,
      params.ref_genome_gz,
      params.ref_genome,
      params.cpus_align,
      params.cpus_mkdup,
      params.reads_max_discard_fraction,
      params.upload_ubam,
      params.aligned_lane_prefix,
      params.markdup,
      params.lossy,
      params.aligned_seq_output_format,
      params.payload_schema_version,
      params.song_url,
      params.score_url
    )

  publish:
    DnaSeqAlignmentWf.out.metadata to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.seq_expriment_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.dna_seq_alignment_analysis to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.read_group_ubam to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.aligned_seq to: "outdir", overwrite: true
    DnaSeqAlignmentWf.out.aligned_seq_index to: "outdir", overwrite: true
}
