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

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> id;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t ipv4;
    tcp_t tcp;
}

struct metadata_t {
    bit<1> restricted;   // 1 = el paquete entró por un puerto de invitado
    bit<1> denied; // la politica lo descarto
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
        transition select(hdr.ethernet.etherType){
            0x0800: parse_ipv4;
            default: accept;

        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            6: parse_tcp;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
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
    counter(1, CounterType.packets_and_bytes) acl_allowed;
    counter(1, CounterType.packets_and_bytes) acl_denied;
    counter(1, CounterType.packets_and_bytes) ps_violations;

    action forward(bit<9> port) {
        std_meta.egress_spec = port;
    }

    action drop() {
        mark_to_drop(std_meta);
    }

    action broadcast() {
        std_meta.mcast_grp = 1;
    }

    action mark_restricted() {
        meta.restricted = 1;
    }

    action allow() {
        acl_allowed.count(0);
    }

    action deny() {
        acl_denied.count(0);
        meta.denied = 1;
        mark_to_drop(std_meta);
    }

    action ps_permit() {
        // la MAC origen es la autorizada para este puerto: no hace nada
    }

    action ps_violation() {
        ps_violations.count(0);
        meta.denied = 1;
        mark_to_drop(std_meta);
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

    table restricted_ports {
    key = {
        std_meta.ingress_port : exact;   
    }
    actions = {
        mark_restricted;
        NoAction;                        
    }
    default_action = NoAction();        
    size = 16;
    }

    // acl es access control list
    table acl {
        key = {
            hdr.ipv4.dstAddr  : exact;
            hdr.ipv4.protocol : ternary;
            hdr.tcp.dstPort   : ternary;
        }
        actions = {
            allow;
            deny;
        }
        default_action = deny();
        size = 16;
    }

    table port_security {
        key = {
            std_meta.ingress_port : exact;   
            hdr.ethernet.srcAddr  : exact;   
        }
        actions = {
            ps_permit;
            ps_violation;
        }
        default_action = ps_violation();     
        size = 64;
    }

    apply {
        ingress_port.count((bit<32>) std_meta.ingress_port);

        // 2.4: la MAC origen tiene que ser la autorizada para el puerto
        port_security.apply();

        // 2.3: política de INVITADOS (solo si pasó port security)
        if (meta.denied == 0) {
            restricted_ports.apply();
            if (meta.restricted == 1) {
                if (hdr.ethernet.etherType == 0x0806) {
                    allow();
                } else if (hdr.ipv4.isValid()) {
                    acl.apply();
                } else {
                    deny();
                }
            }
        }

        // 2.2: reenvío normal, solo si nada lo descartó
        if (meta.denied == 0) {
            mac_table.apply();
        }
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
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.tcp);
    }
}

V1Switch(MyParser(),
         MyVerifyChecksum(),
         MyIngress(),
         MyEgress(),
         MyComputeChecksum(),
         MyDeparser()) main;
