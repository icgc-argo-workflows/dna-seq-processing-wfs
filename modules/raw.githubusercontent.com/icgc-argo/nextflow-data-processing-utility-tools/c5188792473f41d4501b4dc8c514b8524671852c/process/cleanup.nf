#!/usr/bin/env nextflow
nextflow.preview.dsl=2

params.cpus = 1
params.mem = 1
params.files_to_delete = 'NO_FILE'
params.container_version = '18.04'


process cleanup {
    cpus params.cpus
    memory "${params.mem} GB"
 
    container "ubuntu:${params.container_version}"

    input:
        path files_to_delete  // more accurately, other non-hidden files in the same folder will be deleted as well
        val virtual_dep_flag  // for specifying steps do not produce output files but produce values, set those values here

    script:
        """
        IFS=" "
        read -a files <<< "${files_to_delete}"
        for f in "\${files[@]}"
            do rm -fr \$(dirname \$(readlink -f \$f))/*  # delete all files and subdirs but not hidden ones
        done
        """
}
