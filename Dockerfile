FROM alpine

ENV SCHEME_VERSION 9.2
ENV SCHEME_TARBALL mit-scheme-${SCHEME_VERSION}-x86-64.tar.gz
ENV GIT_COMMIT 7e0904324f4eda74a9783d67efc59db8b0a5f505

## Fetch
RUN apk --no-cache --update --virtual build-dependencies add build-base m4 git
RUN git clone -n https://gitlab.com/naughtybits/schemebbs.git /opt/schemebbs
WORKDIR /opt/schemebbs
RUN git -c advice.detachedHead=false checkout ${GIT_COMMIT}
RUN wget https://ftp.gnu.org/gnu/mit-scheme/stable.pkg/${SCHEME_VERSION}/${SCHEME_TARBALL} \
	&& tar xfz ${SCHEME_TARBALL}

## Build
RUN for p in mit-scheme-9.2_patches/*.scm; do patch -p0 < "$p"; done
WORKDIR /opt/schemebbs/mit-scheme-${SCHEME_VERSION}/src
RUN ./configure --disable-x11 --disable-edwin --disable-imail --prefix=/opt/mit-scheme \
	&& make && make install

# Clean
WORKDIR /opt/schemebbs
RUN rm -rf mit-scheme-${SCHEME_VERSION} ${SCHEME_TARBALL} \
	&& apk del build-dependencies

# Run
RUN ./create-boards.sh test
EXPOSE 80
CMD /opt/mit-scheme/bin/scheme --args 80 < bbs.scm
