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

params.song_analysis = ""
params.files = ""

process scoreManifestGen {
  container "quay.io/icgc-argo/score-manifest-gen:score-manifest-gen.0.1.1.0"

  input:
    path song_analysis
    path files

  output:
    path "*.manifest.txt", emit: manifest_file

  script:
    """
    score-manifest-gen.py -s ${song_analysis} -f ${files}
    """
}

workflow {
  main:
    scoreManifestGen(
      file(params.song_analysis),
      Channel.fromPath(params.files).collect()
    )

  publish:
    scoreManifestGen.out.manifest_file to: 'outdir', mode: 'copy', overwrite: true
}
