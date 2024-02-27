# AN lab 5 - P4 part 2

## Commands
```
$ p4c-bm2-ss --p4v 16 --p4runtime-files \
build/counter.p4.p4info.txt -o build/counter.json counter.p4

$ sudo python3 utils/install_rules.py -t topology.json \
-j build/counter.json -b simple_switch_grpc
```