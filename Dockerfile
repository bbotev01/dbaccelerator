FROM ubuntu:latest
MAINTAINER Boyan Botev <bbotev@gmail.com>

RUN apt-get update && apt-get install -y \
        libmemcached-dev \
        libpq-dev 

RUN apt-get install -y vim sudo git \ 
	&& mkdir -p /usr/src/pgpool \
	&& cd /usr/src/ \
	&& git clone https://github.com/pgpool/pgpool2.git pgpool \
	&& apt-get install -y gettext \ 
		bison \
		flex \
		gcc \
		libc-dev \
		make \
	&& cd /usr/src/pgpool \
	&& git checkout V3_2_2 \   
	&& ./configure 
#	&& ./configure --with-memcached=/usr/include/libmemcached-1.0 

RUN cd /usr/src/pgpool &&  make && make install

COPY pgpool.conf /usr/local/etc/pgpool.conf.mod
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /var/log/pgpool && \
    mkdir -p /var/run/pgpool && \
    mkdir -p /var/run/postgresql && \
    chmod 755 /usr/local/bin/entrypoint.sh	 

EXPOSE 5432 

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
