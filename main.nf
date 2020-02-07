#!/usr/bin/env nextflow
nextflow.preview.dsl=2
name = 'dna-seq-alignment'


/*
========================================================================================
                        ICGC-ARGO DNA SEQ ALIGNMENT
========================================================================================
#### Homepage / Documentation
https://github.com/icgc-argo/dna-seq-processing-wfs
#### Authors
Alexandru Lepsa @lepsalex <alepsa@oicr.on.ca>
Linda Xiang @lindaxiang <linda.xiang@oicr.on.ca>
Junjun Zhang @junjun-zhang <junjun.zhang@oicr.on.ca>

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
    song_cpus
    song_mem
    score_cpus
    score_mem
    score_transport_mem                 TODO: Description
}

SeqToLaneBam Parameters (object):
---seqtolanebam
{
    container_version                   docker container version, defaults set below
    reads_max_discard_fraction          SeqToLaneBam reads max discard function
    cpus                                cpus for SeqToLaneBam container, defaults to cpus parameter
    mem                                 memory (MB) for SeqToLaneBam container, defaults to memory parameter
    tool                                splitting tool, choices=['picard', 'samtools'], default="samtools"
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
    song_cpus
    song_mem
    score_cpus
    score_mem
    score_transport_mem                 TODO: Description
    extract_cpus
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

seqtolanebam_params = [
    'container_version': '0.2.0.0',
    'reads_max_discard_fraction': -1,
    *:(params.seqtolanebam ?: [:])
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
    'song_container_version': '4.0.1',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.upload ?: [:])
]

// Include all modules and pass params
include songScoreDownload as download from './song-score-utils/song_score_download' params(download_params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.2.0.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.3.0/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.5.0/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-alignment.0.1.2.0/tools/payload-gen-dna-alignment/payload-gen-dna-alignment.nf" params(params)
include songScoreUpload as upload from './song-score-utils/song_score_upload' params(upload_params)


workflow {
    // download files and metadata from song/score (analysis type: sequencing_experiment)
    download(params.study_id, params.analysis_id)

    // preprocessing input data (BAM or FASTQ) into read group level unmapped BAM (uBAM)
    seqDataToLaneBam(download.out.song_analysis, download.out.files.collect())

    // use scatter to run BWA alignment for each ubam in parallel
    bwaMemAligner(seqDataToLaneBam.out.lane_bams.flatten(), "grch38-aligned",
        file(params.ref_genome_fa + ".gz"),
        Channel.fromPath(getBwaSecondaryFiles(params.ref_genome_fa + ".gz"), checkIfExists: true).collect())

    // collect aligned lane bams for merge and markdup
    bamMergeSortMarkdup(bwaMemAligner.out.aligned_bam.collect(), file(params.ref_genome_fa),
        Channel.fromPath(getFaiFile(params.ref_genome_fa), checkIfExists: true).collect(),
        'aligned_seq_basename', true, 'cram', false)

    // generate payload for aligned seq (analysis type: sequencing_alignment)
    payloadGenDnaAlignment(bamMergeSortMarkdup.out.merged_seq.concat(bamMergeSortMarkdup.out.merged_seq_idx).collect(),
        download.out.song_analysis, [], name, '', workflow.manifest.version)

    // upload aligned file and metadata to song/score
    upload(params.study_id, payloadGenDnaAlignment.out.payload, payloadGenDnaAlignment.out.alignment_files.collect())
}
