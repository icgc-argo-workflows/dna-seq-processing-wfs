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
version = '0.2.2.1'

params.seq = ""
params.container_version = ""
params.ref_genome_gz = ""
params.cpus = 1
params.mem = 2  // in GB

def getAlignedQCSecondaryFiles(main_file){  //this is kind of like CWL's secondary files
  def all_files = []
  for (ext in ['.fai', '.gzi']) {
    all_files.add(main_file + ext)
  }
  return all_files
}


process alignedSeqQC {
  container "quay.io/icgc-argo/aligned-seq-qc:aligned-seq-qc.${params.container_version ?: version}"
  cpus params.cpus
  memory "${params.mem} GB"

  input:
    path seq
    path ref_genome_gz
    path ref_genome_gz_secondary_file
    val dependencies

  output:
    path "*.qc_metrics.tgz", emit: metrics

  script:
    """
    aligned-seq-qc.py -s ${seq} \
                      -r ${ref_genome_gz} \
                      -n ${params.cpus}
    """
}
