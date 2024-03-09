/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<8> TYPE_TCP = 6;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<1>  intflag;
    bit<3>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct metadata {
	bit<16> tcpLength;
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
	tcp_t		 tcp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
		meta.tcpLength = hdr.ipv4.totalLen - 20;
		transition select(hdr.ipv4.protocol) {
			TYPE_TCP: parse_tcp;
			default: accept;
		}
    }

	state parse_tcp {
		packet.extract(hdr.tcp);
		transition accept;
	}

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    register<bit<8>>(3) knocking_ports;
    bit<8> sequence_counter = 0;
    ip4Addr_t srcIP = 0;
    macAddr_t srcMAC = 0;

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action set_ports(bit<8> port1, bit<8> port2, bit<8> port3) {
        knocking_ports.write(0, port1);
        knocking_ports.write(1, port2);
        knocking_ports.write(2, port3);
    }

    action increase_counter() {
        // sequence_counter.write(0, sequence_counter.read(0) + 1);
        sequence_counter = sequence_counter + 1;
    }

    action reset_counter() {
        // sequence_counter.write(0, 0);
        sequence_counter = 0;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }

    table knocking_ports_sequence {
        key = {}
        actions = {
            set_ports;
            drop;
        }
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }

        if (hdr.tcp.isValid()) {
            knocking_ports_sequence.apply();
            
            if ((srcIP == 32w0) && (srcMAC == 48w0)) {
                srcIP = hdr.ipv4.srcAddr;
                srcMAC = hdr.ethernet.srcAddr;
            }

            if ((srcIP == hdr.ipv4.srcAddr) & (srcMAC == hdr.ethernet.srcAddr)) {
                bit<8> current_counter = sequence_counter;
                // sequence_counter.read(counter, 0);

                if (current_counter < 8w3) {
                    bit<16> next_port;
                    knocking_ports.read(next_port, current_counter);

                    if (hdr.tcp.dstPort == next_port) {
                        increase_counter();
                    }

                    reset_counter();
                } else {
                    reset_counter();
                    drop();
                }
            } else {
                drop();
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
        update_checksum(
        hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);

			update_checksum_with_payload(
            hdr.tcp.isValid(),
                {
                    hdr.ipv4.srcAddr,
                    hdr.ipv4.dstAddr,
                    8w0,
                    hdr.ipv4.protocol,
                    /* hdr.ipv4.totalLen, */
					meta.tcpLength,
                    hdr.tcp.srcPort,
                    hdr.tcp.dstPort,
                    hdr.tcp.seqNo,
                    hdr.tcp.ackNo,
                    hdr.tcp.dataOffset,
                    hdr.tcp.intflag,
                    hdr.tcp.res,
                    hdr.tcp.cwr,
                    hdr.tcp.ece,
                    hdr.tcp.urg,
                    hdr.tcp.ack,
                    hdr.tcp.psh,
                    hdr.tcp.rst,
                    hdr.tcp.syn,
                    hdr.tcp.fin,
                    hdr.tcp.window,
                    hdr.tcp.urgentPtr
                },
                hdr.tcp.checksum,
                HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
		packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
