FROM ubuntu:xenial as builder
RUN TINI_VERSION="v0.13.2" \
    && TINI_REAL_VERSION="0.13.2" \
    && TINI_BUILD="/tmp/tini" \
    && echo "Installing build dependencies" \
    && TINI_DEPS="build-essential cmake curl git hardening-includes libcap-dev python-dev rpm vim" \
    && apt-get update \
    && apt-get install --yes ${TINI_DEPS} \
    && echo "Building Tini" \
    && git clone https://github.com/krallin/tini.git "${TINI_BUILD}" \
    && cd "${TINI_BUILD}" \
    && curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-13.1.2.tar.gz \
    && tar -xf virtualenv-13.1.2.tar.gz \
    && mv virtualenv-13.1.2/virtualenv.py virtualenv-13.1.2/virtualenv \
    && export PATH="${TINI_BUILD}/virtualenv-13.1.2:${PATH}" \
    && HARDENING_CHECK_PLACEHOLDER="${TINI_BUILD}/hardening-check/hardening-check" \
    && HARDENING_CHECK_PLACEHOLDER_DIR="$(dirname "${HARDENING_CHECK_PLACEHOLDER}")" \
    && mkdir "${HARDENING_CHECK_PLACEHOLDER_DIR}" \
    && echo  "#/bin/sh" > "${HARDENING_CHECK_PLACEHOLDER}" \
    && chmod +x "${HARDENING_CHECK_PLACEHOLDER}" \
    && export PATH="${PATH}:${HARDENING_CHECK_PLACEHOLDER_DIR}" \
    && git checkout "${TINI_VERSION}" \
    && export SOURCE_DIR="${TINI_BUILD}" \
    && export BUILD_DIR="${TINI_BUILD}" \
    && export ARCH_NATIVE=1 \
    && "${TINI_BUILD}/ci/run_build.sh" \
    && echo "Move Tini" \
    && mv "${TINI_BUILD}/tini_${TINI_REAL_VERSION}.deb" /tmp/tini_release.deb
FROM ubuntu:xenial
COPY --from=builder /tmp/tini_release.deb /tmp
RUN apt-get update \
    && dpkg --force-all -i /tmp/tini_release.deb \
    && rm /tmp/tini_release.deb \
    && TINI_DEPS="build-essential cmake curl git hardening-includes libcap-dev python-dev rpm" \
    && apt-get purge --yes ${TINI_DEPS} \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Symlinkng to /usr/local/bin" \
    && ln -s /usr/bin/tini        /usr/local/bin/tini \
    && ln -s /usr/bin/tini-static /usr/local/bin/tini-static \
    && echo "Running Smoke Test" \
    && /usr/bin/tini -- ls \
    && /usr/bin/tini-static -- ls \
    && /usr/local/bin/tini -- ls \
    && /usr/local/bin/tini-static -- ls \
    && echo "Done"
ENTRYPOINT ["/usr/bin/tini", "--"]
