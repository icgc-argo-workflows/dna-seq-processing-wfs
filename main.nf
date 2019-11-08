#!/usr/bin/env nextflow
nextflow.preview.dsl=2

/*
========================================================================================
                        ICGC-ARGO DNA SEQ ALIGNMENT
========================================================================================
#### Homepage / Documentation
https://github.com/icgc-argo/nextflow-dna-seq-alignment
#### Authors
Alexandru Lepsa @lepsalex <alepsa@oicr.on.ca>
----------------------------------------------------------------------------------------

TODO: Replace A1/A2 with actual analysis types

Required Paramaters:
--analysis-id                   SONG A1 analysis id
--api-token                     SONG/SCORE api token
--song-url                      SONG server URL
--score-url                     SCORE server URL

Optional Paramaters
--reads-max                     preprocess reads max discard function

*/

// download files and metadata from song/score (A1)

// run files through preprocess step (split to lanes)

// aliign each lane independently

// collect aligned lanes for merge and markdup

// upload aligned file and metadata to song/score (A2)