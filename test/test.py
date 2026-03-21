import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def axi_write(dut, master, addr, data):
    """
    AXI write for selected master
    master = 0 → Master0 (ui_in)
    master = 1 → Master1 (uio_in)
    """

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)

    if master == 0:
        dut.ui_in.value = (addr << 2) | 0x1   # start_write
        dut.uio_in.value = data
    else:
        dut.uio_in.value = (addr << 2) | 0x1
        dut.ui_in.value = data

    await RisingEdge(dut.clk)

    # Deassert
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Wait for done
    max_cycles = 2000
    for _ in range(max_cycles):
        if master == 0:
            done = int(dut.uo_out.value) & 0x1
        else:
            done = int(dut.uio_out.value) & 0x1

        if done:
            break
        await RisingEdge(dut.clk)
    else:
        dut._log.error(f"Timeout WRITE Master{master} ❌")
        return False

    return True


async def axi_read(dut, master, addr):
    """
    AXI read for selected master
    """

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)

    if master == 0:
        dut.ui_in.value = (addr << 2) | 0x2   # start_read
    else:
        dut.uio_in.value = (addr << 2) | 0x2

    await RisingEdge(dut.clk)

    dut.ui_in.value = 0
    dut.uio_in.value = 0

    max_cycles = 2000
    for _ in range(max_cycles):
        if master == 0:
            done = int(dut.uo_out.value) & 0x1
            data = int(dut.uo_out.value) & 0xFF
        else:
            done = int(dut.uio_out.value) & 0x1
            data = int(dut.uio_out.value) & 0xFF

        if done:
            return data

        await RisingEdge(dut.clk)

    dut._log.error(f"Timeout READ Master{master} ❌")
    return None

    await RisingEdge(dut.clk)
    return int(dut.uio_out.value) & 0xFF


@cocotb.test()
async def axi4lite_test(dut):

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    for _ in range(5):
        await RisingEdge(dut.clk)

    dut.rst.value = 0
    await RisingEdge(dut.clk)

    dut._log.info("Reset Done ✅")

    # ---------------- TEST MATRIX ----------------
    tests = [
        (0, 0x2, 0xAA),  # M0 → S0
        (0, 0x9, 0xBB),  # M0 → S1
        (1, 0x3, 0xCC),  # M1 → S0
        (1, 0xA, 0xDD),  # M1 → S1
    ]

    for master, addr, data in tests:

        dut._log.info(f"\n--- Master{master} WRITE Addr=0x{addr:X} Data=0x{data:X}")

        ok = await axi_write(dut, master, addr, data)
        if not ok:
            return

        await Timer(20, units="ns")

        dut._log.info(f"--- Master{master} READ Addr=0x{addr:X}")

        rdata = await axi_read(dut, master, addr)
        if rdata is None:
            return

        dut._log.info(f"READ DATA = 0x{rdata:X}")

        if rdata != data:
            dut._log.error(f"❌ FAIL: Expected 0x{data:X}, Got 0x{rdata:X}")
        else:
            dut._log.info("✅ PASS")
