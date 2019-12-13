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
 *          Linda Xiang <linda.xiang@oicr.on.ca>
 */

nextflow.preview.dsl=2
name = 'sequencing-data-submission'
version = "0.1.0.0"

params.exp_tsv = "data/experiment.tsv"
params.rg_tsv = "data/read_group.tsv"
params.file_tsv = "data/file.tsv"
params.token_file = "/home/ubuntu/.access_token"
params.token_file_legacy_data = ""
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"


include metadataValidation from "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.0.1.3.1/tools/metadata-validation/metadata-validation.nf" params(params)
include seqValidation from "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-validation.0.1.4.1/tools/seq-validation/seq-validation.nf" params(params)
include SeqExperimentUpload from "../seq-experiment-upload" params(params)


process getDataFiles{
  container "ubuntu:18.04"

  input:
    path file_tsv
    path metadata
  output:
    path "*.{bam,fastq,fastq.gz,fastq.bz2,fq,fq.gz,fq.bz2}", emit: files_to_submit
  script:
    """
    cols=(\$(head -1 ${file_tsv}))
    PATH_I=0
    for i in \${!cols[@]}; do
      if [ \${cols[\$i]} == "path" ]; then
        PATH_I=\$i
        break
      fi
    done

    (( PATH_I += 1 ))
    DIR=\$(dirname \$(realpath ${file_tsv}))

    for f in \$(tail -n +2 ${file_tsv} | cut -f \$PATH_I |sort -u); do
      if [[ \$f == /* ]] ; then
        ln -s \$f .
      else
        ln -s \$DIR/\$f .
      fi
    done
    """
}


workflow SequencingDataSubmission {
  get:
    exp_tsv
    rg_tsv
    file_tsv
    token_file
    token_file_legacy_data
    song_url
    score_url

  main:
    // Validate metadata
    metadataValidation('tsv', '', exp_tsv, rg_tsv,
        file_tsv, "seq_exp.json", "seq_rg.json")

    getDataFiles(file_tsv, metadataValidation.out.metadata)
    files_to_submit = getDataFiles.out.files_to_submit

    // validate sequencing files (FASTQ or BAM)
    seqValidation(metadataValidation.out.metadata, files_to_submit.collect())

    // create SONG entry for sequencing experiment and (upload if it's submission)
    SeqExperimentUpload(metadataValidation.out.metadata, name, version,
        files_to_submit.collect(), song_url, score_url, token_file, 'true')


  emit: // outputs
    metadata = metadataValidation.out.metadata
    seq_expriment_analysis = SeqExperimentUpload.out.seq_expriment_analysis
}


workflow {
  main:
    SequencingDataSubmission(
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv),
      params.token_file,
      params.token_file_legacy_data,
      params.song_url,
      params.score_url
    )

  publish:
    SequencingDataSubmission.out.metadata to: "outdir", overwrite: true
    SequencingDataSubmission.out.seq_expriment_analysis to: "outdir", overwrite: true
}
