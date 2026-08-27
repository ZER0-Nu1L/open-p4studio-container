"""BFRT/PTF smoke test for the neutral minimal_forward program."""

# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

import bfrt_grpc.client as gc
from bfruntime_client_base_tests import BfRuntimeTest
import ptf.testutils as testutils


INGRESS_PORT = 8
EGRESS_PORT = 9
DST_IP = "198.51.100.9"
INPUT_DMAC = "00:11:22:33:44:55"
OUTPUT_DMAC = "02:00:00:00:00:09"


class MinimalForwardTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, client_id=0, p4_name="minimal_forward")

    def runTest(self):
        bfrt_info = self.interface.bfrt_info_get("minimal_forward")
        table = bfrt_info.table_get("SwitchIngress.ipv4_forward")
        table.info.key_field_annotation_add("hdr.ipv4.dst_addr", "ipv4")
        table.info.data_field_annotation_add(
            "dst_mac", "SwitchIngress.set_egress", "mac"
        )

        target = gc.Target(device_id=0, pipe_id=0xFFFF)
        key = table.make_key([gc.KeyTuple("hdr.ipv4.dst_addr", DST_IP)])
        data = table.make_data(
            [
                gc.DataTuple("port", EGRESS_PORT),
                gc.DataTuple("dst_mac", OUTPUT_DMAC),
            ],
            "SwitchIngress.set_egress",
        )

        packet = testutils.simple_tcp_packet(
            eth_dst=INPUT_DMAC,
            eth_src="00:aa:bb:cc:dd:ee",
            ip_src="192.0.2.1",
            ip_dst=DST_IP,
            ip_ttl=64,
        )
        expected = testutils.simple_tcp_packet(
            eth_dst=OUTPUT_DMAC,
            eth_src="00:aa:bb:cc:dd:ee",
            ip_src="192.0.2.1",
            ip_dst=DST_IP,
            ip_ttl=63,
        )

        installed = False
        try:
            table.entry_add(target, [key], [data])
            installed = True
            testutils.send_packet(self, INGRESS_PORT, packet)
            testutils.verify_packet(self, expected, EGRESS_PORT)
            testutils.verify_no_other_packets(self)

            table.entry_del(target, [key])
            installed = False
            testutils.send_packet(self, INGRESS_PORT, packet)
            testutils.verify_no_other_packets(self, timeout=2)
        finally:
            if installed:
                table.entry_del(target, [key])
