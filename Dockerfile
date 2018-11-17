# Modified file from original:
# https://github.com/apple/foundationdb/blob/26aad131b7592478993da7f420c8a3b94eeb96f6/docker/ubuntu/18.04/Dockerfile
# and
# https://github.com/apple/foundationdb/blob/60908f77cb74409e6ee66a041220726f6d0916ba/packaging/docker/Dockerfile
#
# Copyright 2013-2018 Apple Inc. and the FoundationDB project authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM ubuntu:18.04

# Install dependencies

RUN apt-get update && \
	apt-get install -y \
		wget \
		sudo \
		python \
		dnsutils && \
	rm -r /var/lib/apt/lists/*

# Install FoundationDB Binaries

ARG FDB_VERSION="6.0.15"

ARG FDB_DEB_REVISION="1"
ARG FDB_PKG_URL="https://www.foundationdb.org/downloads/${FDB_VERSION}/ubuntu/installers"
ARG FDB_CLIENTS_PKG="foundationdb-clients_${FDB_VERSION}-${FDB_DEB_REVISION}_amd64.deb"
ARG FDB_CLIENTS_PKG_SHA256SUM="1b5e799900f8be328d6c32220c399e83cdbaf320b34ffcadc7c1851414d423bd"
ARG FDB_SERVER_PKG="foundationdb-server_${FDB_VERSION}-${FDB_DEB_REVISION}_amd64.deb"
ARG FDB_SERVER_PKG_SHA256SUM="d08c9ceff5c83645cd100eae969d660ab03189251447861e9ab953b60bd3ea7f"

WORKDIR /var/fdb/tmp
RUN wget $FDB_PKG_URL/$FDB_CLIENTS_PKG && \
	echo "${FDB_CLIENTS_PKG_SHA256SUM} ${FDB_CLIENTS_PKG}" > checksum && sha256sum -c checksum && \
  wget $FDB_PKG_URL/$FDB_SERVER_PKG && \
	echo "${FDB_SERVER_PKG_SHA256SUM} ${FDB_SERVER_PKG}" > checksum && sha256sum -c checksum && \
  dpkg -i $FDB_CLIENTS_PKG $FDB_SERVER_PKG && \
  cp -r /etc/foundationdb /etc/foundationdb.default && \
	rm -r /var/fdb/tmp

ENV FDB_UID="1000"
ENV FDB_GID="1000"
ENV FDB_LISTEN_ADDR="0.0.0.0"
ENV FDB_LISTEN_PORT 4500
ENV FDB_PUBLIC_ADDR=""
ENV FDB_PUBLIC_PORT 4500
ENV FDB_LOCALITY_MACHINE_ID "docker"
ENV FDB_LOCALITY_ZONE_ID "docker"
ENV FDB_RESET_FDB_CLUSTER_FILE 1

# Set Up Runtime Scripts and Directories

WORKDIR /var/fdb

COPY fdb.bash .
RUN chmod u+x fdb.bash

CMD ./fdb.bash
