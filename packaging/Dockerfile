FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 gettext rpm dpkg-dev file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
CMD ["python3", "tools/build-release.py"]
