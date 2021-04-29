FROM quay.io/icgc-argo/dna-seq-processing-tools:base-docker.0.2.1

LABEL org.opencontainers.image.source https://github.com/icgc-argo/data-processing-utility-tools

ENV PATH="/tools:${PATH}"

COPY *.py /tools/

WORKDIR /tools

USER ubuntu

ENTRYPOINT ["/usr/bin/env"]
CMD ["/bin/bash"]
