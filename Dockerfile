FROM ubuntu:jammy-20240111 as basebuilder

# This docker file can be used to build a tool chain docker image for building RomWBW images.

# Tested on a ubuntu host and on Windows un WSL (with docker desktop)

# First build the docker image (will b)
# docker build --progress plain -t romwbw-chain .

# After you have built the above image (called romwbw-chain), you can use it to compile and build the RomWBW images
# as per the standard make scripts within RomWBW.
# Start a new terminal, cd to where you have clone RomWBW, and then run this command: 
# docker run -v ${PWD}:/src/ --privileged=true -u $(id -u ${USER}):$(id -g ${USER}) -it romwbw-chain:latest

# you can now compile and build the required images:

# cd Tools && make
# cd Source && make # at least once to build many common units
# cd Source && make rom ROM_PLATFORM=RCEZ80 ROM_CONFIG=std

# when finish, type 'exit' to return to back to your standard terminal session

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
