FROM maven:3.6.3-jdk-8 AS builder
WORKDIR /elastic

RUN apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata curl git g++ cmake

RUN git clone https://github.com/duydo/coccoc-tokenizer.git && \
    cd coccoc-tokenizer && mkdir build && cd build && \
    cmake -DBUILD_JAVA=1 .. && \
    make install && \
    ln -sf /usr/local/lib/libcoccoc_tokenizer_jni.* /usr/lib/

RUN git clone --depth=1 --branch "7.17.5-7.17.10" https://github.com/duydo/elasticsearch-analysis-vietnamese.git && \
    cd elasticsearch-analysis-vietnamese && git checkout 7957e15fbd121ecdf89ebae07eeb7b8381264d79 && \
    mvn package -Dmaven.test.skip

RUN rm /usr/local/bin/mvn-entrypoint.sh

FROM docker.elastic.co/elasticsearch/elasticsearch:7.17.10

ENV LD_LIBRARY_PATH /usr/local/lib

RUN elasticsearch-plugin install -b "https://github.com/o19s/elasticsearch-learning-to-rank/releases/download/v1.5.8-es7.17.10/ltr-plugin-v1.5.8-es7.17.10.zip"

COPY --from=builder /usr/local/bin/* /usr/local/bin
COPY --from=builder /usr/local/lib/* /usr/local/lib
COPY --from=builder /usr/local/share/tokenizer/dicts/* /usr/local/share/tokenizer/dicts/
COPY --from=builder \
	/elastic/elasticsearch-analysis-vietnamese/target/releases/elasticsearch-analysis-vietnamese-7.17.10.zip \
	/elastic-plugins/elasticsearch-analysis-vietnamese-7.17.10.zip

RUN elasticsearch-plugin install -b file:///elastic-plugins/elasticsearch-analysis-vietnamese-7.17.10.zip
