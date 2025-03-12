FROM debian:bookworm-slim

RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install -y \
		libavutil-dev \
		libavformat-dev \
		libavcodec-dev \
		libmicrohttpd-dev \
		libjansson-dev \
		libssl-dev \
		libsofia-sip-ua-dev \
		libglib2.0-dev \
		libopus-dev \
		libogg-dev \
		libcurl4-openssl-dev \
		liblua5.3-dev \
		libconfig-dev \
		libusrsctp-dev \
		libwebsockets-dev \
		libnanomsg-dev \
		librabbitmq-dev \
		pkg-config \
		gengetopt \
		libtool \
		automake \
		build-essential \
		wget \
		git \
		meson \
	gtk-doc-tools && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget https://github.com/cisco/libsrtp/archive/v2.6.0.tar.gz && \
	tar xfv v2.6.0.tar.gz
RUN git clone https://gitlab.freedesktop.org/libnice/libnice

WORKDIR /tmp/libsrtp-2.6.0
RUN ./configure --prefix=/usr --enable-openssl && \
	make shared_library && \
	make install

WORKDIR /tmp/libnice
RUN git checkout 0.1.22 && \
	mkdir builddir && \
	meson builddir && \
	ninja -C builddir && \
	ninja -C builddir install

#RUN find /usr/lib -name '*nice*'
#RUN find /usr/local/lib -name '*nice*'

COPY . /usr/local/src/janus-gateway

WORKDIR /usr/local/src/janus-gateway
RUN sh autogen.sh && \
	./configure --enable-post-processing --prefix=/usr/local && \
	make && \
	make install && \
	make configs

FROM debian:bookworm-slim

ARG BUILD_DATE="undefined"
ARG GIT_BRANCH="undefined"
ARG GIT_COMMIT="undefined"
ARG VERSION="undefined"

LABEL build_date=${BUILD_DATE}
LABEL git_branch=${GIT_BRANCH}
LABEL git_commit=${GIT_COMMIT}
LABEL version=${VERSION}

RUN apt-get -y update && apt-get -y upgrade && \
	apt-get install -y \
		libavcodec-dev \
		libavformat-dev \
		libavutil-dev \
		libconfig9 \
		libcurl4 \
		libglib2.0-0 \
		libjansson4 \
		liblua5.3-0 \
		libmicrohttpd12 \
		libnanomsg5 \
		libogg0 \
		libopus0 \
		libssl-dev \
		libsofia-sip-ua0 \
		libusrsctp-dev \
		libwebsockets-dev \
		librabbitmq4 && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY --from=0 /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so.1
RUN ln -s /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so

#COPY --from=0 /usr/lib/libnice.la /usr/lib/libnice.la
COPY --from=0 /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0 /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0
RUN ln -s /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0 /usr/local/lib/x86_64-linux-gnu/libnice.so.10
RUN ln -s /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0 /usr/local/lib/x86_64-linux-gnu/libnice.so

RUN ln -s /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0 /usr/lib/libnice.so.10.14.0
RUN ln -s /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0 /usr/lib/libnice.so.10
RUN ln -s /usr/local/lib/x86_64-linux-gnu/libnice.so.10.14.0 /usr/lib/libnice.so

COPY --from=0 /usr/local/bin/janus /usr/local/bin/janus
COPY --from=0 /usr/local/bin/janus-pp-rec /usr/local/bin/janus-pp-rec
COPY --from=0 /usr/local/bin/janus-cfgconv /usr/local/bin/janus-cfgconv
COPY --from=0 /usr/local/etc/janus /usr/local/etc/janus
COPY --from=0 /usr/local/lib/janus /usr/local/lib/janus
COPY --from=0 /usr/local/share/janus /usr/local/share/janus

ENV BUILD_DATE=${BUILD_DATE}
ENV GIT_BRANCH=${GIT_BRANCH}
ENV GIT_COMMIT=${GIT_COMMIT}
ENV VERSION=${VERSION}

EXPOSE 10000-10200/udp
EXPOSE 8188
EXPOSE 8088
EXPOSE 8089
EXPOSE 8889
EXPOSE 8000
EXPOSE 7088
EXPOSE 7089

CMD ["/usr/local/bin/janus"]
