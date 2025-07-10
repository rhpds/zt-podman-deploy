#!/bin/bash
#dnf install -y tree buildah podman

set -ex

# start new container from scratch
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount ${newcontainer})

# install the packages
# yum install --installroot ${scratchmnt} httpd --releasever 9 --setopt=module_platform_id="platform:el9" -y
dnf install -y --releasever=10 --installroot=$scratchmnt redhat-release
dnf install -y --setopt=reposdir=/etc/yum.repos.d \
      --installroot=$scratchmnt \
      --setopt=cachedir=/var/cache/dnf httpd

# Clean up yum cache
if [ -d "${scratchmnt}" ]; then
  rm -rf "${scratchmnt}"/var/cache/yum
fi

# configure container label and entrypoint
buildah config --label name=rhel10-httpd ${newcontainer}
buildah config --port 80 --cmd "/usr/sbin/httpd -DFOREGROUND" ${newcontainer}

# commit the image
buildah unmount ${newcontainer}
buildah commit ${newcontainer} rhel10-httpd
