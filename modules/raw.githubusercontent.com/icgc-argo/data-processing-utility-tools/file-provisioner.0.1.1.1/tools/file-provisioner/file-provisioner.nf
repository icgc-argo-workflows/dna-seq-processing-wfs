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

params.file_path = "/home/ubuntu/A.ARGO/git/data-processing-utility-tools/tools/file-provisioner/tests/work/c1/7ca66bf161590661f7838f64e07e9f/out/f677818e71ecd40145cebca12e17441f.BD233T_CTTGTA_L008_R1_001.fastq.bz2"
//params.file_path = "score://collab/EGAR00001264286/1a5436f1-0268-5f72-88b5-b49628264ff5"
params.token_file = "NO_FILE"
params.song_url = ""
params.score_url = ""
params.transport_mem = 2
params.container_version = '0.1.1.1'

process scoreDownload {
  container "quay.io/icgc-argo/file-provisioner:file-provisioner.${params.container_version}"

  input:
    val file_path
    path token_file
    val song_url
    val score_url

  output:
    path "out/*", emit: downloaded_file

  script:
    args_song_url = song_url.length() > 0 ? "-s ${song_url}" : ""
    args_score_url = score_url.length() > 0 ? "-c ${score_url}" : ""
    """
    score-download.py \
      -p ${file_path} \
      -t ${token_file} ${args_song_url} ${args_score_url} \
      -n ${task.cpus} \
      -y ${params.transport_mem}
    """
}


process localFilePathToFile {
  container "quay.io/icgc-argo/file-provisioner:file-provisioner.${params.container_version}"

  input:
    val file_path

  output:
    path "*", emit: local_file

  script:
    """
    if [[ ${file_path} == score://* ]] ; then
      echo "To download SCORE object, plese provide token file!"
      exit 1
    fi
    BASENAME=\$(basename ${file_path})
    ln -s ${file_path} \$BASENAME
    """
}


workflow FileProvisioner {
  take:
    file_path
    token_file
    song_url
    score_url

  main:
    if (token_file.name != 'NO_FILE') {
      scoreDownload(file_path, token_file, song_url, score_url)
      provisioned_file = scoreDownload.out.downloaded_file

    } else {
      localFilePathToFile(file_path)
      provisioned_file = localFilePathToFile.out.local_file
    }

  emit:
    file = provisioned_file
}


workflow {
  main:
    FileProvisioner(
      Channel.from(params.file_path),
      file(params.token_file),
      params.song_url,
      params.score_url
    )

  publish:
    FileProvisioner.out.file to: 'outdir', overwrite: true
}
