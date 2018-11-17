# Docker FoundationDB Build Tools

A Docker image for running [FoundationDB][fdb] on Linux for testing and
build purposes. It is not intended for production usage.

It is recommended that you fork this repository and customize the Docker
image as the DockerHub automated build may be unstable and may change
drastically.

## Getting Started

1. Build the Docker image with a named tag:

    ```sh
    docker build --tag fdb-build-tools:latest \
      --build-arg FDB_VERSION=5.2.5 \
      --build-arg FDB_CLIENTS_PKG_SHA256SUM=56e08082ae53caa7416c9660a535fa6b1330eb12985e5f2e3dff0739568d3b6c \
      --build-arg FDB_SERVER_PKG_SHA256SUM=59f1249728a3bbb009f703650ea67a68910d988991274375eba8a7adb553333e \
      .
    ```

2. Start FoundationDB with the server port exposed to the host. Directories
   from the host are also used as volumes in the container. This allows you
   to inspect the configuration and logs. Also, the `fdb.cluster` file will
   be in the `var/fdb/conf` directory.

    ```sh
    mkdir -p var/fdb/conf
    mkdir -p var/fdb/logs

    docker run -it --name fdb \
      -e "FDB_PUBLIC_ADDR=127.0.0.1" \
      -p 127.0.0.1:4500:4500 \
      -v $(pwd)/var/fdb/conf:/etc/foundationdb \
      -v $(pwd)/var/fdb/logs:/var/log/foundationdb \
      fdb-build-tools:latest
    ```

3. If you have a client application, you can use the FoundationDB server
   hosted in the container. Export the FDB_CLUSTER_FILE environment
   variable in step 2 or use the cluster file when opening the connection
   in your code.

    ```sh
    # In the same directory as step 2.
    #
    # Export the FDB_CLUSTER_FILE environment variable pointing to the
    # full path of the file.
    export FDB_CLUSTER_FILE=$(pwd)/var/fdb/conf/fdb.cluster
    ```

    Then run your program.

## Docker Compose

You can also use this image in a Docker Compose setup.

A sample `Dockerfile` which installs the FoundationDB client packages,
builds a Go program, and runs the program. You can adapt this for the
other FoundationDB API language bindings.

```Dockerfile
FROM golang:1.11.2-stretch

RUN apt-get update && \
      apt-get install -y \
      wget \
      dnsutils && \
      rm -r /var/lib/apt/lists/*

ARG FDB_VERSION

ARG FDB_DEB_REVISION="1"
ARG FDB_PKG_URL="https://www.foundationdb.org/downloads/${FDB_VERSION}/ubuntu/installers"
ARG FDB_CLIENTS_PKG="foundationdb-clients_${FDB_VERSION}-${FDB_DEB_REVISION}_amd64.deb"
ARG FDB_CLIENTS_PKG_SHA256SUM

WORKDIR /var/fdb/tmp

RUN wget $FDB_PKG_URL/$FDB_CLIENTS_PKG && \
      echo "${FDB_CLIENTS_PKG_SHA256SUM} ${FDB_CLIENTS_PKG}" > checksum && sha256sum -c checksum && \
      dpkg -i $FDB_CLIENTS_PKG && \
      rm -r /var/fdb/tmp

WORKDIR /app

COPY . .

RUN go build -mod=vendor

CMD ./helloworld
```

A sample `docker-compose.yml`:

```yaml
version: '3.7'
services:
  fdb:
    image: fdb-build-tools:latest
    volumes:
       - ./var/fdb/conf:/etc/foundationdb
       - ./var/fdb/logs:/var/log/foundationdb
  app:
    build:
      context: .
      args:
        FDB_VERSION: 6.0.15
        FDB_CLIENTS_PKG_SHA256SUM: 1b5e799900f8be328d6c32220c399e83cdbaf320b34ffcadc7c1851414d423bd
    environment:
      FDB_CLUSTER_FILE: /var/fdb/conf/fdb.cluster
    volumes:
       - ./var/fdb/conf:/var/fdb/conf
```

Be sure to create the bound volume directories on your host machine like:

```sh
mkdir -p var/fdb/conf
mkdir -p var/fdb/logs
```

This allows the FoundationDB container to write the configuration files in a
directory on the host machine. Then, the app container mounts the same
directory via a volume and sets the `FDB_CLUSTER_FILE` environment to that
file's path in the container. Your program can then use that file (by
default the FoundationDB language bindings should use the file pointed
at by `FDB_CLUSTER_FILE`; however, you can set open the file explicitly
in the `open` API call).

## Continuous Integration Services

TODO

## License

[Apache-2.0 License][license]

[license]: LICENSE
[fdb]: https://www.foundationdb.org
[travis_ci]: https://travis-ci.com/bluk/docker-swift-build-tools
[travis_ci_docker]: https://docs.travis-ci.com/user/docker/
[google_cloud_build]: https://cloud.google.com/cloud-build/
[circleci_build_job]: https://circleci.com/docs/2.0/build/
