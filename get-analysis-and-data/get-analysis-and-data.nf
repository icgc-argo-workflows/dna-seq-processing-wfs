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
 */


nextflow.preview.dsl=2
name = 'get-analysis-and-data'

params.analysis_id = "a866ae59-acdc-424a-a6ae-59acdc424a7a"
params.program_id = "TEST-PRO"
params.token_file = "/Users/junjun/.access_token"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"


include songAnalysisGet from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-get.0.1.1.0/tools/song-analysis-get/song-analysis-get.nf" params(params)
include FileProvisioner as FP from "../modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/file-provisioner.0.1.0.1/tools/file-provisioner/file-provisioner.nf" params(params)


process getFilePaths {

  container "cfmanteiga/alpine-bash-curl-jq:latest"

  input:
    path song_analysis

  output:
    path "file_paths.csv", emit: file_paths

  script:
    """
    analysis_id=(\$(cat ${song_analysis} | jq --raw-output '.analysisId'))

    echo "path" >> file_paths.csv

    for o in \$(cat ${song_analysis} | jq --raw-output '.file[].objectId'); do
      echo "score://collab/\$analysis_id/\$o" >> file_paths.csv
    done
    """
}


workflow GetAnalysisAndData {
  get:
    analysis_id
    token_file

  main:
    songAnalysisGet(analysis_id, params.program_id, params.song_url, token_file)
    getFilePaths(songAnalysisGet.out.song_analysis)
    file_paths = getFilePaths.out.file_paths.splitCsv(header:true).map{ row->row.path }
    FP(file_paths.flatten(), token_file, params.song_url, params.score_url)

  emit:
    analysis = songAnalysisGet.out.song_analysis
    files = FP.out.file
}

workflow {
  main:
    GetAnalysisAndData(
      params.analysis_id,
      file(params.token_file)
    )

  publish:
    GetAnalysisAndData.out.analysis to: "outdir", overwrite: true
    GetAnalysisAndData.out.files to: "outdir", overwrite: true
}
