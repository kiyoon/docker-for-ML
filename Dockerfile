# Dockerfile for general purpose environment with users in sudoer group.
# Edited from the Tensorflow 2.0 dockerfile, but can be used with any AI framework.
# AI framework not included.

ARG UBUNTU_VERSION=18.04

ARG ARCH=
ARG CUDA=10.1
# From the base repo, install CUDA toolkits manually.
# Instead you can also install dev version from the nvidia repo.
FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION} as base
# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.2.24-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64

LABEL maintainer="Kiyoon Kim <kiyoon.kim@ed.ac.uk>"

# Prevents apt-get to show interactive screen
ARG DEBIAN_FRONTEND=noninteractive

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
		apt-utils \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
		# There appears to be a regression in libcublas10=10.2.2.89-1 which
        # prevents cublas from initializing in TF. See
        # https://github.com/tensorflow/tensorflow/issues/9489#issuecomment-562394257
        libcublas10=10.2.1.243-1 \ 
        libcublas-dev=10.2.1.243-1 \
        cuda-cudart-dev-${CUDA/./-} \
        cuda-cufft-dev-${CUDA/./-} \
        cuda-curand-dev-${CUDA/./-} \
        cuda-cusolver-dev-${CUDA/./-} \
        cuda-cusparse-dev-${CUDA/./-} \
        libcudnn7=${CUDNN}+cuda${CUDA} \
        libcudnn7-dev=${CUDNN}+cuda${CUDA} \
        libcurl3-dev \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        git \
		vim-gtk \
		screen \
		virtualenv \
		tzdata \
#	    openjdk-8-jdk \
        && \
    find /usr/local/cuda-${CUDA}/lib64/ -type f -name 'lib*_static.a' -not -name 'libcudart_static.a' -delete && \
    rm /usr/lib/${LIB_DIR_PREFIX}-linux-gnu/libcudnn_static_v7.a && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV PATH /usr/local/cuda/bin:$PATH
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#ARG USE_PYTHON_3_NOT_2
#ARG _PY_SUFFIX=${USE_PYTHON_3_NOT_2:+3}
#ARG PYTHON=python${_PY_SUFFIX}
#ARG PIP=pip${_PY_SUFFIX}

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
	python \
	python3 \
	python-dev \
	python3-dev \
	python-pip \
	python3-pip && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip --no-cache-dir install --upgrade \
    pip \
    setuptools

RUN pip3 --no-cache-dir install --upgrade \
    pip \
    setuptools

# Some TF tools expect a "python" binary
#RUN ln -s $(which ${PYTHON}) /usr/local/bin/python 

RUN pip --no-cache-dir install \
    Pillow \
    h5py \
    matplotlib \
    numpy \
    scipy \
    sklearn \
    pandas \
    future

RUN pip3 --no-cache-dir install \
    Pillow \
    h5py \
    matplotlib \
    numpy \
    scipy \
    sklearn \
    pandas \
    future

COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

# Install sudo
RUN apt-get update && apt-get install -y sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Make 10 users with UID 1000 to 1009 because we don't know who's using it as of yet.
RUN /bin/bash -c 'for i in {1000..1009}; do adduser --disabled-password --gecos "" docker$i && adduser docker$i sudo; done'
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
