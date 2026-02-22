## =========================================================
## Stage 1: Builder (install + patch + one-offs)
## =========================================================
FROM oraclelinux:8 AS builder
LABEL maintainer="Stephen Balousek <stephen.balousek@oracle.com>"

ARG INSTALLER
ARG OPATCH_ZIP=installers/OPatch/EMPTY
ARG ONEOFF_PATCHES=installers/OneOffPatches/EMPTY

ENV OGG_HOME=/u01/ogg
ENV OGG_DEPLOYMENT_HOME=/u02
ENV OGG_TEMPORARY_FILES=/u03
ENV OGG_DEPLOYMENT_SCRIPTS=/u01/ogg/scripts
ENV PATH="${OGG_HOME}/bin:${PATH}"

# scripts
COPY install-prerequisites.sh install-deployment.sh /tmp/
COPY bin/ /usr/local/bin/

# fail early with a clear message if INSTALLER was not provided
RUN : "${INSTALLER:?INSTALLER build argument is required}"

# installer
COPY ${INSTALLER} /tmp/installer.zip

# install GoldenGate RU
RUN bash /tmp/install-prerequisites.sh && \
    bash /tmp/install-deployment.sh && \
    rm -rf /tmp/*

# nginx config
COPY nginx/ /etc/nginx/

# ---------------------------------------------------------
# OPatch + one-off patches
#   - OPatch replacement: optional
#   - One-off patches:    optional
#   - Rule: if one-off patches are provided, OPATCH_ZIP is required
# ---------------------------------------------------------
COPY ${OPATCH_ZIP} /tmp/opatch.zip
COPY install-patches.sh apply-oneoff-opatch.sh /tmp/
COPY ${ONEOFF_PATCHES} /tmp/oneoffs/

RUN bash /tmp/install-patches.sh && \
    rm -rf /tmp/*

# ---------------------------------------------------------
# Runtime cleanup (still in builder!)
# ---------------------------------------------------------
RUN set -eux; \
    rm -rf \
        /u01/ogg/jdk \
        /u01/ogg/oui \
        /u01/ogg/inventory \
        /u01/ogg/cfgtoollogs \
        /u01/ogg/install \
        /u01/ogg/deinstall \
        /u01/ogg/OPatch \
        /u01/ogg/.patch_storage

LABEL ogg.stage="builder"
LABEL ogg.patchable="false"

## =========================================================
## Stage 2: Runtime image (small, clean, final)
## =========================================================
FROM oraclelinux:8

ENV OGG_HOME=/u01/ogg
ENV OGG_DEPLOYMENT_HOME=/u02
ENV OGG_TEMPORARY_FILES=/u03
ENV OGG_DEPLOYMENT_SCRIPTS=/u01/ogg/scripts
ENV PATH="${OGG_HOME}/bin:${PATH}"

# scripts
COPY install-prerequisites.sh /tmp/

RUN bash /tmp/install-prerequisites.sh && \
    rm -rf /tmp/*

# copy only the final runtime artifacts
COPY --from=builder --chown=ogg:ogg /u01/ogg /u01/ogg
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /etc/nginx /etc/nginx


# runtime metadata
EXPOSE 80 443

VOLUME [ "${OGG_DEPLOYMENT_HOME}", "${OGG_TEMPORARY_FILES}", "${OGG_DEPLOYMENT_SCRIPTS}" ]

HEALTHCHECK --start-period=90s --retries=1 \
  CMD [ "/usr/local/bin/healthcheck" ]

ENTRYPOINT [ "/usr/local/bin/deployment-main.sh" ]
