#!/bin/bash
set -x
trap 'echo "FATAL: setup failed at line ${LINENO}" >> /tmp/progress.log; exit 1' ERR

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Setup zt-podman-deploy" > /tmp/progress.log
chmod 666 /tmp/progress.log

dnf -y remove katello-ca-consumer-* 2>/dev/null || true
subscription-manager clean
subscription-manager register --activationkey="${ACTIVATION_KEY}" --org="${ORG_ID}" --force
dnf install -y git podman skopeo

LIBDIR=/tmp/lab-lib-$$
git clone --depth=1 https://github.com/rhel-labs/lab-setup "${LIBDIR}"
. "${LIBDIR}/common.sh"

echo "Packages installed" >> /tmp/progress.log

# --- lab configuration ---
REGISTRY_HOST="registry-${GUID}.${DOMAIN}"
# -------------------------

setup_ssl_registry "${REGISTRY_HOST}"
echo "Registry up at ${REGISTRY_HOST}" >> /tmp/progress.log

# Mirror hostinfo-app to local registry — students pull from here in Module 1
IMAGE_TGT="hostinfo-app:latest"
skopeo copy \
    docker://ghcr.io/rhel-labs/"${IMAGE_TGT}" \
    docker://"${REGISTRY_HOST}/${IMAGE_TGT}"

echo "${IMAGE_TGT} mirrored to local registry" >> /tmp/progress.log

add_local_host "${REGISTRY_HOST}"

persist_env_var REGISTRY "${REGISTRY_HOST}"

cleanup_subscription
cleanup_certbot
cleanup_tmpfiles
echo "Setup complete" >> /tmp/progress.log
