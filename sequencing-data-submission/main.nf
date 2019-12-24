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
short_name = 'seq-submission'

params.wf_name = name
params.wf_short_name = short_name
params.wf_version = workflow.manifest.version
params.exp_tsv = "data/experiment.v2.tsv"
params.rg_tsv = "data/read_group.v2.tsv"
params.file_tsv = "data/file.v2.tsv"
params.token_file = "/home/ubuntu/.access_token"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"

include metadataValidation from "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/metadata-validation.0.1.4.0/tools/metadata-validation/metadata-validation.nf" params(params)
include seqValidation from "../modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-validation.0.1.5.0/tools/seq-validation/seq-validation.nf" params(params)
include SeqExperimentUpload from "../seq-experiment-upload/seq-experiment-upload.nf" params(params)


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

  main:
    // Validate metadata
    metadataValidation(exp_tsv, rg_tsv, file_tsv)

    getDataFiles(file_tsv, metadataValidation.out.metadata)
    files_to_submit = getDataFiles.out.files_to_submit

    // validate sequencing files (FASTQ or BAM)
    seqValidation(metadataValidation.out.metadata, files_to_submit.collect())
    //seqValidation.out[0].view()

    // create SONG entry for sequencing experiment and upload
    SeqExperimentUpload(metadataValidation.out.metadata, params.wf_name, params.wf_short_name, params.wf_version,
      files_to_submit.collect(), params.song_url, params.score_url, params.token_file, 'true')

  emit: // outputs
    metadata = metadataValidation.out.metadata
    files_to_submit = files_to_submit
    seq_expriment_payload = SeqExperimentUpload.out.seq_expriment_payload
    seq_expriment_analysis = SeqExperimentUpload.out.seq_expriment_analysis
}


workflow {
  main:
    SequencingDataSubmission(
      file(params.exp_tsv),
      file(params.rg_tsv),
      file(params.file_tsv)
    )

  publish:
    SequencingDataSubmission.out.metadata to: "outdir", overwrite: true
    SequencingDataSubmission.out.files_to_submit to: "outdir", overwrite: true
    SequencingDataSubmission.out.seq_expriment_payload to: "outdir", overwrite: true
    SequencingDataSubmission.out.seq_expriment_analysis to: "outdir", overwrite: true
}
