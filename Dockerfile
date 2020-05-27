FROM alpine

## Env
# Last known working versions
ENV SCHEME_VERSION 9.2
ENV SCHEME_TARBALL mit-scheme-${SCHEME_VERSION}-x86-64.tar.gz
ENV GIT_COMMIT 03c95568db0930259365d791d346b6c45ebd2b17

## Fetch
RUN apk --no-cache --update --virtual build-dependencies add build-base m4 git
RUN git clone -n https://gitlab.com/naughtybits/schemebbs.git /opt/schemebbs
WORKDIR /opt/schemebbs
# Disable pesky warning
RUN git -c advice.detachedHead=false checkout ${GIT_COMMIT}
RUN wget https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}/${SCHEME_TARBALL}
# HACK: Busybox md5sum lacks the `--ignore-missing' option.
RUN wget -qO - https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}/md5sums.txt \
	| grep ${SCHEME_TARBALL} > md5sum.txt
# Verify integrity
RUN md5sum -c md5sum.txt && tar xfz ${SCHEME_TARBALL}

## Build
# Apply URI parser patch
RUN patch -p0 < patch-runtime_http-syntax.scm
WORKDIR /opt/schemebbs/mit-scheme-${SCHEME_VERSION}/src
# Configure with plugins disabled
RUN ./configure --disable-x11 --disable-edwin --disable-imail --prefix=/opt/mit-scheme \
	&& make && make install

## Cleanup
WORKDIR /opt/schemebbs
RUN rm -rf mit-scheme-${SCHEME_VERSION} ${SCHEME_TARBALL} md5sum.txt \
	&& apk del build-dependencies

## Run
EXPOSE 8080
VOLUME /opt/schemebbs/data
CMD /opt/mit-scheme/bin/scheme --args 8080 < bbs.scm
