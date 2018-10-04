# Calculate IP
_ip=`ip a l eth0 | grep -Po "(?<=inet\s)([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+)*"`
_gateway=`ip r | grep -Po "(?<=default\svia\s)([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)*"`
_dns=`grep -Po "(?<=nameserver\s)(.)*" /etc/resolv.conf`

# Setup static network information
nmcli con mod 'System eth0' ipv4.addresses $_ip ipv4.gateway $_gateway ipv4.dns $_dns ipv4.method manual connection.autoconnect yes

# Reload connection
nmcli con down 'System eth0'
nmcli con up 'System eth0'
