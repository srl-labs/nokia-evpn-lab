ip link add bond0 type bond
ip link set bond0 type bond miimon 100 mode balance-rr
ip link set eth1 down
ip link set eth2 down
ip link set eth1 master bond0
ip link set eth2 master bond0
ip link set bond0 up
ip link add link bond0 name bond0.1 type vlan id 1
ip link set bond0.1 up