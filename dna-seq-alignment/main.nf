#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
name = 'dna-seq-alignment'
version = '1.9.1'

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

gatkCollectOxogMetrics (object):
--gatkCollectOxogMetrics
{
    container_version                   docker container version, defaults to unset
    cpus                                cpus for align container, defaults to cpus parameter
    mem                                 memory (GB) for align container, defaults to mem parameter
    oxog_scatter                        number of parallel tasks for scattering OxoG metrics collection
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

params.cleanup = true
params.cpus = 1
params.mem = 1
params.max_retries = 5  // set to 0 will disable retry
params.first_retry_wait_time = 1  // in seconds

params.tempdir = "NO_DIR"
params.publish_dir = ""

params.analysis_metadata = "NO_FILE"
params.experiment_info_tsv = "NO_FILE1"
params.read_group_info_tsv = "NO_FILE2"
params.file_info_tsv = "NO_FILE3"
params.extra_info_tsv = "NO_FILE4"
params.sequencing_files = []

params.song_url = ""
params.score_url = ""
params.api_token = ""
params.download = [:]
params.seqDataToLaneBam = [:]
params.bwaMemAligner = [:]
params.bamMergeSortMarkdup = [:]
params.uploadAlignment = [:]
params.readGroupUBamQC = [:]
params.payloadGenDnaAlignment = [:]
params.alignedSeqQC = [:]
params.payloadGenDnaSeqQc = [:]
params.uploadQc = [:]
params.gatkCollectOxogMetrics = [:]


download_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.download ?: [:])
]

seqDataToLaneBam_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'reads_max_discard_fraction': -1,
    *:(params.seqDataToLaneBam ?: [:])
]

bwaMemAligner_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'tempdir': params.tempdir ?: 'NO_DIR',
    *:(params.bwaMemAligner ?: [:])
]

bamMergeSortMarkdup_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'output_format': 'cram',
    'markdup': true,
    'lossy': false,
    'tempdir': params.tempdir ?: 'NO_DIR',
    *:(params.bamMergeSortMarkdup ?: [:])
]

readGroupUBamQC_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    *:(params.readGroupUBamQC ?: [:])
]

payloadGenDnaAlignment_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'publish_dir': params.publish_dir,
    *:(params.payloadGenDnaAlignment ?: [:])
]

alignedSeqQC_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    *:(params.alignedSeqQC ?: [:])
]

payloadGenDnaSeqQc_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'publish_dir': params.publish_dir,
    *:(params.payloadGenDnaSeqQc ?: [:])
]

uploadAlignment_params = [
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    'cpus': params.cpus,
    'mem': params.mem,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.uploadAlignment ?: [:])
]

uploadQc_params = [
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    'cpus': params.cpus,
    'mem': params.mem,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.uploadQc ?: [:])
]

gatkCollectOxogMetrics_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'publish_dir': params.publish_dir,
    'oxog_scatter': 8,  // default, may be overwritten by params file
    *:(params.gatkCollectOxogMetrics ?: [:])
]


// Include all modules and pass params
include { SongScoreDownload as dnld } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-download@2.6.2/main.nf' params(download_params)
include { seqDataToLaneBam as toLaneBam } from "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.3.3.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(seqDataToLaneBam_params)
include { bwaMemAligner } from "./wfpr_modules/github.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner@0.2.0/main.nf" params(bwaMemAligner_params)
include { readGroupUBamQC as rgQC } from "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/read-group-ubam-qc.0.1.2.0/tools/read-group-ubam-qc/read-group-ubam-qc.nf" params(readGroupUBamQC_params)
include { bamMergeSortMarkdup as merSorMkdup } from "./wfpr_modules/github.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup@0.2.0/main.nf" params(bamMergeSortMarkdup_params)
include { getSecondaryFiles as getMdupSecondaryFile; getBwaSecondaryFiles } from './wfpr_modules/github.com/icgc-argo/data-processing-utility-tools/helper-functions@1.0.1/main'
include { alignedSeqQC; getAlignedQCSecondaryFiles } from "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/aligned-seq-qc.0.2.2.1/tools/aligned-seq-qc/aligned-seq-qc" params(alignedSeqQC_params)
include { payloadGenDnaAlignment as pGenDnaAln } from "./wfpr_modules/github.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-alignment@0.4.0/main.nf" params(payloadGenDnaAlignment_params)
include { payloadGenDnaSeqQc as pGenDnaSeqQc } from "./wfpr_modules/github.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-seq-qc@0.6.0/main.nf" params(payloadGenDnaSeqQc_params)
include { gatkSplitIntervals as splitItvls; getSecondaryFiles as getSIIdx } from "./modules/raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-split-intervals.4.1.4.1-1.0/tools/gatk-split-intervals/gatk-split-intervals"
include { metadataParser as mParser } from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/metadata-parser.0.1.0.0/tools/metadata-parser/metadata-parser.nf"
include { gatkCollectOxogMetrics as oxog; getOxogSecondaryFiles; gatherOxogMetrics as gatherOM } from "./modules/raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-collect-oxog-metrics.4.1.8.0-3.0/tools/gatk-collect-oxog-metrics/gatk-collect-oxog-metrics" params(gatkCollectOxogMetrics_params)
include { SongScoreUpload as upAln } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-upload@2.6.1/main.nf' params(uploadAlignment_params)
include { SongScoreUpload as upQc } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-upload@2.6.1/main.nf' params(uploadQc_params)
include { cleanupWorkdir as cleanup } from './modules/raw.githubusercontent.com/icgc-argo/nextflow-data-processing-utility-tools/2.3.0/process/cleanup-workdir'
include { payloadGenSeqExperiment as pGenExp } from './wfpr_modules/github.com/icgc-argo/data-processing-utility-tools/payload-gen-seq-experiment@0.5.0/main.nf'


workflow DnaAln {
    take:
        study_id
        analysis_id
        ref_genome_fa
        analysis_metadata
        experiment_info_tsv
        read_group_info_tsv
        file_info_tsv
        extra_info_tsv
        sequencing_files

    main:
        // detect local mode or not
        local_mode = false
        if ((!analysis_metadata.startsWith("NO_FILE") || !experiment_info_tsv.startsWith("NO_FILE")) && sequencing_files.size() > 0){
            local_mode = true
            if (!params.publish_dir) {
                exit 1, "You specified local sequencing data as input, please also set `params.publish_dir` to keep the output."
            }
            log.info "Run the workflow using local input sequencing data, alignment results will be in: ${params.publish_dir}"

            if (!analysis_metadata.startsWith("NO_FILE")) {
                if (!experiment_info_tsv.startsWith("NO_FILE") ||
                        !read_group_info_tsv.startsWith("NO_FILE") ||
                        !file_info_tsv.startsWith("NO_FILE") ||
                        !extra_info_tsv.startsWith("NO_FILE")
                )  {
                    log.info "Use analysis metadata JSON as input, will ignore input: 'experiment_info_tsv', 'read_group_info_tsv', 'file_info_tsv', 'extra_info_tsv'"
                }
                analysis_metadata = file(analysis_metadata)
            } else if (!experiment_info_tsv.startsWith("NO_FILE") &&
                       !read_group_info_tsv.startsWith("NO_FILE") &&
                       !file_info_tsv.startsWith("NO_FILE") &&
                       !extra_info_tsv.startsWith("NO_FILE")
                ) {
                pGenExp(
                    file(experiment_info_tsv),
                    file(read_group_info_tsv),
                    file(file_info_tsv),
                    file(extra_info_tsv)
                )
                analysis_metadata = pGenExp.out.payload
            } else {
                exit 1, "To run the workflow using local inputs, please specify metadata in JSON using params.analysis_metadata or metadata in TSVs using params.experiment_info_tsv, params.read_group_info_tsv, params.file_info_tsv and params.extra_info_tsv"
            }

            sequencing_files = Channel.fromPath(sequencing_files)
        } else if (study_id && analysis_id) {
            // download files and metadata from song/score (analysis type: sequencing_experiment)
            log.info "Run the workflow using input sequencing data from SONG/SCORE, alignment results will be uploaded to SONG/SCORE as well"
            dnld(study_id, analysis_id)
            analysis_metadata = dnld.out.analysis_json
            sequencing_files = dnld.out.files
        } else {
            exit 1, "To use sequencing data from SONG/SCORE as input, please provide `params.study_id`, `params.analysis_id` and other SONG/SCORE params.\n" +
                "Or please provide `params.analysis_metadata` (or `params.experiment_info_tsv`, `params.read_group_info_tsv`, `params.file_info_tsv` and `params.extra_info_tsv`) and `params.sequencing_files` from local files as input."
        }

        // preprocessing input data (BAM or FASTQ) into read group level unmapped BAM (uBAM)
        toLaneBam(analysis_metadata, sequencing_files.collect())

        // perform ubam QC
        rgQC(toLaneBam.out.lane_bams.flatten())

        // use scatter to run BWA alignment for each ubam in parallel
        bwaMemAligner(toLaneBam.out.lane_bams.flatten(), file(ref_genome_fa + '.gz'),
            Channel.fromPath(getBwaSecondaryFiles(ref_genome_fa + '.gz'), checkIfExists: true).collect(),
            analysis_metadata, bwaMemAligner_params.tempdir, rgQC.out.count())  // just to run after rgQC

        // collect aligned lane bams for merge and markdup
        merSorMkdup(bwaMemAligner.out.aligned_bam.collect(), file(ref_genome_fa + '.gz'),
            Channel.fromPath(getMdupSecondaryFile(ref_genome_fa + '.gz', ['fai', 'gzi']), checkIfExists: true).collect(),
            bamMergeSortMarkdup_params.tempdir)

        // generate payload for aligned seq (analysis type: sequencing_alignment)
        pGenDnaAln(merSorMkdup.out.merged_seq.concat(merSorMkdup.out.merged_seq_idx).collect(),
            analysis_metadata, [], name, version)

        // upload aligned file and metadata to song/score
        def alnAnalysisId
        if (!local_mode) {
            upAln(study_id, pGenDnaAln.out.payload, pGenDnaAln.out.alignment_files.collect())
            alnAnalysisId = upAln.out.analysis_id
        } else {
            alnAnalysisId = 'Unknown'
        }

        // perform aligned seq QC
        alignedSeqQC(pGenDnaAln.out.alignment_files.flatten().first(), file(ref_genome_fa + '.gz'),
            Channel.fromPath(getAlignedQCSecondaryFiles(ref_genome_fa + '.gz'), checkIfExists: true).collect(),
            alnAnalysisId)  // run after upAln

        // prepare oxog_scatter intervals
        splitItvls(gatkCollectOxogMetrics_params.oxog_scatter, file(ref_genome_fa),
            Channel.fromPath(getSIIdx(ref_genome_fa), checkIfExists: true).collect(), file('NO_FILE'))

        // get single/paired end info
        mParser(analysis_metadata)
     
        // perform gatkCollectOxogMetrics in parallel tasks
        oxog(pGenDnaAln.out.alignment_files.flatten().first(), pGenDnaAln.out.alignment_files.flatten().last(),
            file(ref_genome_fa),
            Channel.fromPath(getOxogSecondaryFiles(ref_genome_fa), checkIfExists: true).collect(),
            splitItvls.out.interval_files.flatten(), mParser.out.paired, alignedSeqQC.out.count())  // run after alignedSeqQC

        // gatherOxogMatrics
        gatherOM(oxog.out.oxog_metrics.collect())

        // prepare song payload for qc metrics
        pGenDnaSeqQc(analysis_metadata,
            alignedSeqQC.out.metrics.concat(
                merSorMkdup.out.duplicates_metrics,
                gatherOM.out.oxog_metrics,
                rgQC.out.ubam_qc_metrics).collect(),
            name, version)

        // upload aligned file and metadata to song/score
        if (!local_mode) {
            upQc(study_id, pGenDnaSeqQc.out.payload, pGenDnaSeqQc.out.qc_files.collect())
        }

        if (params.cleanup && !local_mode) {
            cleanup(
                sequencing_files.concat(toLaneBam.out, bwaMemAligner.out, merSorMkdup.out,
                    alignedSeqQC.out, oxog.out, rgQC.out).collect(),
                upAln.out.analysis_id.concat(upQc.out.analysis_id).collect())  // wait until upAln and upQc is done
        } else if (params.cleanup && local_mode) {
            cleanup(
                sequencing_files.concat(toLaneBam.out, bwaMemAligner.out, merSorMkdup.out,
                    alignedSeqQC.out, oxog.out, rgQC.out).collect(), pGenDnaSeqQc.out.payload)
        }

    emit:
        alignment_payload = pGenDnaAln.out.payload
        alignment_files = pGenDnaAln.out.alignment_files
        qc_metrics_payload = pGenDnaSeqQc.out.payload
        qc_metrics_files = pGenDnaSeqQc.out.qc_files
}


workflow {
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
