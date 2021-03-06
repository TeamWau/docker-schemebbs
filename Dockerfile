FROM alpine

## Env vars
# Last known working versions
ENV LATEST_HASH fcd89a06789a12146fcca6f5cb40002a4c74964f
ENV SCHEME_VERSION 9.2

ENV SCHEME mit-scheme-${SCHEME_VERSION}
ENV SCHEME_SOURCE ${SCHEME}.tar.gz
ENV SCHEME_BINARY ${SCHEME}-x86-64.tar.gz
ENV SOURCE_URI https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}

## Prepare build environment
RUN set -x && apk --no-cache --update --virtual build-dependencies add build-base m4 git
RUN git clone -n https://gitlab.com/naughtybits/schemebbs.git /opt/schemebbs
WORKDIR /opt/schemebbs
# Disable pesky warning that clutters build log
RUN git -c advice.detachedHead=false checkout ${LATEST_HASH}
# Fetch tarballs and check integrity
RUN wget ${SOURCE_URI}/${SCHEME_BINARY} ${SOURCE_URI}/${SCHEME_SOURCE} ${SOURCE_URI}/md5sums.txt
# HACK: Busybox md5sum lacks `--ignore-missing' option.
RUN fgrep -e ${SCHEME_BINARY} -e ${SCHEME_SOURCE} md5sums.txt | md5sum -c

## Build and install Scheme binary
RUN tar xfz ${SCHEME_BINARY}
WORKDIR /opt/schemebbs/${SCHEME}/src
RUN ./configure --disable-x11 --disable-edwin \
	&& make && make install

## Bootstrap Scheme source with patch
WORKDIR /opt/schemebbs
# Remove previous build before extracting
RUN rm -rf ${SCHEME} \
	&& tar xfz ${SCHEME_SOURCE}
# Apply URI parser patch
RUN patch -p0 < patch-runtime_http-syntax.scm
WORKDIR /opt/schemebbs/${SCHEME}/src
# Configure with plugins disabled and build with bootstrap binaries
RUN ./configure --disable-x11 --disable-edwin \
	&& make && make install

## Cleanup
WORKDIR /opt/schemebbs
RUN rm -rf ${SCHEME} ${SCHEME_BINARY} ${SCHEME_SOURCE} md5sums.txt \
	&& apk del build-dependencies

## Run
EXPOSE 8080
VOLUME /opt/schemebbs/data
CMD scheme --args 8080 < bbs.scm
