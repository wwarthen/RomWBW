FROM ubuntu:jammy-20240111 as basebuilder

# docker build --progress plain -t vipoo/romwbw .

# docker run -v ${PWD}:/src/ --privileged=true -u $(id -u ${USER}):$(id -g ${USER}) -it vipoo/romwbw:latest

# cd Source && make ROM_PLATFORM=RCZ80 ROM_CONFIG=std
LABEL Maintainer="Dean Netherton" \
      Description="spike to use clang for ez80 target"

ENV DEBIAN_FRONTEND=noninteractive


RUN dpkg --add-architecture i386
RUN sed -i 's/http:\/\/archive\.ubuntu\.com\/ubuntu/http:\/\/au.archive.ubuntu.com\/ubuntu/g' /etc/apt/sources.list
RUN apt update -y
RUN apt dist-upgrade -y
RUN apt install -y --no-install-recommends cmake lzip ca-certificates mtools build-essential dos2unix libboost-all-dev texinfo texi2html libxml2-dev subversion bison flex zlib1g-dev m4 git wget dosfstools curl

RUN mkdir work
WORKDIR /work

FROM basebuilder as main

LABEL Maintainer="Dean Netherton" \
      Description="spike to build RomWBW"

RUN mkdir /src
WORKDIR /src/

RUN apt install -y --no-install-recommends build-essential libncurses-dev srecord bsdmainutils

RUN adduser --disabled-password --gecos "" builder

