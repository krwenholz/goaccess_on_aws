FROM ubuntu:bionic

RUN apt-get update
RUN apt-get install -y locales python3-pip python3-dev python3-virtualenv \
      git curl wget libncursesw5-dev libglib2.0-dev libgeoip-dev libtokyocabinet-dev

RUN wget http://tar.goaccess.io/goaccess-1.2.tar.gz && \
    tar -xzvf goaccess-1.2.tar.gz && \
    cd goaccess-1.2 && \
    ./configure --enable-utf8 --enable-geoip=legacy && \
    make && \
    make install && \
    ln -s /usr/local/bin/goaccess /usr/bin/goaccess

COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY src .

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD [CMD [ "python", "-m", "src.handler" ]
