#!/usr/bin/env nextflow

/*
  Copyright (C) 2021,  icgc-argo

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  Authors:
    Junjun Zhang
    Linda Xiang
*/

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2
version = '0.2.0'  // package version

container = [
    'ghcr.io': 'ghcr.io/icgc-argo/dna-seq-processing-tools.bwa-mem-aligner'
]
default_container_registry = 'ghcr.io'
/********************************************************************/

// universal params
params.container_registry = ""
params.container_version = ""
params.container = ""

params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""  // set to empty string will disable publishDir

// tool specific parmas go here
params.input_bam = "tests/input/?????_?.lane.bam"
params.aligned_lane_prefix = 'grch38-aligned'
params.ref_genome_gz = "tests/input/tiny-grch38-chr11-530001-537000.fa.gz"
params.sequencing_experiment_analysis = "NO_FILE"
params.tempdir = "NO_DIR"

// Include modules
include { getBwaSecondaryFiles } from './wfpr_modules/github.com/icgc-argo/data-processing-utility-tools/helper-functions@1.0.1/main'

process bwaMemAligner {
  container "${params.container ?: container[params.container_registry ?: default_container_registry]}:${params.container_version ?: version}"
  publishDir "${params.publish_dir}/${task.process.replaceAll(':', '_')}", mode: "copy", enabled: params.publish_dir

  cpus params.cpus
  memory "${params.mem} GB"

  tag "${input_bam.size()}"

  input:
    path input_bam
    path ref_genome_gz
    path ref_genome_gz_secondary_files
    path sequencing_experiment_analysis
    val tempdir
    val dependencies

  output:
    path "${params.aligned_lane_prefix}.${input_bam.baseName}.bam", emit: aligned_bam

  script:
    metadata = sequencing_experiment_analysis ? "-m " + sequencing_experiment_analysis : ""
    arg_tempdir = tempdir != 'NO_DIR' ? "-t ${tempdir}": ""
    """
    main.py \
      -i ${input_bam} \
      -r ${ref_genome_gz} \
      -o ${params.aligned_lane_prefix} \
      -n ${task.cpus} ${metadata} ${arg_tempdir}
    """
}

// this provides an entry point for this main script, so it can be run directly without clone the repo
// using this command: nextflow run <git_acc>/<repo>/<pkg_name>/<main_script>.nf -r <pkg_name>.v<pkg_version> --params-file xxx
workflow {
  bwaMemAligner(
    Channel.fromPath(params.input_bam, checkIfExists: true),
    file(params.ref_genome_gz),
    Channel.fromPath(getBwaSecondaryFiles(params.ref_genome_gz), checkIfExists: true).collect(),
    file(params.sequencing_experiment_analysis),
    params.tempdir,
    true
  )
}