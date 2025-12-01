FROM continuumio/miniconda3:latest

# Build argument for environment file path
ARG ENV_FILE=testing/env_python_3.9_with_R.yml

# Metadata labels
LABEL org.opencontainers.image.source=https://github.com/apache/zeppelin
LABEL org.opencontainers.image.description="Zeppelin test environment with Python 3.9 and R"

# Copy environment file
COPY ${ENV_FILE} /tmp/environment.yml

RUN conda config --set channel_priority strict && \
    conda install -n base -c conda-forge mamba && \
    mamba env create -f /tmp/environment.yml && \
    conda clean -afy && \
    rm /tmp/environment.yml

# Install R IRkernel
RUN conda run -n python_3_with_R R -e "IRkernel::installspec()"

# Install Java 11 for Maven (Adoptium/Temurin)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        apt-transport-https \
        gnupg && \
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" > /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        temurin-11-jdk \
        git \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PATH=/opt/conda/envs/python_3_with_R/bin:$PATH \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    CONDA_DEFAULT_ENV=python_3_with_R

WORKDIR /workspace

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python --version && conda --version

CMD ["/bin/bash"]
