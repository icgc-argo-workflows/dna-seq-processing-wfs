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
 * Author: Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2

params.read_group_ubam_analysis = []
params.files_to_upload = [
  "data/HCC1143_BAM_INPUT.3.20190812.wgs.grch38.bam",
  "data/HCC1143_BAM_INPUT.3.20190812.wgs.grch38.bam.bai"
]
params.wf_name = ""
params.wf_short_name = ""
params.wf_version = ""
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"
params.token_file = "/home/ubuntu/.access_token"


include payloadGenDnaAlignment from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-alignment.0.1.2.0/tools/payload-gen-dna-alignment/payload-gen-dna-alignment.nf" params(params)
include SongPayloadUpload as SPU from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-payload-upload.0.1.2.0/tools/song-payload-upload/song-payload-upload.nf" params(params)
include songAnalysisGet from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-get.0.1.1.0/tools/song-analysis-get/song-analysis-get.nf" params(params)
include scoreManifestGen from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-manifest-gen.0.1.1.0/tools/score-manifest-gen/score-manifest-gen.nf" params(params)
include scoreUpload from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-upload.0.1.0.0/tools/score-upload/score-upload.nf" params(params)
include songAnalysisPublish from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-publish.0.1.0.0/tools/song-analysis-publish/song-analysis-publish.nf" params(params)


workflow DnaAlignmentUpload {
  get:
    files_to_upload
    seq_experiment_analysis
    token_file

  main:
    payloadGenDnaAlignment(files_to_upload, seq_experiment_analysis,
      params.read_group_ubam_analysis, params.wf_name, params.wf_short_name, params.wf_version)

    SPU(params.song_url, payloadGenDnaAlignment.out.payload, token_file)

    songAnalysisGet(SPU.out.analysis_id, SPU.out.study, params.song_url, token_file)

    scoreManifestGen(songAnalysisGet.out.song_analysis, payloadGenDnaAlignment.out.alignment_files)

    scoreUpload(scoreManifestGen.out.manifest_file, payloadGenDnaAlignment.out.alignment_files, token_file, params.song_url, params.score_url)

    songAnalysisPublish(SPU.out.analysis_id, SPU.out.study, scoreUpload.out[0], params.song_url, token_file)

  emit:
    dna_seq_alignment_analysis = songAnalysisGet.out.song_analysis
    alignment_files = payloadGenDnaAlignment.out.alignment_files
}

workflow {
  main:
    DnaAlignmentUpload(
      Channel.fromPath(params.files_to_upload).collect(),
      file(params.seq_experiment_analysis),
      file(params.token_file)
    )

  publish:
    DnaAlignmentUpload.out.dna_seq_alignment_analysis to: "outdir", overwrite: true
}
