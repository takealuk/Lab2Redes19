/* Obligatorio 2 - Parte 2: esqueleto del switch P4 (v1model / BMv2).
 *
 * Provisto por el curso: definicion del encabezado Ethernet, parser y
 * deparser. El resto de la logica debe ser implementada por el grupo.
 */
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
 *  Encabezados
 *************************************************************************/
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct headers_t {
    ethernet_t ethernet;
}

struct metadata_t {
}

/*************************************************************************
 *  Parser
 *************************************************************************/
parser MyParser(packet_in pkt,
                out headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t std_meta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

/*************************************************************************
 *  Verificacion de checksum
 *************************************************************************/
control MyVerifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 *  Ingress
 *************************************************************************/
control MyIngress(inout headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t std_meta) {

    counter(64, CounterType.packets_and_bytes) ingress_port;

    action forward(bit<9> port) {
        std_meta.egress_spec = port;
    }

    action drop() {
        mark_to_drop(std_meta);
    }

    action broadcast() {
        std_meta.mcast_grp = 1;
    }

    table mac_table {
        key = {
            hdr.ethernet.dstAddr : exact;
        }
        actions = {
            forward;
            drop;
            broadcast;
        }
        default_action = drop();
        size = 256;
    }

    apply {
        ingress_port.count((bit<32>) std_meta.ingress_port);
        mac_table.apply();
    }
}

/*************************************************************************
 *  Egress
 *************************************************************************/
control MyEgress(inout headers_t hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t std_meta) {
    
    counter(64, CounterType.packets_and_bytes) egress_port;

    apply {
         if (std_meta.egress_port == std_meta.ingress_port) {
            mark_to_drop(std_meta);
        } else {
            egress_port.count((bit<32>) std_meta.egress_port);
        }
    }
}

/*************************************************************************
 *  Calculo de checksum
 *************************************************************************/
control MyComputeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 *  Deparser
 *************************************************************************/
control MyDeparser(packet_out pkt, in headers_t hdr) {
    apply {
        pkt.emit(hdr.ethernet);
    }
}

V1Switch(MyParser(),
         MyVerifyChecksum(),
         MyIngress(),
         MyEgress(),
         MyComputeChecksum(),
         MyDeparser()) main;
