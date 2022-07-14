FROM python:3.10.4-bullseye

# Update packages and system
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install software-properties-common git libsasl2-dev libzstd-dev

# Install librdkafka
# ENV LIBRDKAFKA_VERSION=1.8.2
# RUN git clone -b v${LIBRDKAFKA_VERSION} --single-branch https://github.com/edenhill/librdkafka.git \
#     && cd librdkafka \
#     && ./configure --install-deps \
#     && make \
#     && make install \
#     && cd .. \
#     && rm -rf librdkafka

# Python environment variables
ENV PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

# Clone FTL PYTHON LIB from GitHub
ENV FTL_PYTHON_LIB_VERSION=0.0.17
RUN git clone -b v${FTL_PYTHON_LIB_VERSION} --single-branch https://github.com/fintechless/ftl-python-lib.git
# COPY ftl-python-lib ${PYTHONPATH}/ftl-python-lib

# Create Python venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python -m venv $VIRTUAL_ENV

# Install Poetry
ENV POETRY_VERSION="1.1.12" \
    POETRY_HOME="/opt/poetry"
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python -

# Copy the codebase
ENV SRC="/src"
ENV PYTHONPATH="${PYTHONPATH}:/${SRC}"
WORKDIR ${SRC}
ADD . .

# Install dependencies:
RUN poetry install
