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

params.analysis_id = ""
params.study = ""
params.song_url = ""
params.token_file = ""
params.score_upload_status = ""


process songAnalysisPublish {
  container "quay.io/icgc-argo/song-analysis-publish:song-analysis-publish.0.1.0.0"

  input:
    val analysis_id
    val study
    val score_upload_status
    val song_url
    path token_file

  output:
    stdout()

  script:
    """
    song-analysis-publish.py -a ${analysis_id} -p ${study} -s ${song_url} -t ${token_file}
    """
}

workflow {
  songAnalysisPublish(
    params.analysis_id,
    params.study,
    params.score_upload_status,
    params.song_url,
    file(params.token_file)
  )
  songAnalysisPublish.out[0].view()
}
