#!/bin/bash

yum install -y vim screen tmux tcpdump nc socat sysstat rng-tools

systemctl enable rngd

{% if time_zone != '' %}
timedatectl set-timezone {{ time_zone }}
{%- endif -%}
