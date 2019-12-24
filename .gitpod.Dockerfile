FROM alpine:latest
                
RUN  apk add --no-cache texlive-xetex texmf-dist-latexextra

# from https://github.com/cybercode/alpine-ruby/blob/master/Dockerfile
# guess ist is to install native extensions

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
      && apk add --no-cache postgresql-client nodejs \
        libffi-dev readline sqlite build-base postgresql-dev \
        libc-dev linux-headers libxml2-dev libxslt-dev readline-dev gcc libc-dev 

RUN apk add --no-cache \
    ruby ruby-dev ruby-irb ruby-rake ruby-io-console ruby-bigdecimal ruby-json ruby-bundler  \
    libstdc++ tzdata bash ca-certificates \
    &&  echo 'gem: --no-document' > /etc/gemrc\
# from https://hub.docker.com/r/ciandt/docker-alpine-pandoc/dockerfile^\
# install pandoc
RUN \
    apk add --no-cache ca-certificates wget \
    && wget -O /tmp/pandoc.tar.gz https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-linux.tar.gz \
    && tar xvzf /tmp/pandoc.tar.gz --strip-components 1 -C /usr/local/ \
    && ln /usr/local/bin/pandoc /usr/local/bin/pandoc_2.5 \
    && update-ca-certificates \
    && apk del wget ca-certificates\
    && rm /tmp/pandoc.tar.gz