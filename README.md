# nextflow-dna-seq-alignment
ICGC ARGO Alignment workflow to be run in RDPC K8s cluster

### Example Command (local testing)
`nextflow run main.nf -params-file params.json`

#### Kubernetes
`nextflow kuberun -params-file params.k8s.json icgc-argo/nextflow-dna-seq-alignment -latest -v nextflow-pv-claim:/mnt/volume/nextflow`