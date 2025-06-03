#!/bin/bash

dnf install -y tree buildah podman

set -ex

# start new container from scratch
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount ${newcontainer})

# install the packages
yum install --installroot ${scratchmnt} httpd --releasever 9 --setopt=module_platform_id="platform:el9" -y

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/yum
fi

# configure container label and entrypoint
buildah config --label name=rhel9-httpd ${newcontainer}
buildah config --port 80 --cmd "/usr/sbin/httpd -DFOREGROUND" ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} rhel9-httpd
