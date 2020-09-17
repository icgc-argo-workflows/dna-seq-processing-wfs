#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.cpus = 1
params.mem = 1
params.files_to_delete = 'NO_FILE'
params.container_version = '18.04'


process cleanupWorkdir {
    cpus params.cpus
    memory "${params.mem} GB"
 
    container "ubuntu:${params.container_version}"

    input:
        path files_to_delete  // more accurately, other non-hidden files in the same folder will be deleted as well
        val virtual_dep_flag  // for specifying steps do not produce output files but produce values, set those values here

    script:
        """
        set -euxo pipefail

        IFS=" "
        read -a files <<< "${files_to_delete}"
        for f in "\${files[@]}"
        do
            dir_to_rm=\$(dirname \$(readlink -f \$f))

            if [[ \$dir_to_rm != ${workflow.workDir}/* ]]; then  # skip dir not under workdir, like from input file dir
                echo "Not delete: \$dir_to_rm/*\"
                continue
            fi

            rm -fr \$dir_to_rm/*  # delete all files and subdirs but not hidden ones
            echo "Deleted: \$dir_to_rm/*"
        done
        """
}
