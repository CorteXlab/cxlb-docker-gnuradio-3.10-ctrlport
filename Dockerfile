FROM debian:bookworm


LABEL org.opencontainers.image.source=https://github.com/CorteXlab/cxlb-docker-gnuradio-3.10-ctrlport
LABEL org.opencontainers.image.description="Image intended to run GNU Radio 3.10 with ControlPort in CorteXlab"

ENV APT="apt-get -y"

RUN ${APT} update && ${APT} dist-upgrade

WORKDIR /root

# set an empty password for root
RUN sed -i -e 's%root:\*:%root:$6$fEFUE2YaNmTEH51Z$1xRO8/ytEYIo10ajp4NZSsoxhCe1oPLIyjDjqSOujaPZXFQxSSxu8LDHNwbPiLSjc.8u0Y0wEqYkBEEc5/QN5/:%' /etc/shadow

# install ssh server, listening on port 2222
RUN ${APT} install openssh-server
RUN sed -i 's/^#\?[[:space:]]*Port 22$/Port 2222/' /etc/ssh/sshd_config
RUN sed -i 's/^#\?[[:space:]]*PermitEmptyPasswords no$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
RUN sed -i 's/^#\?[[:space:]]*PermitRootLogin.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir /run/sshd
RUN chmod 755 /run/sshd

# tweaks for macos / windows
RUN sed -i 's/^#\?[[:space:]]*X11UseLocalhost.*$/X11UseLocalhost no/' /etc/ssh/sshd_config
RUN echo "AddressFamily inet" >> /etc/ssh/sshd_config
RUN touch /root/.Xauthority

# cxlb-build-toolchain.git
RUN ${APT} install git
RUN git clone https://github.com/CorteXlab/cxlb-build-toolchain.git cxlb-build-toolchain.git

# Install thrift deps for ControlPort
RUN ${APT} install thrift-compiler python3-thrift libthrift-dev

# Bypass issues with PEP668 (externally managed)
RUN mkdir -p /root/.config/pip && touch /root/.config/pip/pip.conf
RUN echo "\n[global]" >> /root/.config/pip/pip.conf
RUN echo "break-system-packages = true" >> /root/.config/pip/pip.conf

# build toolchain (separate build steps to benefit from docker cache in case of build issues on a specific module)
ENV BUILD="cxlb-build-toolchain.git/cxlb-build-toolchain -y /usr/bin/python3 -as"
ENV PARMS="cxlb_toolchain_build /cortexlab/toolchains/current"
RUN ${APT} install udev
RUN ${BUILD} uhd=master ${PARMS}
RUN ${BUILD} uhd-firmware ${PARMS}
RUN ${BUILD} volk=main ${PARMS}
RUN ${APT} install python3-pygccxml/bookworm
RUN ${BUILD} gnuradio=maint-3.10 ${PARMS}
RUN ${APT} -t bookworm install nodejs
RUN ${BUILD} gr-bokehgui=master ${PARMS}
# RUN ${BUILD} gr-iqbal=master ${PARMS}
# RUN ${BUILD} fft-web ${PARMS}

# activate toolchain configuration
RUN /cortexlab/toolchains/current/bin/cxlb-toolchain-system-conf
#RUN echo source /cortexlab/toolchains/current/bin/cxlb-toolchain-user-conf >> /etc/profile
RUN ln -s /cortexlab/toolchains/current/bin/cxlb-toolchain-user-conf /etc/profile.d/cxlb-toolchain-user-conf.sh
# RUN sysctl -w net.core.wmem_max=2500000


# Set default port number for thrift ControlPort
RUN sed -i 's/^export = False/export = True/' /cortexlab/toolchains/current/etc/gnuradio/conf.d/gnuradio-runtime.conf
RUN sed -i 's/^clock = thread/clock = monotonic/' /cortexlab/toolchains/current/etc/gnuradio/conf.d/gnuradio-runtime.conf
RUN sed -i 's/^on = False/on = True/' /cortexlab/toolchains/current/etc/gnuradio/conf.d/gnuradio-runtime.conf
RUN sed -i 's/^edges_list = False/edges_list = True/' /cortexlab/toolchains/current/etc/gnuradio/conf.d/gnuradio-runtime.conf
RUN echo "\n[thrift]\n" >> /cortexlab/toolchains/current/etc/gnuradio/conf.d/gnuradio-runtime.conf
RUN echo "port = 9090" >> /cortexlab/toolchains/current/etc/gnuradio/conf.d/gnuradio-runtime.conf

# remove toolchain sources
#RUN rm -rf cxlb_toolchain_build/

# the container's default executable: ssh daemon
CMD [ "/usr/sbin/sshd", "-p", "2222", "-D" ]