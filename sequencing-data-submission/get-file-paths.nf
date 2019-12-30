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
 * Authors: Junjun Zhang <junjun.zhang@oicr.on.ca>
 *          Linda Xiang <linda.xiang@oicr.on.ca>
 */

nextflow.preview.dsl=2


process getFilePaths {
  container "ubuntu:18.04"

  input:
    path file_tsv
    path metadata
  output:
    path "file_paths.csv", emit: file_paths
  script:
    """
    cols=(\$(head -1 ${file_tsv}))
    PATH_I=0
    for i in \${!cols[@]}; do
      if [ \${cols[\$i]} == "path" ]; then
        PATH_I=\$i
        break
      fi
    done

    (( PATH_I += 1 ))
    DIR=\$(dirname \$(realpath ${file_tsv}))

    echo "path" >> file_paths.csv
    for f in \$(tail -n +2 ${file_tsv} | cut -f \$PATH_I |sort -u); do
      if [[ \$f == /* ]] ; then
        echo \$f >> file_paths.csv
      elif [[ \$f == score://* ]] ; then
        echo \$f >> file_paths.csv
      else
        echo \$DIR/\$f >> file_paths.csv
      fi
    done
    """
}
