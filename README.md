# AN lab 5 - P4 part 2

## Commands
```
vagrant@p4:~/src$ p4c-bm2-ss --p4v 16 --p4runtime-files \
build/counter.p4.p4info.txt -o build/counter.json counter.p4

vagrant@p4:~/src$ sudo python3 utils/install_rules.py -t AN-lab5/topology.json \
-j build/counter.json -b simple_switch_grpc

vagrant@p4:~/src$ simple_switch_CLI
RuntimeCmd: table_dump MyIngress.ipv4_forwarding
```