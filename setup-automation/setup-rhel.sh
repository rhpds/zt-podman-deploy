#!/bin/bash
while [ ! -f /opt/instruqt/bootstrap/host-bootstrap-completed ]
do
    echo "Waiting for Instruqt to finish booting the VM"
    sleep 1
done

subscription-manager config --rhsm.manage_repos=1
subscription-manager register --activationkey=${ACTIVATION_KEY} --org=12451665 --force

dnf install -y tree buildah podman

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "setting password" >> /root/post-run.log
echo redhat | passwd --stdin rhel

echo "DONE" >> /root/post-run.log

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


#set up tmux so it has to restart itself whenever the system reboots

#step 1: make a script
tee ~/startup-tmux.sh << EOF
TMUX='' tmux new-session -d -s 'podman' > /dev/null 2>&1
TMUX='' tmux new-session -d -s 'host' > /dev/null 2>&1
tmux set -g pane-border-status top
tmux setw -g pane-border-format ' #{pane_index} #{pane_current_command}'
tmux set -g mouse on
tmux set mouse on
EOF

#step 2: make it executable
chmod +x ~/startup-tmux.sh
#step 3: use cron to execute 
echo "@reboot ~/startup-tmux.sh" | crontab -

#step 4: start tmux for the lab
~/startup-tmux.sh