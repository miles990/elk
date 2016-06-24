# Dockerfile for ELK stack on Ubuntu base

# Help:
# Default command: docker run -d -p 80:80 -p 3333:3333 -p 3334:3334 -p 9200:9200 miles990/elk /start.sh
# Default command will start ELK within a docker
# To send data to elk, stream to TCP port 3333
# Example: echo 'test data' | nc HOST 3333. Host is the IP of the docker host
# To login to bash: docker run -t -i miles990/elk /bin/bash


FROM ubuntu:14.04
MAINTAINER AlexLee

# Initial update
RUN apt-get update

# This is to install add-apt-repository utility. All commands have to be non interactive with -y option
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common

# Install Oracle Java 8, accept license command is required for non interactive mode
RUN	DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:webupd8team/java && \
	apt-get update && \
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections &&\
	DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-installer

# Elasticsearch installation
# Start Elasticsearch by /elasticsearch/bin/elasticsearch. This will run on port 9200.
RUN wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.3.3/elasticsearch-2.3.3.tar.gz && \
	tar xf elasticsearch-2.3.3.tar.gz && \
	rm elasticsearch-2.3.3.tar.gz && \
	mv elasticsearch-2.3.3 elasticsearch 

# Logstash installation
# Create a logstash.conf and start logstash by /logstash/bin/logstash agent -f logstash.conf
RUN wget https://download.elastic.co/logstash/logstash/logstash-2.3.3.tar.gz && \
	tar xf logstash-2.3.3.tar.gz && \
	rm logstash-2.3.3.tar.gz && \
	mv logstash-2.3.3 logstash && \
	touch logstash.conf && \
	echo 'input { tcp { port => 3333 type => "text event"} tcp { port => 3334 type => "json event" codec => json_lines {} } }' >> logstash.conf && \
	echo 'output { elasticsearch { hosts => "localhost" } }' >> logstash.conf 

# Kibana installation
RUN wget https://download.elastic.co/kibana/kibana/kibana-4.5.1-linux-x64.tar.gz && \
	tar xf kibana-4.5.1-linux-x64.tar.gz && \
	rm kibana-4.5.1-linux-x64.tar.gz && \
	mv kibana-4.5.1-linux-x64 kibana

# Install curl utility just for testing
RUN apt-get update && \
	apt-get install -y curl

# Install Nginx
# Start or stop with /etc/init.d/nginx start/stop. Runs on port 80.
# Sed command is to make the worker threads of nginx run as user root
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y nginx && \
	sed -i -e 's/www-data/root/g' /etc/nginx/nginx.conf

# Deploy kibana to Nginx
RUN mv /usr/share/nginx/html /usr/share/nginx/html_orig && \
	mkdir /usr/share/nginx/html && \
	cp -r /kibana/* /usr/share/nginx/html

# Create a start bash script
RUN touch elk_start.sh && \
	echo '#!/bin/bash' >> elk_start.sh && \
	echo '/elasticsearch/bin/elasticsearch -Des.insecure.allow.root=true -Des.network.host=0.0.0.0 &' >> elk_start.sh && \
	echo '/etc/init.d/nginx start &' >> elk_start.sh && \
	echo 'exec /logstash/bin/logstash agent -f /logstash.conf' >> elk_start.sh && \
	chmod 777 start.sh

# 80=nginx, 9200=elasticsearch, 3333,3334=logstash tcp input
EXPOSE 80 3333 3334 9200 49021

