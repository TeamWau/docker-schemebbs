FROM alpine

## Env vars
# Last known working versions
ENV GIT_COMMIT d3c6a2a34e434fc2a39f18440bbde728ee969338
ENV SCHEME_VERSION 9.2
# HACK: The patch file got lost in a commit.
ENV PATCH_URI https://gitlab.com/naughtybits/schemebbs/-/raw/03c95568db0930259365d791d346b6c45ebd2b17/patch-runtime_http-syntax.scm

ENV SCHEME mit-scheme-${SCHEME_VERSION}
ENV SCHEME_SOURCE ${SCHEME}.tar.gz
ENV SCHEME_BINARY ${SCHEME}-x86-64.tar.gz
ENV SOURCE_URI https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}

## Prepare build environment
RUN apk --no-cache --update --virtual build-dependencies add build-base m4 git
RUN git clone -n https://gitlab.com/naughtybits/schemebbs.git /opt/schemebbs
WORKDIR /opt/schemebbs
# Disable pesky warning that clutters build log
RUN git -c advice.detachedHead=false checkout ${GIT_COMMIT}
# Fetch tarballs and check integrity
RUN wget ${SOURCE_URI}/${SCHEME_BINARY} ${SOURCE_URI}/${SCHEME_SOURCE} ${SOURCE_URI}/md5sums.txt ${PATCH_URI}
# HACK: Busybox md5sum lacks `--ignore-missing' option.
RUN fgrep -e ${SCHEME_BINARY} -e ${SCHEME_SOURCE} md5sums.txt | md5sum -c

## Build and install Scheme binary
RUN tar xfz ${SCHEME_BINARY}
WORKDIR /opt/schemebbs/${SCHEME}/src
RUN ./configure --disable-x11 --disable-edwin \
	&& make \
	&& make install

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
	&& make \
	&& make install

## Cleanup
WORKDIR /opt/schemebbs
RUN rm -rf ${SCHEME} ${SCHEME_BINARY} ${SCHEME_SOURCE} md5sums.txt \
	&& apk del build-dependencies

## Run
EXPOSE 8080
VOLUME /opt/schemebbs/data
CMD scheme --args 8080 < bbs.scm
