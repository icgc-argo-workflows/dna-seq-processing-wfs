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

params.upload_files = ""
params.manifest_file = ""
params.song_url = ""
params.score_url = ""

process ScoreUpload {
  container "quay.io/icgc-argo/score-upload:score-upload.0.1.0.0"

  input:
    path manifest_file
    path upload_files
    path token_file
    val song_url
    val score_url

  output:
    stdout()

  script:
    """
    score-upload.py -m ${manifest_file} -s ${song_url} -c ${score_url} -t ${token_file}
    """
}

workflow {
  ScoreUpload(
    file(params.manifest_file),
    Channel.fromPath(params.upload_files).collect(),
    file(params.token_file),
    params.song_url,
    params.score_url
  )
  ScoreUpload.out[0].view()
}
