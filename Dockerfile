FROM ubuntu:bionic

RUN apt-get update -y
RUN apt-get install -y locales wget python3-pip python3-dev python3-virtualenv \
    libncursesw5-dev libglib2.0-dev libgeoip-dev libtokyocabinet-dev libbz2-dev

RUN wget http://tar.goaccess.io/goaccess-1.3.tar.gz && \
    tar -xzvf goaccess-1.3.tar.gz && \
    cd goaccess-1.3 && \
    ./configure --enable-utf8 --enable-geoip=legacy --enable-tcb=btree && \
    make && \
    make install && \
    ln -s /usr/local/bin/goaccess /usr/bin/goaccess

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY src src

CMD [CMD [ "python", "-m", "src.handler" ]
