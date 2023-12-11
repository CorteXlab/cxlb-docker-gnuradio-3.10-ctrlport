# cxlb-docker-gnuradio-3.10-ctrlport
Dockerfile for GNU Radio 3.10 and Cortexlab toolchain with ControlPort

This image has the same content as one build with https://github.com/CorteXlab/cxlb-docker-gnuradio-3.10, namely:
- GNU Radio, from branch maint-3.10
- UHD from branch master
- gr-bokehgui from branch master
- gr-iqbal from branch master

  

## How to build and run locally
- build the docker image:

    `docker build --network=host -t cxlb-gnuradio-3.10-ctrlport .`

- create and start a container:

    `docker run -dti --net=host cxlb-gnuradio-3.10-ctrlport`

- then connect to this container with ssh:

    `ssh -Xp 2222 root@localhost`

## How to use in CorteXlab
- Either:
  - Use it direcly in a scenario
    ```
      nodes:
      node12:
        container:
        - image: ghcr.io/cortexlab/cxlb-gnuradio-3.10-ctrlport:1.0
    ```
  - Base your custom image on it and use that in your scenario
    
    `FROM ghcr.io/cortexlab/cxlb-gnuradio-3.10-ctrlport:1.0`
    ```
      nodes:
      node12:
        container:
        - image: my/cortexlab/custom-image:0.7
    ```
- Either:  
  1. Full SSH forwarding and manual control
      - Run a ssh deamon on the node with `command: /usr/sbin/sshd -p 2222 -D` in the scenario file (or no command at all, since it's the default)
      - Connect to airlock, adding `-L 9090:localhost:9090` to the connection command (example: `ssh -L 9090:localhost:9090 -X username@gw.cortexlab.fr`)
      - Connect to the node itself (with the task running), adding `-L 9090:localhost:9090` again to the ssh command (example `ssh -L 9090:localhost:9090 -X -p 2222 root@mnode12`)
      - Run the desired flowgraph
      - Locally (on your computer), run `gr-perf-monitorx 9090`
  1. Production deployment
     - Run the desired flowgraph with the scenario command: `command: bash -lc "/path/to/my/great/flowgraph.py -l options"`
     - Connect to airlock, adding `-L 9090:mnodeX:9090` to the connection command, replacing `mnodeX` with the node running the flowgraph (example: `ssh -L 9090:mnode12:9090 -X username@gw.cortexlab.fr`)
     - Locally (on your computer), run `gr-perf-monitorx 9090`
       
This requires a local installation of GNU Radio, compiled with ControlPort to run the `gr-perf-monitorx` command.
That installation could be in a docker container based on this image (following the above instructions)
