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

params.song_url = ""
params.song_payload = ""
params.token_file = ""


process getStudyAndAnalysisId {

  input:
    path song_analysis
  output:
    val study, emit: study
    val analysis_id, emit: analysis_id
  exec:
    (full, analysis_id, study) = (song_analysis.baseName =~ /(.+)\.(.+)\.analysis/)[0]
}

process songPayloadUploadPr {
  container "quay.io/icgc-argo/song-payload-upload:song-payload-upload.0.1.2.0"

  input:
    val song_url
    path song_payload
    path token_file

  output:
    path "*.analysis.json", emit: song_analysis

  script:
    """
    song-payload-upload.py -p ${song_payload} -s ${song_url} -t ${token_file}
    """
}

workflow SongPayloadUpload{
  get:
    song_url
    song_payload
    token_file

  main:
    songPayloadUploadPr(
      song_url,
      song_payload,
      token_file
    )

    getStudyAndAnalysisId(
      songPayloadUploadPr.out.song_analysis
    )

  emit:
    study = getStudyAndAnalysisId.out.study
    analysis_id = getStudyAndAnalysisId.out.analysis_id
}

workflow {
  SongPayloadUpload(
    params.song_url,
    file(params.song_payload),
    file(params.token_file)
  )

  SongPayloadUpload.out.study.view()
  SongPayloadUpload.out.analysis_id.view()
}
