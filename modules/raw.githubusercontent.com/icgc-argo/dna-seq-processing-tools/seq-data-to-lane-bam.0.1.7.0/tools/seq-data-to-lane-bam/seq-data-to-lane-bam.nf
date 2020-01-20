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
 * author Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2
version = '0.1.7.0'

params.metadata_json = ""
params.seq_files = ""
params.reads_max_discard_fraction = -1
params.container_version = ''


process seqDataToLaneBam {
  container "quay.io/icgc-argo/seq-data-to-lane-bam:seq-data-to-lane-bam.${params.container_version ?: version}"

  input:
    path metadata_json
    path seq_files
    val reads_max_discard_fraction

  output:
    path "*.lane.bam", emit: lane_bams

  script:
    reads_max_discard_fraction = reads_max_discard_fraction < 0 ? 0.05: reads_max_discard_fraction
    """
    seq-data-to-lane-bam.py \
      -p ${metadata_json} \
      -d ${seq_files} \
      -m ${reads_max_discard_fraction}
    """
}
