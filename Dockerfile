FROM ubuntu:14.04
RUN apt-get update -y
RUN apt-get install -y software-properties-common vim git
RUN export LD_LIBRARY_PATH=.:`cat /etc/ld.so.conf.d/* | grep -vF "#" | tr "\\n" ":" | sed -e "s/:$//g"`
RUN if [ $(grep -cF trusty /etc/lsb-release) > 0 ]; then add-apt-repository -y ppa:zerebubuth/ccache; fi
RUN add-apt-repository -y ppa:valhalla-core/valhalla
RUN apt-get update -y
RUN apt-get install -y -qq autoconf automake libtool make gcc g++ lcov protobuf-compiler libcurl3 libcurl3-dev libvalhalla-dev valhalla-bin -y

# working dir
RUN rm -fr /usr/src/app
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app/osmlr

WORKDIR /usr/src/app/osmlr

RUN git submodule update --init --recursive
RUN ./autogen.sh && ./configure --enable-coverage && make test -j$(nproc)
RUN ln -s /usr/src/app/osmlr/osmlr /usr/bin/osmlr

# run the spider
CMD ["/bin/bash"]