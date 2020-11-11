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

nextflow.enable.dsl=2
version = '4.1.8.0-1.0'

params.seq = ""
params.seq_idx = ""
params.interval_file = "NO_FILE"
params.container_version = ""
params.ref_genome_fa = ""
params.cpus = 1
params.mem = 2  // in GB

def getOxogSecondaryFiles(main_file){  //this is kind of like CWL's secondary files
  def all_files = []
  all_files.add(main_file + '.fai')
  all_files.add(main_file.take(main_file.lastIndexOf('.')) + '.dict')
  return all_files
}

process gatkCollectOxogMetrics {
  container "quay.io/icgc-argo/gatk-collect-oxog-metrics:gatk-collect-oxog-metrics.${params.container_version ?: version}"
  cpus params.cpus
  memory "${params.mem} GB"

  input:
    path seq
    path seq_idx
    path ref_genome_fa
    path ref_genome_secondary_file
    path interval_file
    val dependencies

  output:
    path "*.oxog_metrics.tgz", emit: oxog_metrics

  script:
    arg_interval_file = interval_file.name == 'NO_FILE' ? "" : "-i ${interval_file}"
    """
    gatk-collect-oxog-metrics.py -s ${seq} \
                      -r ${ref_genome_fa} \
                      -m ${(int) (params.mem * 1000)} ${arg_interval_file}
    """
}


process gatherOxogMetrics {
  container "quay.io/icgc-argo/gatk-collect-oxog-metrics:gatk-collect-oxog-metrics.${params.container_version ?: version}"
  cpus params.cpus
  memory "${params.mem} GB"

  input:
    path oxog_metrics_files

  output:
    path "out/*.oxog_metrics.tgz", emit: oxog_metrics

  script:
    """
    gather-oxog-metrics.py -m ${oxog_metrics_files}
    """
}
