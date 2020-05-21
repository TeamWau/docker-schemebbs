FROM alpine

## Env
# Last known working versions
ENV SCHEME_VERSION 9.2
ENV SCHEME_TARBALL mit-scheme-${SCHEME_VERSION}-x86-64.tar.gz
ENV GIT_COMMIT 12c1870a58edd3a5ca9a05b36426616042083577

## Fetch
RUN apk --no-cache --update --virtual build-dependencies add build-base m4 git
RUN git clone -n https://gitlab.com/naughtybits/schemebbs.git /opt/schemebbs
WORKDIR /opt/schemebbs
# Disable pesky warning
RUN git -c advice.detachedHead=false checkout ${GIT_COMMIT}
ADD https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}/${SCHEME_TARBALL}
# Verify integrity
ADD https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}/md5sums.txt
RUN md5sum -c --ignore-missing md5sums.txt && tar xfz ${SCHEME_TARBALL}

## Patch
# Apply in-house patches
RUN for p in mit-scheme-9.2_patches/*.scm; do patch -p0 < "$p"; done
# HACK: Bind to 0.0.0.0
RUN sed -i deps/server.scm -e 's/host-address-loopback/host-address-any/'

## Build
WORKDIR /opt/schemebbs/mit-scheme-${SCHEME_VERSION}/src
# Configure with plugins disabled
RUN ./configure --disable-x11 --disable-edwin --disable-imail --prefix=/opt/mit-scheme \
	&& make && make install

## Cleanup
WORKDIR /opt/schemebbs
RUN rm -rf mit-scheme-${SCHEME_VERSION} ${SCHEME_TARBALL} md5sums.txt \
	&& apk del build-dependencies

## Run
EXPOSE 80
VOLUME /opt/schemebbs/data
# TODO: Take list of boards to create as an external env var.
#RUN ./create-boards.sh test
CMD /opt/mit-scheme/bin/scheme --args 80 < bbs.scm
