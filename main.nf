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

#### WORK IN PROGRESS
TODO: Replace A1/A2 with actual analysis types
TODO: Docker container version to latest?

Required Parameters (no default):
--study_id                              song study ID
--analysis_id                           song A1 analysis ID
--song_url                              song server URL
--score_url                             score server URL
--api_token                             song/score API Token
--aligned_basename                      final aligned filename

General Parameters (with defaults):
--reference_dir                         reference genome directory
--aligned_lane_prefix                   prefix for alignment (defaults to "grch38-aligned")
--cpus                                  cpus given to all process containers (default 1)
--memory                                memory (MB) given to all process containers (default 1024)

Download Parameters (object):
--download
{
    song_container_version              song docker container version, defaults set below
    score_container_version             score docker container version, defaults set below
    song_url                            song url for download process (defaults to main song_url param)
    score_url                           score url for download process (defaults to main score_url param)
    api_token                           song/score API token for download process (defaults to main api_token param)
    song_cpu
    song_mem
    score_cpu
    score_mem
    score_transport_mem                 TODO: Description
}

Preprocess Parameters (object):
---preprocess
{
    container_version                   docker container version, defaults set below
    reads_max_discard_fraction          preprocess reads max discard function
    cpus                                cpus for preprocess container, defaults to cpus parameter
    mem                                 memory (MB) for preprocess container, defaults to memory parameter
}

Align Parameters (object):
--align
{
    container_version                   docker container version, defaults set below
    cpus                                cpus for align container, defaults to cpus parameter
    mem                                 memory (MB) for align container, defaults to memory parameter
}

Merge Parameters (object):
--merge
{
    container_version                   docker container version, defaults set below
    output_format                       options are ['cram', 'bam']
    markdup                             TODO: write description
    lossy                               TODO: write description
    cpus                                cpus for merge container, defaults to cpus parameter
    mem                                 memory (MB) for merge container, defaults to memory parameter
}

Upload Parameters (object):
--upload
{
    song_container_version              song docker container version, defaults set below
    score_container_version             score docker container version, defaults set below
    song_url                            song url for upload process (defaults to main song_url param)
    score_url                           score url for upload process (defaults to main score_url param)
    api_token                           song/score API token for upload process (defaults to main api_token param)
    song_cpu
    song_mem
    score_cpu
    score_mem
    score_transport_mem                 TODO: Description
    extract_cpu
    extract_mem
}

*/

params.reference_dir = 'reference'
params.aligned_lane_prefix = 'grch38-aligned'

download_params = [
    'song_container_version': '4.0.0',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.download ?: [:])
]

preprocess_params = [
    'container_version': '0.1.7.0',
    'reads_max_discard_fraction': 0.08,
    *:(params.preprocess ?: [:])
]

align_params = [
    'container_version': '0.1.2',
    *:(params.align ?: [:])
]

merge_params = [
    'container_version': '0.1.4.1',
    'output_format': ['cram'],
    'markdup': 'OPTIONAL_INPUT',
    'lossy': 'OPTIONAL_INPUT',
    *:(params.merge ?: [:])
]

sequencing_alignment_payload_gen_params = [
    'container_version': '0.1.2.0',
    *:(params.sequencing_alignment_payload_gen ?: [:])
]

upload_params = [
    'song_container_version': '4.0.0',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.upload ?: [:])
]

// Include all modules and pass params
include songScoreDownload as download from './data-processing/workflow/song_score_download' params(download_params)                                                                             
include preprocess from './dna-seq-processing/workflow/preprocess' params(preprocess_params)
include bwaMemAligner as align from './dna-seq-processing/process/bwa_mem_aligner' params(align_params)
include merge from './dna-seq-processing/workflow/merge' params(merge_params)
include sequencingAlignmentPayloadGen from './data-processing/process/sequencing_alignment_payload_gen' params(sequencing_alignment_payload_gen_params) 
include songScoreUpload as upload from './data-processing/workflow/song_score_upload' params(upload_params)

ref_gnome = Channel.fromPath("${params.reference_dir}/*").collect()

workflow {
    // download files and metadata from song/score (A1)
    download(params.study_id, params.analysis_id)

    // run files through preprocess step (split to lanes)
    preprocess(download.out.analysis_json_and_files)

    // align each lane independently
    align(preprocess.out.unaligned_lanes, ref_gnome, params.aligned_lane_prefix)

    // collect aligned lanes for merge and markdup
    merge(align.out.aligned_file.collect(), ref_gnome, params.aligned_basename)

    // generate A2 payload
    sequencingAlignmentPayloadGen(download.out.analysis_json, merge.out.merged_aligned_file.collect())

    // upload aligned file and metadata to song/score (A2)
    upload(params.study_id, sequencingAlignmentPayloadGen.out.analysis, sequencingAlignmentPayloadGen.out.upload_files.collect())
}
