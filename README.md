# AN lab 5 - P4 part 2

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

### simple_switch_CLI
RuntimeCmd: counter_read MyIngress.direct_port_counter 0
RuntimeCmd: counter_read MyIngress.direct_port_counter 1
RuntimeCmd: counter_read MyIngress.direct_port_counter 2
RuntimeCmd: counter_read MyIngress.direct_port_counter 3

## Commands - task 3
### simple_switch_CLI
RuntimeCmd: counter_read MyIngress.indirect_counter 0