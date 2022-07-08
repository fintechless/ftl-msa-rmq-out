FROM python:3.10.4-bullseye

ARG DOCKER_CONTAINER_NAME

# Update packages and system
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install software-properties-common git libsasl2-dev libzstd-dev

# Install librdkafka
RUN git clone https://github.com/edenhill/librdkafka.git \
    && cd librdkafka \
    && ./configure --install-deps \
    && make \
    && make install \
    && cd .. \
    && rm -rf librdkafka

# Create Python venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python -m venv $VIRTUAL_ENV

# Install Poetry
ENV POETRY_VERSION="1.1.12" \
    POETRY_HOME="/opt/poetry"
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python -

ENV PLATFORM_DIR=/opt/ftl
ENV CONSUMER_DIR=/opt/ftl/msa

# Clone FTL PYTHON LIB from GitHub
ENV GITHUB_FTL_PYTHON_LIB_VERSION=0.0.14
RUN git clone -b v${GITHUB_FTL_PYTHON_LIB_VERSION} –single-branch https://github.com/fintechless/ftl-python-lib.git ${PLATFORM_DIR}/ftl-python-lib
# COPY ftl-python-lib ${PLATFORM_DIR}/ftl-python-lib

COPY ${DOCKER_CONTAINER_NAME} ${CONSUMER_DIR}/${DOCKER_CONTAINER_NAME}

RUN ls ${CONSUMER_DIR}

COPY pyproject.toml ${CONSUMER_DIR}/pyproject.toml
COPY poetry.lock ${CONSUMER_DIR}/poetry.lock

WORKDIR /opt/ftl/msa
RUN poetry install
