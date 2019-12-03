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

import groovy.json.JsonSlurper

process getStudyAndAnalysisId {
  input:
    val str
  output:
    val meta_info.study, emit: study
    val meta_info.analysisId, emit: analysis_id
  exec:
    meta_info = new JsonSlurper().parseText(str)
}

process songPayloadUploadPr {
  container "quay.io/icgc-argo/song-payload-upload:song-payload-upload.0.1.0.0"

  input:
    val song_url
    path song_payload
    path token_file

  output:
    stdout()

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
      songPayloadUploadPr.out[0]
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
