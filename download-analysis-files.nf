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

include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-seq-experiment.0.1.0.0/tools/payload-gen-seq-experiment/payload-gen-seq-experiment.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-read-group-ubam.0.1.0.0/tools/payload-gen-read-group-ubam/payload-gen-read-group-ubam.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-alignment.0.1.0.0/tools/payload-gen-dna-alignment/payload-gen-dna-alignment.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-payload-upload.0.1.0.0/tools/song-payload-upload/song-payload-upload.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-manifest-gen.0.1.0.0/tools/score-manifest-gen/score-manifest-gen.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-upload.0.1.0.0/tools/score-upload/score-upload.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-publish.0.1.0.0/tools/song-analysis-publish/song-analysis-publish.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-get.0.1.0.0/tools/song-analysis-get/song-analysis-get.nf"
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-download.0.2.0.0/tools/score-download/score-download.nf"


workflow SongScoreUpload {
  get:
  main:
  emit:
}

workflow {

}
