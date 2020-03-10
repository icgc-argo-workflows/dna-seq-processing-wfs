[![Build Status](https://travis-ci.org/icgc-argo/dna-seq-processing-wfs.svg?branch=master)](https://travis-ci.org/icgc-argo/dna-seq-processing-wfs)
# ICGC ARGO DNA Seq Processing Pipeline


## Introduction

This repository maintains the source code of the ICGC ARGO DNA Seq Processing Pipeline. The pipeline is written
in [Nextflow](https://www.nextflow.io/) workflow language using DSLv2, with modules imported from other ICGC
ARGO GitHub repositories. Specifically, here are repositories maintaining various of tools/modules:

* https://github.com/icgc-argo/dna-seq-processing-tools
* https://github.com/icgc-argo/data-processing-utility-tools
* https://github.com/icgc-argo/nextflow-dna-seq-processing-tools
* and https://github.com/icgc-argo/data-qc-tools-and-wfs

Each Nextflow module (including associated container image which is registered in Quay.io) is strictly
version controlled and released independently. To ensure reproducibility the pipeline declares explicitly
which specific version of a module is to be imported.


## Run the pipeline

To run the pipeline, please follow instruction [here](https://www.nextflow.io/docs/latest/getstarted.html#installation) to install Nextflow (version `20.01.0` or higher) first.

Run `1.0.0` version of the pipeline:
```
nextflow run icgc-argo/dna-seq-processing-wfs -r 1.0.0 -params-file <your_params_file.json>
```

You may need to run `nextflow pull` if the version `1.0.0` is new since last time the pipeline was run.


## Testing

Automated Travis CI testing has been set up. However, tests will be skipped when CI is triggered on a Travis server due to reliance on SONG/SCORE services which are not available. A possible solution is to spin up
SONG/SCORE services running use Docker at Travis, this will require some work but should be doable. Before this
is resolved, we can manually test the pipeline with the following commands under the root directory of this
Git repository:

```
export API_TOKEN=<your_api_token>
pytest -v
```
