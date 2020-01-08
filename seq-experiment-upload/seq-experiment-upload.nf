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

params.user_submit_metadata = "data/seq-exp.fq.metadata.json"
params.wf_name = ""
params.wf_short_name = ""
params.wf_version = ""
params.files_to_upload = [
  "data/C0HVY.2_r1.fq",
  "data/C0HVY.2_r2.fq",
  "data/D0RE2.1_r1.fq",
  "data/D0RE2.1_r2.fq",
  "data/D0RH0.2_r1.fq",
  "data/D0RH0.2_r2.fq"
]
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"
params.token_file = "/home/ubuntu/.access_token"
params.is_submission = false

include payloadGenSeqExperiment from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-seq-experiment.0.1.1.0/tools/payload-gen-seq-experiment/payload-gen-seq-experiment.nf" params(params)
include SongPayloadUpload from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-payload-upload.0.1.1.0/tools/song-payload-upload/song-payload-upload.nf" params(params)
include songAnalysisGet from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-get.0.1.1.0/tools/song-analysis-get/song-analysis-get.nf" params(params)
include scoreManifestGen from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-manifest-gen.0.1.0.0/tools/score-manifest-gen/score-manifest-gen.nf" params(params)
include scoreUpload from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-upload.0.1.0.0/tools/score-upload/score-upload.nf" params(params)
include songAnalysisPublish from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-publish.0.1.0.0/tools/song-analysis-publish/song-analysis-publish.nf" params(params)


workflow SeqExperimentUpload {
  get:
    user_submit_metadata
    wf_name
    wf_short_name
    wf_version
    files_to_upload
    song_url
    score_url
    token_file
    is_submission
    seq_valid

  main:
    payloadGenSeqExperiment(user_submit_metadata, wf_name, wf_short_name, wf_version, seq_valid)

    SongPayloadUpload(song_url, payloadGenSeqExperiment.out.payload, token_file)

    songAnalysisGet(SongPayloadUpload.out.analysis_id, SongPayloadUpload.out.study, song_url, token_file)

    if (is_submission) {
      scoreManifestGen(songAnalysisGet.out.song_analysis, files_to_upload)

      scoreUpload(scoreManifestGen.out.manifest_file, files_to_upload, token_file, song_url, score_url)

      songAnalysisPublish(SongPayloadUpload.out.analysis_id, SongPayloadUpload.out.study, scoreUpload.out[0], song_url, token_file)
    }

  emit:
    seq_expriment_payload = payloadGenSeqExperiment.out.payload
    seq_expriment_analysis = songAnalysisGet.out.song_analysis
}

workflow {
  SeqExperimentUpload(
    file(params.user_submit_metadata),
    params.wf_name,
    params.wf_short_name,
    params.wf_version,
    Channel.fromPath(params.files_to_upload).collect(),
    params.song_url,
    params.score_url,
    params.token_file,
    params.is_submission,
    'ok'
  )

  publish:
    SeqExperimentUpload.out.seq_expriment_payload to: "outdir", overwrite: true
    SeqExperimentUpload.out.seq_expriment_analysis to: "outdir", overwrite: true
}
