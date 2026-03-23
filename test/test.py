import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def axi_write(dut, master, addr, data):

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)

    if master == 0:
        dut.ui_in.value = (addr << 2) | 0x1
        dut.uio_in.value = data
    else:
        dut.uio_in.value = (addr << 2) | 0x1
        dut.ui_in.value = data

    await RisingEdge(dut.clk)

    # Deassert
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Wait fixed cycles (AXI latency)
    for _ in range(20):
        await RisingEdge(dut.clk)

    return True


async def axi_read(dut, master, addr):

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)

    # Start read
    if master == 0:
        dut.ui_in.value = (addr << 2) | 0x2
    else:
        dut.uio_in.value = (addr << 2) | 0x2

    await RisingEdge(dut.clk)

    # Deassert
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Wait for AXI pipeline
    for _ in range(25):
        await RisingEdge(dut.clk)

    # Read data safely
    if master == 0:
        val = dut.uo_out.value
    else:
        val = dut.uio_out.value

    if not val.is_resolvable:
        dut._log.error(f"❌ X/Z detected: {val}")
        return 0

    return val.to_unsigned()

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
        
        dut._log.info(f"uo_out raw = {dut.uo_out.value}")
        
        dut._log.info(f"\n--- Master{master} WRITE Addr=0x{addr:X} Data=0x{data:X}")
        
        await axi_write(dut, master, addr, data)
        
        await Timer(20, units="ns")
        
        dut._log.info(f"--- Master{master} READ Addr=0x{addr:X}")
        
        rdata = await axi_read(dut, master, addr)
        
        dut._log.info(f"READ DATA = 0x{rdata:X}")
        
        if rdata != data:
            dut._log.error(f"❌ FAIL: Expected 0x{data:X}, Got 0x{rdata:X}")
        else:
            dut._log.info("✅ PASS")
