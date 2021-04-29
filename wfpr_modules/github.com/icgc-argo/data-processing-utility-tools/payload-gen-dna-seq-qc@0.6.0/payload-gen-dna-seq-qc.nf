#!/usr/bin/env nextflow

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
 * Authors:
 *   Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.enable.dsl=2
version = '0.5.3.0'

params.seq_experiment_analysis = ""
params.qc_files = []
params.wf_name = ""
params.wf_version = ""
params.container_version = ""
params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""


process payloadGenDnaSeqQc {
  container "quay.io/icgc-argo/payload-gen-dna-seq-qc:payload-gen-dna-seq-qc.${params.container_version ?: version}"
  cpus params.cpus
  memory "${params.mem} GB"
  publishDir "${params.publish_dir}/${task.process.replaceAll(':', '_')}", mode: "copy", enabled: "${params.publish_dir ? true : ''}"

  input:
    path seq_experiment_analysis
    path qc_files
    val wf_name
    val wf_version

  output:
    path "*.dna_seq_qc.payload.json", emit: payload
    path "out/*.tgz", emit: qc_files

  script:
    """
    payload-gen-dna-seq-qc.py \
      -a ${seq_experiment_analysis} \
      -f ${qc_files} \
      -w "${wf_name}" \
      -r ${workflow.runName} \
      -s ${workflow.sessionId} \
      -v ${wf_version}
    """
}
