#!/bin/bash

_ip=`ip a l eth0 | grep -Po "(?<=inet\s)([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+)*"`
_subnet=`ipcalc -np ${_ip} | sort | cut -d\= -f 2 | tr -s "\n" /`

# Enable Red Hat repositories
subscription-manager repos --enable=rhel-7-server-rhceph-3-mon-rpms --enable=rhel-7-server-rhceph-3-osd-rpms --enable=rhel-7-server-rhceph-3-tools-rpms --enable=rhel-7-server-ansible-2.4-rpms

# Install software
yum install -y nano wget vim screen git python telnet ceph-ansible

# RPMs pre-requitistes
# TODO: get them from Red Hat repos?
wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/python-itsdangerous-0.23-2.el7.noarch.rpm
wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/python-werkzeug-0.9.1-2.el7.noarch.rpm
wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/python-flask-0.10.1-4.el7.noarch.rpm
yum localinstall -y *.rpm

# Copy pre-created files
cp -pR /usr/share/ceph-ansible /root/ceph-ansible
cp -f /root/ceph-ansible/group_vars/all.yml.sample /root/ceph-ansible/group_vars/all.yml
cp -f /root/ceph-ansible/group_vars/osds.yml.sample /root/ceph-ansible/group_vars/osds.yml
cp -f /root/ceph-ansible/group_vars/mons.yml.sample /root/ceph-ansible/group_vars/mons.yml
cp -f /root/ceph-ansible/group_vars/rgws.yml.sample /root/ceph-ansible/group_vars/rgws.yml
cp -f /root/ceph-ansible/site.yml.sample /root/ceph-ansible/site.yml
mkdir ~/ceph-ansible-keys

# Disable host key check for Ansible
echo "host_key_checking = False" >> /root/ceph-ansible/ansible.cfg

# Create group_vars files
# All
cat << EOF >> /root/ceph-ansible/group_vars/all.yml
fetch_directory: ~/ceph-ansible-keys
ntp_service_enabled: false
ceph_origin: repository
ceph_repository: rhcs
ceph_rhcs_version: "3"
ceph_repository_type: cdn
rbd_cache: "true"
rbd_cache_writethrough_until_flush: "false"
rbd_client_directories: false
monitor_interface: eth0
journal_size: 1024
public_network: "${_subnet::-1}"
cluster_network: "${_subnet::-1}"
ceph_conf_overrides:
  global:
    mon_osd_allow_primary_affinity: 1
    mon_clock_drift_allowed: 0.5
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_pg_warn_min_per_osd: 0
    mon_pg_warn_max_per_osd: 0
    mon_pg_warn_max_object_skew: 0
  client:
    rbd_default_features: 1
EOF

# OSDs
cat << EOF >> /root/ceph-ansible/group_vars/osds.yml
fetch_directory: ~/ceph-ansible-keys
osd_scenario: collocated
devices:
  - /dev/vdb
journal_collocation: true
EOF

# Inventory file
cat << EOF >> /root/ceph-ansible/inventory
[mons]
${_ip%/*}
[osds]
${_ip%/*}
[mgrs]
${_ip%/*}
[all:vars]
ansible_user=cloud-user
EOF

# Wait for few seconds
sleep 30

# Run installer
cd /root/ceph-ansible
ansible-playbook -i /root/ceph-ansible/inventory site.yml
