#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019-2020, Ontario Institute for Cancer Research (OICR).
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
 * author Junjun Zhang <junjun.zhang@oicr.on.ca>
 *        Linda Xiang <linda.xiang@oicr.on.ca>
 */

nextflow.preview.dsl=2
version = '0.2.0.0'

params.seq = ""
params.container_version = ""
params.ref_genome = ""
params.rdup = false
params.required_flag = ""
params.filtering_flag = ""


process alignedSeqQC {
  container "quay.io/icgc-argo/aligned-seq-qc:aligned-seq-qc.${params.container_version ?: version}"

  input:
    path seq
    path ref_genome
    val rdup
    val required_flag
    val filtering_flag

  output:
    path "*.qc_metrics.tgz", emit: metrics

  script:
    arg_rdup = rdup ? "-d" : ""
    arg_required_flag = required_flag ? "-f ${required_flag}" : ""
    arg_filtering_flag = filtering_flag ? "-F ${filtering_flag}" : ""
    """
    aligned-seq-qc.py -s ${seq} \
                      -r ${ref_genome} \
                      -n ${task.cpus} \
                      ${arg_rdup} \
                      ${arg_required_flag} \
                      ${arg_filtering_flag}
    """
}