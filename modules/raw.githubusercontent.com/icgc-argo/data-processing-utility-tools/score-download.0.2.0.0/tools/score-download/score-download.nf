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

params.manifest_file = ""
params.song_url = ""
params.score_url = ""
params.token_file = ""

process scoreDownload {
  container "quay.io/icgc-argo/score-download:score-download.0.2.0.0"

  input:
    path manifest_file
    path token_file
    val song_url
    val score_url

  output:
    path "*", emit: downloaded_files

  script:
    """
    score-download.py -m ${manifest_file} -s ${song_url} -c ${score_url} -t ${token_file}
    """
}

workflow {
  main:
    scoreDownload(
      file(params.manifest_file),
      file(params.token_file),
      params.song_url,
      params.score_url
    )
  publish:
    scoreDownload.out.downloaded_files to: 'outdir', mode: 'copy', overwrite: true
}
