# ============================================================================ #
# Copyright (c) 2022 - 2025 NVIDIA Corporation & Affiliates.                   #
# All rights reserved.                                                         #
#                                                                              #
# This source code and the accompanying materials are made available under     #
# the terms of the Apache License 2.0 which accompanies this distribution.     #
# ============================================================================ #

# Usage:
# Build from the repo root with
#   docker build -t sustik/cuda-quantum-dev:latest -f docker/build/sustik.cudaq.dev.Dockerfile .
#
# If a custom base image is used, then that image (i.e. the build environment) must 
# 1) have all the necessary build dependendencies installed
# 2) define the LLVM_INSTALL_PREFIX environment variable indicating where the 
#    the LLVM binaries that CUDA-Q depends on are installed
# 3) set the CC and CXX environment variable to use the same compiler toolchain
#    as the LLVM dependencies have been built with.

ARG base_image=ghcr.io/nvidia/cuda-quantum-devdeps:ext-cu12.0-gcc11-main
FROM $base_image

RUN mkdir cuda-quantum
RUN mkdir config
# To use X applications bind mount /tmp/.X11-unix as follows:
# --mount type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix

RUN apt update && apt install -y less zsh xterm pybind11-dev

RUN groupadd -g 1000 sustik && \
    useradd -m -u 1000 -g sustik sustik -s /usr/bin/zsh

ENV DISPLAY=:0
ENV CUDAQ_REPO_ROOT=/workspaces/cuda-quantum
ENV CUDAQ_INSTALL_PREFIX=/usr/local/cudaq
ENV PATH="$CUDAQ_INSTALL_PREFIX/bin:${PATH}"
ENV PYTHONPATH="$CUDAQ_INSTALL_PREFIX:${PYTHONPATH}"

ARG workspace=.
ARG destination="$CUDAQ_REPO_ROOT"
ADD "$workspace" "$destination"
WORKDIR "$destination"

# mpich or openmpi
ARG mpi=
RUN if [ -n "$mpi" ]; \
    then \
        if [ ! -z "$MPI_PATH" ]; then \
            echo "Using a base image with MPI is not supported when passing a 'mpi' build argument." && exit 1; \
        else \
			apt update && apt install -y lib$mpi-dev ; \
		fi \
    fi

# Configuring a base image that contains the necessary dependencies for GPU
# accelerated components and passing a build argument 
#   install="CMAKE_BUILD_TYPE=Release CUDA_QUANTUM_VERSION=latest"
# creates a dev image that can be used as argument to docker/release/cudaq.Dockerfile
# to create the released cuda-quantum image.
ARG install=
ARG git_source_sha=xxxxxxxx
RUN if [ -n "$install" ]; \
    then \
        expected_prefix=$CUDAQ_INSTALL_PREFIX; \
        install=`echo $install | xargs` && export $install; \
        bash scripts/build_cudaq.sh -v; \
        if [ ! "$?" -eq "0" ]; then \
            exit 1; \
        elif [ "$CUDAQ_INSTALL_PREFIX" != "$expected_prefix" ]; then \
            mkdir -p "$expected_prefix"; \
            mv "$CUDAQ_INSTALL_PREFIX"/* "$expected_prefix"; \
            rmdir "$CUDAQ_INSTALL_PREFIX"; \
        fi; \
        echo "source-sha: $git_source_sha" > "$CUDAQ_INSTALL_PREFIX/build_info.txt"; \
    fi

RUN mkdir /usr/local/cudaq
RUN chown sustik:sustik /usr/local/cudaq
USER sustik

WORKDIR /home/sustik
RUN mkdir cuda-quantum
RUN mkdir config
# The intention is that the above two directories are bind mounted, e.g.:
# > docker run \
#      --mount type=bind,source=[...]/cuda-quantum,target=$HOME/cuda-quantum \
#      --mount type=bind,source=$HOME/config,target=$HOME/config \
#      -it sustik/cuda-quantum-dev /bin/bash

ENV HISTFILE=/home/sustik/cuda-quantum/.zsh_history_cudaq
ENV HOME=/home/sustik

RUN ln -s /home/sustik/config/.zshrc .

CMD sh -c "echo 'Inside Container:' && echo 'User: $(whoami) UID: $(id -u) GID: $(id -g)'"
