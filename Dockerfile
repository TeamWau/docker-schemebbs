FROM alpine

## Env vars
# Last known working versions
ENV GIT_COMMIT 03c95568db0930259365d791d346b6c45ebd2b17
ENV SCHEME_VERSION 9.2
ENV SCHEME mit-scheme-${SCHEME_VERSION}
ENV SCHEME_SOURCE ${SCHEME}.tar.gz
ENV SCHEME_BINARY ${SCHEME}-x86-64.tar.gz

ENV MITSCHEME_LIBRARY_PATH /opt/mit-scheme/lib
ENV MIT_SCHEME_EXE /opt/mit-scheme/bin/scheme

## Prepare build environment
RUN apk --no-cache --update --virtual build-dependencies add build-base m4 git
RUN git clone -n https://gitlab.com/naughtybits/schemebbs.git /opt/schemebbs
WORKDIR /opt/schemebbs
# Disable pesky warning that clutters the build log
RUN git -c advice.detachedHead=false checkout ${GIT_COMMIT}
# Fetch tarballs and check integrity
RUN wget https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}/{${SCHEME_BINARY},${SCHEME_SOURCE},md5sums.txt}
# HACK: Busybox md5sum lacks the `--ignore-missing' option.
RUN fgrep -e ${SCHEME_BINARY} -e ${SCHEME_SOURCE} md5sums.txt | md5sum -c

## Build and install the Scheme binary
RUN tar xfz ${SCHEME_BINARY} -C ${SCHEME}-bootstrap
WORKDIR /opt/schemebbs/${SCHEME}-bootstrap/src
RUN ./configure --disable-x11 --disable-edwin --disable-imail --prefix=/opt/mit-scheme \
	&& make \
	&& make install

## Bootstrap the Scheme source with the patch
WORKDIR /opt/schemebbs
RUN tar xfz ${SCHEME_SOURCE} -C ${SCHEME}
# Apply URI parser patch
RUN patch -p0 < patch-runtime_http-syntax.scm
WORKDIR /opt/schemebbs/${SCHEME}/src
# Configure with plugins disabled, build with bootstrap binaries
RUN ./configure --disable-x11 --disable-edwin --disable-imail --prefix=/opt/mit-scheme \
	&& make
# Remove bootstrap binaries before installing the newly built ones
RUN rm -rf /opt/mit-scheme \
	&& make install

## Cleanup
WORKDIR /opt/schemebbs
RUN rm -rf ${SCHEME} ${SCHEME}-bootstrap ${SCHEME_BINARY} ${SCHEME_SOURCE} md5sums.txt \
	&& apk del build-dependencies

## Run
EXPOSE 8080
VOLUME /opt/schemebbs/data
CMD /opt/mit-scheme/bin/scheme --args 8080 < bbs.scm
