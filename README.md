[![Build Status](https://travis-ci.org/icgc-argo-workflows/dna-seq-processing-wfs.svg?branch=master)](https://travis-ci.org/icgc-argo-workflows/dna-seq-processing-wfs)
# ICGC ARGO DNA Seq Processing Workflow


## Introduction

This repository maintains the source code of the ICGC ARGO DNA Seq Processing Pipeline. The pipeline is written
in [Nextflow](https://www.nextflow.io/) workflow language using DSLv2, with modules imported from other ICGC
ARGO GitHub repositories. Specifically, here are repositories maintaining various of tools/modules:

* https://github.com/icgc-argo-workflows/dna-seq-processing-tools
* https://github.com/icgc-argo-workflows/data-processing-utility-tools
* https://github.com/icgc-argo-workflows/nextflow-dna-seq-processing-tools
* https://github.com/icgc-argo-workflows/data-qc-tools-and-wfs

Each Nextflow module (including associated container image which is registered in Quay.io) is strictly
version controlled and released independently. To ensure reproducibility the pipeline declares explicitly
which specific version of a module is to be imported.

## Major tasks performed in the pipeline
* download input sequencing metadata/data from `SONG/SCORE`
* preprocess input sequencing reads (in `FASTQ` or `BAM`) into lane level (aka read group level) `BAM`
* collect `CollectQualityYieldMetrics` using `Picard` tool for read group
* perform `BWA-MEM` alignment against `GRCh38` reference genome in parallel for each lane `BAM`
* merge and markduplicate aligned lane `BAM`, produce coordinate-sorted `CRAM/CRAI` and `duplicates_metrics`
* collect alignment QC metrics using `samtools stats` for aligned seq
* collect `CollectOxoGMetrics` using `GATK` for aligned seq and calculate `OxoQ` score
* generate `SONG` metadata for aligned seq and upload them to `SONG/SCORE`
* generate `SONG` metadata for all collected `qc_metrics` and upload them to `SONG/SCORE`

## Run the pipeline

To run the pipeline, please follow instruction [here](https://www.nextflow.io/docs/latest/getstarted.html#installation) to install Nextflow (version `20.01.0` or higher) first.

Run `1.9.1` version of the pipeline:
```
nextflow run icgc-argo-workflows/dna-seq-processing-wfs -r 1.9.1 -params-file <your_params_file.json>
```

You may need to run `nextflow pull icgc-argo-workflows/dna-seq-processing-wfs` if the version `1.9.1` is new since last time the pipeline was run.

Please note that SONG/SCORE services need to be available and you have appropriate API token.

## Testing

Automated Travis CI testing has been set up. However, tests relying on SONG/SCORE will be skipped when CI is triggered
on a Travis server where SONG/SCORE services are not available. When running tests locally (where SONG/SCORE services may be
available) please use the following commands under the root directory of this Git repository:

```
# perform all tests when SONG/SCORE is available
export api_token=<your_api_token>
pytest -v

# or perform tests that do not need SONG/SCORE
TRAVIS=true pytest -v
```
