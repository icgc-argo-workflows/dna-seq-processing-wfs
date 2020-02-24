#!/usr/bin/env nextflow
nextflow.preview.dsl=2


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

Required Parameters (no default):
--study_id                              song study ID
--analysis_id                           song sequencing_experiment analysis ID
--ref_genome_fa                         reference genome '.fa' file, other secondary files are expected to be under the same folder
--song_url                              song server URL
--score_url                             score server URL
--api_token                             song/score API Token

General Parameters (with defaults):
--cpus                                  cpus given to all process containers (default 1)
--mem                                   memory (GB) given to all process containers (default 1)

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

seqDataToLaneBam Parameters (object):
--seqDataToLaneBam
{
    container_version                   docker container version, defaults to unset
    reads_max_discard_fraction          seqDataToLaneBam reads max discard fraction
    cpus                                cpus for seqDataToLaneBam container, defaults to cpus parameter
    mem                                 memory (GB) for seqDataToLaneBam container, defaults to mem parameter
    tool                                splitting tool, choices=['picard', 'samtools'], default="samtools"
}

bwaMemAligner Parameters (object):
--bwaMemAligner
{
    container_version                   docker container version, defaults to unset
    cpus                                cpus for bwaMemAligner container, defaults to cpus parameter
    mem                                 memory (GB) for bwaMemAligner container, defaults to mem parameter
}

bamMergeSortMarkdup Parameters (object):
--bamMergeSortMarkdup
{
    container_version                   docker container version, defaults to unset
    output_format                       options are ['cram', 'bam'], defaults to 'cram'
    markdup                             perform markdpulicate or not, defaults to true
    lossy                               generate lossy cram or not, defaults to false
    cpus                                cpus for bamMergeSortMarkdup container, defaults to cpus parameter
    mem                                 memory (GB) for bamMergeSortMarkdup container, defaults to mem parameter
}

payloadGenDnaAlignment (object):
--payloadGenDnaAlignment
{
    container_version                   docker container version, defaults to unset
    cpus                                cpus for align container, defaults to cpus parameter
    mem                                 memory (GB) for align container, defaults to mem parameter
}

Upload Parameters (object):
--upload
{
    song_container_version              song docker container version, defaults set below
    score_container_version             score docker container version, defaults set below
    song_url                            song url for upload process (defaults to main song_url param)
    score_url                           score url for upload process (defaults to main score_url param)
    api_token                           song/score API token for upload process (defaults to main api_token param)
    song_cpus                           cpus for song container, defaults to cpus parameter
    song_mem                            memory (GB) for song container, defaults to mem parameter
    score_cpus                          cpus for score container, defaults to cpus parameter
    score_mem                           memory (GB) for score container, defaults to mem parameter
    score_transport_mem                 memory (GB) for score_transport, defaults to mem parameter
    extract_cpus                        cpus for extract container, defaults to cpus parameter
    extract_mem                         memory (GB) extract score container, defaults to mem parameter
}

*/

params.study_id = ""
params.analysis_id = ""
params.ref_genome_fa = ""

params.cpus = 1
params.mem = 1

download_params = [
    'song_container_version': '4.0.0',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.download ?: [:])
]

seqDataToLaneBam_params = [
    'reads_max_discard_fraction': -1,
    *:(params.seqDataToLaneBam ?: [:])
]

bwaMemAligner_params = [
    *:(params.bwaMemAligner ?: [:])
]

bamMergeSortMarkdup_params = [
    'output_format': 'cram',
    'markdup': true,
    'lossy': false,
    *:(params.bamMergeSortMarkdup ?: [:])
]

readGroupUBamQC_params = [
    *:(params.readGroupUBamQC ?: [:])
]

payloadGenDnaAlignment_params = [
    *:(params.payloadGenDnaAlignment ?: [:])
]

alignedSeqQC_params = [
    *:(params.alignedSeqQC ?: [:])
]

payloadGenDnaSeqQc_params = [
    *:(params.payloadGenDnaSeqQc ?: [:])
]

uploadAlignment_params = [
    'song_container_version': '4.0.0',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.uploadAlignment ?: [:])
]

uploadQc_params = [
    'song_container_version': '4.0.0',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.uploadQc ?: [:])
]

gatkCollectOxogMetrics_params = [
    *:(params.gatkCollectOxogMetrics ?: [:])
]


// Include all modules and pass params
include songScoreDownload as dnld from './song-score-utils/song-score-download' params(download_params)
include seqDataToLaneBam as toLaneBam from "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.2.2.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(seqDataToLaneBam_params)
include bwaMemAligner from "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.6.0/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(bwaMemAligner_params)
include getBwaSecondaryFiles from "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.6.0/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(bwaMemAligner_params)
include readGroupUBamQC as rgQC from "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/read-group-ubam-qc.0.1.1.0/tools/read-group-ubam-qc/read-group-ubam-qc.nf" params(readGroupUBamQC_params)
include bamMergeSortMarkdup as merSorMkdup from "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.7.0/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(bamMergeSortMarkdup_params)
include getMdupSecondaryFile from "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.7.0/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(bamMergeSortMarkdup_params)
include alignedSeqQC from "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/aligned-seq-qc.0.2.0.0/tools/aligned-seq-qc/aligned-seq-qc" params(alignedSeqQC_params)
include getAlignedQCSecondaryFiles from "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/aligned-seq-qc.0.2.0.0/tools/aligned-seq-qc/aligned-seq-qc" params(alignedSeqQC_params)
include payloadGenDnaAlignment as pGenDnaAln from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-alignment.0.1.3.0/tools/payload-gen-dna-alignment/payload-gen-dna-alignment.nf" params(payloadGenDnaAlignment_params)
include payloadGenDnaSeqQc as pGenDnaSeqQc from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-seq-qc.0.1.1.0/tools/payload-gen-dna-seq-qc/payload-gen-dna-seq-qc.nf" params(payloadGenDnaSeqQc_params)
include gatkCollectOxogMetrics as oxog from "./modules/raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-collect-oxog-metrics.4.1.4.1-1.1/tools/gatk-collect-oxog-metrics/gatk-collect-oxog-metrics" params(gatkCollectOxogMetrics_params)
include getOxogSecondaryFiles from "./modules/raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-collect-oxog-metrics.4.1.4.1-1.1/tools/gatk-collect-oxog-metrics/gatk-collect-oxog-metrics" params(gatkCollectOxogMetrics_params)
include songScoreUpload as upAln from './song-score-utils/song-score-upload' params(uploadAlignment_params)
include songScoreUpload as upQc from './song-score-utils/song-score-upload' params(uploadQc_params)


workflow DnaAln {
    take:
        study_id
        analysis_id
        ref_genome_fa

    main:
        // download files and metadata from song/score (analysis type: sequencing_experiment)
        dnld(study_id, analysis_id)

        // preprocessing input data (BAM or FASTQ) into read group level unmapped BAM (uBAM)
        toLaneBam(dnld.out.song_analysis, dnld.out.files.collect())

        // use scatter to run BWA alignment for each ubam in parallel
        bwaMemAligner(toLaneBam.out.lane_bams.flatten(), file(ref_genome_fa + '.gz'),
            Channel.fromPath(getBwaSecondaryFiles(ref_genome_fa + '.gz'), checkIfExists: true).collect(),
            dnld.out.song_analysis)

        // perform ubam QC
        rgQC(toLaneBam.out.lane_bams.flatten())

        // collect aligned lane bams for merge and markdup
        merSorMkdup(bwaMemAligner.out.aligned_bam.collect(), file(ref_genome_fa + '.gz'),
            Channel.fromPath(getMdupSecondaryFile(ref_genome_fa + '.gz'), checkIfExists: true).collect())

        // generate payload for aligned seq (analysis type: sequencing_alignment)
        pGenDnaAln(merSorMkdup.out.merged_seq.concat(merSorMkdup.out.merged_seq_idx).collect(),
            dnld.out.song_analysis, [], workflow.manifest.name, '', workflow.manifest.version)

        // upload aligned file and metadata to song/score
        upAln(params.study_id, pGenDnaAln.out.payload, pGenDnaAln.out.alignment_files.collect())

        // perform aligned seq QC
        alignedSeqQC(pGenDnaAln.out.alignment_files.flatten().first(), file(ref_genome_fa + '.gz'),
            Channel.fromPath(getAlignedQCSecondaryFiles(ref_genome_fa + '.gz'), checkIfExists: true).collect())

        // perform gatkCollectOxogMetrics
        oxog(pGenDnaAln.out.alignment_files.flatten().first(), file(params.ref_genome_fa),
            Channel.fromPath(getOxogSecondaryFiles(params.ref_genome_fa), checkIfExists: true).collect())

        // prepare song payload for qc metrics
        pGenDnaSeqQc(dnld.out.song_analysis,
            alignedSeqQC.out.metrics.concat(
                merSorMkdup.out.duplicates_metrics,
                oxog.out.oxog_metrics,
                rgQC.out.ubam_qc_metrics).collect(),
            workflow.manifest.name, workflow.manifest.version)

        // upload aligned file and metadata to song/score
        upQc(params.study_id, pGenDnaSeqQc.out.payload, pGenDnaSeqQc.out.qc_files.collect())

    emit:
        analysis_id = upAln.out.analysis_id
        alignment_files = pGenDnaAln.out.alignment_files
}


workflow {
    DnaAln(
        params.study_id,
        params.analysis_id,
        params.ref_genome_fa
    )

    publish:
        DnaAln.out.alignment_files to: "outdir", overwrite: true
}
