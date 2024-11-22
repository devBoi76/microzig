const std = @import("std");
const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
const gpio = @import("gpio.zig");
const uart = @import("uart.zig");

pub const HSI = 16_000_000;
pub const HSE = 25_000_000; // TODO: Verify

pub const LSIRC = 32_000;
pub const LSE = 32768;
pub const RTCCLK = LSE;

pub fn enableClocks() void {
    peripherals.RCC.CR.modify(.{ .PLLON = 1 });
}

pub fn getPLLIN() u32 {
    return switch (peripherals.RCC.PLLCFGR.read().PLLSRC.raw) {
        0 => HSI,
        1 => HSE,
    };
}
pub fn getVCO() u32 {
    return getPLLIN() * (peripherals.RCC.PLLCFGR.read().PLLN.raw / peripherals.RCC.PLLCFGR.read().PLLM.raw);
}
pub fn getPLLGeneral() u32 {
    return getVCO() / (2 * (peripherals.RCC.PLLCFGR.read().PLLP.raw + 1));
}
pub fn getPLL_USBFS_SDMMC_RNG() u32 {
    return getVCO() / peripherals.RCC.PLLCFGR.read().PLLQ.raw;
}

/// HPRE == HCLK == FCLK == AHBPRESC
pub fn getHCLK() u32 {
    const bits = peripherals.RCC.CFGR.read().HPRE.raw;
    return switch (bits) {
        0...7 => getSYSCLK(),
        8 => getSYSCLK() / 2,
        9 => getSYSCLK() / 4,
        10 => getSYSCLK() / 8,
        11 => getSYSCLK() / 16,
        12 => getSYSCLK() / 64,
        13 => getSYSCLK() / 128,
        14 => getSYSCLK() / 256,
        15 => getSYSCLK() / 512,
    };
}

pub fn getPrescaledClock(clock: u32, prescalerBits: u3) u32 {
    return switch (prescalerBits) {
        0...3 => clock,
        4 => clock / 2,
        5 => clock / 4,
        6 => clock / 8,
        7 => clock / 16,
    };
}
pub fn getPPRE1() u32 {
    return getPrescaledClock(getHCLK(), @truncate(peripherals.RCC.CFGR.read().PPRE1.raw));
}

pub fn getPPRE2() u32 {
    return getPrescaledClock(getHCLK(), @truncate(peripherals.RCC.CFGR.read().PPRE2.raw));
}

pub fn getAPB1Peripheral() u32 {
    return getPPRE1();
}
pub fn getAPB1Timer() u32 {
    // 16 == 16 <-> no APBx prescalar
    return if (getPrescaledClock(16, peripherals.RCC.CFGR.read().PPRE1.raw) == 16)
        getPPRE1()
    else
        getPPRE1() * 2;
}
pub fn getAPB2Peripheral() u32 {
    return getPPRE2();
}
pub fn getAPB2Timer() u32 {
    // 16 == 16 <-> no APBx prescalar
    return if (getPrescaledClock(16, peripherals.RCC.CFGR.read().PPRE2.raw) == 16)
        getPPRE2()
    else
        getPPRE2() * 2;
}

pub fn getMCO1() u32 {
    const pre = peripherals.RCC.CFGR.read().MCO1PRE.raw;
    const clock = switch (peripherals.RCC.CFGR.read().MCO1.value) {
        .HSI => HSI,
        .LSE => LSE,
        .HSE => HSE,
        .PLL => getPLLGeneral(),
    };
    return switch (pre) {
        0...3 => clock,
        4 => clock / 2,
        5 => clock / 3,
        6 => clock / 4,
        7 => clock / 5,
    };
}

pub fn getMCO2() u32 {
    const pre = peripherals.RCC.CFGR.read().MCO2PRE.raw;
    const clock = switch (peripherals.RCC.CFGR.MCO2.read().value) {
        .SYS => getSYSCLK(),
        // TODO: Not correct?
        .PLLI2S => getPLLI2SVCO(),
        .HSE => HSE,
        .PLL => getPLLGeneral(),
    };
    return switch (pre) {
        0...3 => clock,
        4 => clock / 2,
        5 => clock / 3,
        6 => clock / 4,
        7 => clock / 5,
    };
}

pub fn getI2S() u32 {
    return switch (peripherals.RCC.CFGR.I2SSRC) {
        0 => getPLLI2SVCO(),
        1 => @panic("todo: I2S_CKIN pin"),
    };
}

pub fn getSYSCLK() u32 {
    return switch (peripherals.RCC.CFGR.read().SWS.raw) {
        0 => HSI,
        1 => HSE,
        2 => getPLLGeneral(),
        else => unreachable,
    };
}

pub fn getRTCCLK() u32 {
    const pre = peripherals.RCC.CFGR.read().RTCPRE.raw;
    if (pre <= 1) return 0;
    return HSE / pre;
}

pub fn getPLLI2SIN() u32 {
    return switch (peripherals.RCC.PLLI2SCFGR.read().PLLSRC.raw) {
        0 => HSI,
        1 => HSE,
    };
}

pub fn getPLLI2SVCO() u32 {
    const plln = peripherals.RCC.PLLI2SCFGR.read().PLLI2SN.raw;
    const pllm = peripherals.RCC.PLLCFGR.read().PLLM.raw;
    return getPLLI2SIN() * (plln / pllm);
}

pub fn getPLLI2S_P() u32 {
    const plli2sp = peripherals.RCC.PLLI2SCFGR.read().PLLI2SP.raw;
    const divisors = [_]u32{ 2, 4, 6, 8 };
    return getPLLI2SVCO() / divisors[plli2sp];
}

pub fn getPLLI2S_Q() u32 {
    const plli2sq = peripherals.RCC.PLLI2SCFGR.read().PLLI2SQ.raw;
    if (plli2sq < 2) @panic("PLLI2SQ < 2 is invalid");
    return getPLLI2SVCO() / plli2sq;
}

pub fn getPLLI2S_R() u32 {
    const plli2sr = peripherals.RCC.PLLI2SCFGR.read().PLLI2SR.raw;
    if (plli2sr < 2) @panic("PLLI2SR < 2 is invalid");
    return getPLLI2SVCO() / plli2sr;
}

pub fn getUART(n: u3) u32 {
    const sel: u32 = peripherals.RCC.DCKCFGR2.raw >> (@as(u5, @intCast(n)) * 2);
    const bits: u2 = @intCast(sel & 0b11);

    return switch (bits) {
        0 => if (n == 0 or n == 5) getAPB2Peripheral() else getAPB1Peripheral(),
        1 => getSYSCLK(),
        2 => HSI,
        3 => LSE,
    };
}

pub const PLLConfig = struct {
    /// Main PLL (PLL) division factor for USB OTG FS,
    /// SDMMC and random number generator clocks
    PLLQ: u4 = 4,
    /// Main PLL(PLL) and audio PLL (PLLI2S) entry clock source
    PLLSRC: enum(u1) { HSI = 0, HSE } = .HSI,
    /// Main PLL (PLL) division factor for main system clock
    PLLP: enum(u2) { @"2" = 0, @"4", @"6", @"8" } = .@"2",
    /// Multiplier of VCO. Has to be set such that VCO between 100MHz..432MHz
    PLLN: u9 = 64 + 128,
    /// Division factor for the main PLLs (PLL, PLLI2S and PLLSAI) input clock
    PLLM: u6 = 16,
};

// TODO: work nicer with typesafe all.zig register definitions
pub fn PLLClock(config: PLLConfig) void {
    // const pll_in: u32 = switch (config.PLLSRC) {
    //     .HSI => HSI,
    //     .HSE => HSE,
    // };

    // const vco: u32 = pll_in * (config.PLLN / config.PLLM);
    // const pll_general: u32 = vco / @as(u32, @intFromEnum(config.PLLP));
    // const usb_sdmmc_rng: u32 = vco / config.PLLQ;

    peripherals.RCC.PLLCFGR.modify(.{
        .PLLQ = .{ .raw = config.PLLQ },
        .PLLSRC = .{ .raw = @intFromEnum(config.PLLSRC) },
        .PLLP = .{ .raw = @intFromEnum(config.PLLP) },
        .PLLN = .{ .raw = config.PLLN },
        .PLLM = .{ .raw = config.PLLM },
    });
}

pub const set = struct {
    const rcc_f7 = microzig.chip.types.peripherals.rcc_f7;

    /// Sets system clock source between HSI, HSE and PLL
    pub fn setSystemClockSource(value: rcc_f7.SW) void {
        peripherals.RCC.CFGR.modify(.{ .SW = .{ .value = value } });
    }

    // const RCC = peripherals.RCC;
    // const CFGR = RCC.CFGR;

    // fn getMmioEnum(comptime T: type) type {
    //     const fields = @typeInfo(T).fields;
    //     var efields: [fields.len]std.builtin.Type.EnumField = undefined;
    //     for (fields, 0..) |f, i|
    //         efields[i] = .{ .name = f.name, .value = i };

    //     return @Type(.{ .Enum = .{
    //         .tag_type = u8,
    //         .fields = fields,
    //         .decls = &.{},
    //         .is_exhaustive = true,
    //     } });
    // }

    // pub fn setCFGR(
    //     comptime field: getMmioEnum(CFGR.underlying_type),
    //     value: @TypeOf(@field(CFGR.underlying_type, @tagName(field))),
    // ) void {
    //     var reg = CFGR.read();
    //     @field(reg, field) = value;
    //     CFGR.write(reg);
    // }

    pub fn setUARTClockSource(
        comptime n: uart.UART,
        value: if (n.peripheral() == .APB1) rcc_f7.USART2SEL else rcc_f7.USART1SEL,
    ) void {
        const field = std.fmt.comptimePrint("{s}SEL", .{@tagName(n)});
        var reg = peripherals.RCC.DCKCFGR2.read();
        @field(reg, field).value = value;
        peripherals.RCC.DCKCFGR2.write(reg);
    }
};
