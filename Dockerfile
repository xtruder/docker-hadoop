FROM java:7

ENV  DEBIAN_FRONTEND noninteractive

ENV  HADOOP_VERSION 2.7.1
ENV  HADOOP_INSTALL_DIR /opt/hadoop

# init base os
RUN sed -i "s/httpredir.debian.org/mirrors.163.com/g" /etc/apt/sources.list
RUN  apt-get update && \
     apt-get install -y --no-install-recommends curl tar ssh && \
     apt-get clean autoclean && \
     apt-get autoremove --yes && \
     rm -rf /var/lib/{apt,dpkg,cache,log}/

# download hadoop 
RUN  mkdir -p ${HADOOP_INSTALL_DIR} && \
     curl -L http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar -xz --strip=1 -C ${HADOOP_INSTALL_DIR}

# build LZO
WORKDIR /tmp
RUN apt-get update && \
    apt-get install -y build-essential maven lzop liblzo2-2 && \
    wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.09.tar.gz && \
    tar zxvf lzo-2.09.tar.gz && \
    cd lzo-2.09 && \
    ./configure --enable-shared --prefix /usr/local/lzo-2.09 && \
    make && make install && \
    cd .. && git clone https://github.com/twitter/hadoop-lzo.git && cd hadoop-lzo && \
    git checkout release-0.4.20 && \
    C_INCLUDE_PATH=/usr/local/lzo-2.09/include LIBRARY_PATH=/usr/local/lzo-2.09/lib mvn clean package && \
    apt-get remove -y build-essential maven && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache.log}/ && \
    cd target/native/Linux-amd64-64 && \
    tar -cBf - -C lib . | tar -xBvf - -C /tmp && \
    cp /tmp/libgplcompression* ${HADOOP_INSTALL_DIR}/lib/native/ && \
    cd /tmp/hadoop-lzo && cp target/hadoop-lzo-0.4.20.jar ${HADOOP_INSTALL_DIR}/share/hadoop/common/ && \
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lzo-2.09/lib" >> ${HADOOP_INSTALL_DIR}/etc/hadoop/hadoop-env.sh && \
    rm -rf /tmp/lzo-2.09* hadoop-lzo lib libgplcompression*

# Enable jmx by default
WORKDIR  ${HADOOP_INSTALL_DIR}

ENTRYPOINT ["bin/hdfs"]
