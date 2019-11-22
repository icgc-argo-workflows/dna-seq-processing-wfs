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
 * author Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2

import groovy.json.JsonSlurper

params.seq_rg_json = "tests/input/seq_rg.json"
params.seq_files = "tests/input/test_rg_3.bam"
params.reads_max_discard_fraction = -1

// https://groups.google.com/forum/#!msg/nextflow/qzsORfO5CFU/pYh-tEWXAgAJ
process getBasenameAndBundleType {
  input:
    val str
  output:
    val meta_info.aligned_basename, emit: aligned_basename
    val meta_info.bundle_type, emit: bundle_type
  exec:
    meta_info = new JsonSlurper().parseText(str)
}

process seqDataToLaneBam {
  container 'quay.io/icgc-argo/seq-data-to-lane-bam:seq-data-to-lane-bam.0.1.5.0'

  input:
    path seq_rg_json
    //tuple sampleId, file(seq_files)
    path seq_files
    val reads_max_discard_fraction

  output:
    stdout()
    path "*.lane.bam", emit: lane_bams

  script:
    reads_max_discard_fraction = reads_max_discard_fraction < 0 ? 0.05: reads_max_discard_fraction
    """
    export TMPDIR=/tmp
    seq-data-to-lane-bam.py \
      -p ${seq_rg_json} \
      -d ${seq_files} \
      -m ${reads_max_discard_fraction}
    """
}

workflow seqDataToLaneBamWf {
  get:
    seq_rg_json
    seq_files
    reads_max_discard_fraction
  main:
    seqDataToLaneBam(
      seq_rg_json,
      seq_files,
      reads_max_discard_fraction
    )

    getBasenameAndBundleType(
      seqDataToLaneBam.out[0]
    )

  emit:
    lane_bams = seqDataToLaneBam.out.lane_bams
    aligned_basename = getBasenameAndBundleType.out.aligned_basename
    bundle_type = getBasenameAndBundleType.out.bundle_type
}
