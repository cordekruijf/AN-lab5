# AN lab 5 - P4 part 2

## Preparation
Setup interfaces
```
#!/bin/sh
set -e

for i in $@
do
        sudo ip link add name veth${i} type veth peer name port${i}
        sudo ip link set veth${i} addrgenmode none
        sudo ip link set port${i} addrgenmode none
        sudo ip link set dev veth${i} up
        sudo ip link set dev port${i} up
done
```

## Commands - task 1
```
vagrant@p4:~/src$ p4c-bm2-ss --p4v 16 --p4runtime-files \
build/counter.p4.p4info.txt -o build/counter.json counter.p4

vagrant@p4:~/src$ sudo python3 utils/install_rules.py -t topology.json \
-j build/counter.json -b simple_switch_grpc

vagrant@p4:~/src$ simple_switch_CLI
RuntimeCmd: table_dump MyIngress.ipv4_forwarding

vagrant@p4:~/src$ sudo tshark -n -i veth0 -i veth1 -i veth2 -i veth3 \
-T fields -e frame.time_relative -e frame.interface_name \
-e eth -e ip -e ipv6 -e udp -e tcp
```

### Scapy
```
$ sudo scapy
>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.1.1")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.2.2")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.3.3")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.4.4")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.8.8")/UDP(sport=RandShort(),dport=RandShort())

>>> sendp(p, iface="veth0")
```

## Commands - task 2
### Kill switch
```
$ sudo killall simple_switch_g
```

### Results
```
vagrant@p4:~/src$ simple_switch_CLI

RuntimeCmd: counter_read MyIngress.direct_port_counter 0
RuntimeCmd: counter_read MyIngress.direct_port_counter 1
RuntimeCmd: counter_read MyIngress.direct_port_counter 2
RuntimeCmd: counter_read MyIngress.direct_port_counter 3
```

## Commands - task 3
```
vagrant@p4:~/src$ p4c-bm2-ss --p4v 16 --p4runtime-files \
build/counter.p4.p4info.txt -o build/counter.json counter.p4
vagrant@p4:~/src$ sudo killall simple_switch_g
vagrant@p4:~/src$ sudo python3 utils/install_rules.py -t topology.json \
-j build/counter.json -b simple_switch_grpc
```

### Scapy
```
$ sudo scapy
>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.1.1")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.2.2")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.3.3")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.4.4")/UDP(sport=RandShort(),dport=RandShort())

>>> p = Ether(src=RandMAC(),dst=RandMAC())/IP(src=RandIP(), \
dst="10.0.8.8")/UDP(sport=RandShort(),dport=RandShort())

>>> sendp(p, iface="veth0")
```

### Results
```
vagrant@p4:~/src$ simple_switch_CLI

RuntimeCmd: counter_read MyIngress.indirect_counter 0
MyIngress.indirect_counter[0]= (336 bytes, 8 packets)
RuntimeCmd: counter_read MyIngress.indirect_counter 1
MyIngress.indirect_counter[1]= (0 bytes, 0 packets)
RuntimeCmd: counter_read MyIngress.indirect_counter 2
MyIngress.indirect_counter[2]= (126 bytes, 3 packets)
RuntimeCmd: counter_read MyIngress.indirect_counter 3
Invalid counter operation (INVALID_INDEX)
RuntimeCmd: counter_read MyIngress.indirect_counter 4
```

## Commands - task 4
```
vagrant@p4:~/port_knocking$ unzip port_knocking.zip
vagrant@p4:~/port_knocking$ ./setup_topo.sh 
vagrant@p4:~/port_knocking$ p4c-bm2-ss --p4v 16 --p4runtime-files build/port_knock.p4.p4info.txt -o build/port_knock.json port_knock.p4
vagrant@p4:~/port_knocking$ p4c-bm2-ss --p4v 16 --p4runtime-files build/basic_forw.p4.p4info.txt -o build/basic_forw.json basic_forw.p4
```
