FROM ubuntu:bionic

RUN apt-get update
RUN apt-get install -y locales python3-pip python3-dev python3-virtualenv \
      git curl wget libncursesw5-dev libglib2.0-dev libgeoip-dev libtokyocabinet-dev

RUN echo "deb http://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list && \
    wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key add - && \
    sudo apt-get update && \
    sudo apt-get install goaccess-tcb

COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY src .

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD [CMD [ "python", "-m", "src.handler" ]
