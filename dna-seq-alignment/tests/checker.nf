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
 * authors: Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.enable.dsl=2

params.study_id = ""
params.analysis_id = ""
params.ref_genome_fa = ""

params.analysis_metadata = "NO_FILE"
params.experiment_info_tsv = "NO_FILE1"
params.read_group_info_tsv = "NO_FILE2"
params.file_info_tsv = "NO_FILE3"
params.extra_info_tsv = "NO_FILE4"
params.sequencing_files = []


include { DnaAln } from "../main" params(params)

workflow {
  main:
    DnaAln(
        params.study_id,
        params.analysis_id,
        params.ref_genome_fa,
        params.analysis_metadata,
        params.experiment_info_tsv,
        params.read_group_info_tsv,
        params.file_info_tsv,
        params.extra_info_tsv,
        params.sequencing_files
    )
}
