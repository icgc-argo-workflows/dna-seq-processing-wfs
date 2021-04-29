FROM python:3.7.5-slim-buster

LABEL org.opencontainers.image.source https://github.com/icgc-argo/data-processing-utility-tools

RUN apt-get update && apt-get install -y procps

RUN groupadd -g 1000 ubuntu && \
    useradd -l -u 1000 -g ubuntu ubuntu && \
    install -d -m 0755 -o ubuntu -g ubuntu /home/ubuntu

ENV PATH="/tools:${PATH}"

COPY *.py /tools/

WORKDIR /tools

USER ubuntu

ENTRYPOINT ["/usr/bin/env"]
CMD ["/bin/bash"]
