# cxlb-docker-gnuradio-3.10-ctrlport
Dockerfile for GNU Radio 3.10 and Cortexlab toolchain with ControlPort

Docker image with a GNURadio-3.10 toolchain

quick howto
-----------

- build the docker image:

    docker build --network=host -t cxlb-gnuradio-3.10-ctrlport .

- create and start a container:

    docker run -dti --net=host cxlb-gnuradio-3.10-ctrlport

- then connect to this container with ssh:

    ssh -Xp 2222 root@localhost
