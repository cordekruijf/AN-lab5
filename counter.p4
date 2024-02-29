#include <core.p4>
#include <v1model.p4>

header Ethernet_h {
    bit<48> dst;
    bit<48> src;
    bit<16> typ;
}

header IPv4_h {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  tos;
    bit<16> total_len;
    bit<16> id;
    bit<3>  flags;
    bit<13> offset;
    bit<8>  ttl;
    bit<8>  proto;
    bit<16> checksum;
    bit<32> src;
    bit<32> dst;
}

struct user_metadata_t {}

struct headers_t {
    Ethernet_h ethernet;
    IPv4_h     ipv4;
}

parser MyParser(packet_in pkt, out headers_t hdr, inout user_metadata_t umd, inout standard_metadata_t smd) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.typ) {
		0x0800 : parse_ipv4;
		default: accept;
        }
    }

	state parse_ipv4 {
		pkt.extract(hdr.ipv4);
		transition accept;
	}
}

control MyVerifyChecksum(inout headers_t hdr, inout user_metadata_t umd) {
    apply {}
}

control MyIngress(inout headers_t hdr, inout user_metadata_t umd, inout standard_metadata_t smd) {

	/* Task 1 */
    /* Source: https://github.com/nsg-ethz/p4-learning/blob/master/examples/counter/direct_counter.p4 */
	direct_counter(CounterType.packets_and_bytes) direct_port_counter;

	/* Task 2 */
	counter(3, CounterType.packets) indirect_counter;


    action set_egress(bit<9> port) {
		/* Task 2 */
        if ((smd.egress_port & 1) == 0) {
            indirect_counter.count(1);
        } else {
            indirect_counter.count(2);
        }

        smd.egress_spec = port;
    }

    action drop() {
		/* Task 2 */
        indirect_counter.count(2);

        mark_to_drop(smd);
    }

    table ipv4_forwarding {
        key = { hdr.ipv4.dst: exact; }
        actions = {
            set_egress;
            drop;
        }
		size=32;
        default_action = drop;
		/* Task 1 */
		counters = direct_port_counter;

    }

    apply {
		if (hdr.ipv4.isValid())
		{
			ipv4_forwarding.apply();
		}
    }
}

control MyEgress(inout headers_t hdr, inout user_metadata_t umd, inout standard_metadata_t smd) {
    apply {}
}

control MyComputeChecksum(inout headers_t hdr, inout user_metadata_t umd) {
    apply {}
}

control MyDeparser(packet_out pkt, in headers_t hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
    }
}

V1Switch(
 MyParser(),
 MyVerifyChecksum(),
 MyIngress(),
 MyEgress(),
 MyComputeChecksum(),
 MyDeparser()
) main;
