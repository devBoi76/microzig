const microzig = @import("microzig");
pub const peripherals = microzig.chip.peripherals;

pub const ADCNum = enum(u2) {
    ADC1 = 0,
    ADC2 = 1,
    ADC3 = 2,
};

pub const ADCChannel = enum(u5) {
    ADC_IN0 = 0,
    ADC_IN1,
    ADC_IN2,
    ADC_IN3,
    ADC_IN4,
    ADC_IN5,
    ADC_IN6,
    ADC_IN7,
    ADC_IN8,
    ADC_IN9,
    ADC_IN10,
    ADC_IN11,
    ADC_IN12,
    ADC_IN13,
    ADC_IN14,
    ADC_IN15,
    ADC_IN16,
    /// Internal reference voltage VREFINT, internally connected to ADC1_IN17
    ADC1_IN17,
    /// Either the temperature sensor or VBAT, depending on which is enabled. When both are enabled only VBAT conversion will be performed.
    /// Temperature sensor can only be accessed through ADC1_IN18, VBAT can be connected to any channel.
    ADC1_IN18,
};

pub const ADC1 = peripherals.ADC1;
pub const ADC2 = peripherals.ADC2;
pub const ADC3 = peripherals.ADC3;
const ADCMemory = @TypeOf(ADC1);

const ADC = @This();

pub fn init(number: ADCNum) ADC {
    return .{
        .number = @intFromEnum(number),
    };
}

number: u2,

pub inline fn get_regs(adc: ADC) ADCMemory {
    return switch (adc.number) {
        0 => ADC1,
        1 => ADC2,
        2 => ADC3,
        else => @panic("This board supports only 3 ADCs (1..3"),
    };
}

pub fn set_enabled(adc: ADC, channel: ADCChannel, enable: bool) void {
    peripherals.RCC.APB2ENR.raw |= @as(u32, 0x100) << (adc.number);

    if (channel == .ADC1_IN17 or channel == .ADC1_IN18) {
        if (adc.number != 0) {
            // TODO: what to do here?
        }

        microzig.chip.peripherals.ADC123_COMMON.CCR.modify(.{ .TSVREFE = @intFromBool(enable) });
    }

    const regs = adc.get_regs();
    regs.CR2.modify(.{ .ADON = @intFromBool(enable) });

    if (enable) {
        regs.SQR1.modify(.{ .L = 0 });
        regs.SQR3.modify(.{ .SQ = @intFromEnum(channel) });
    }
}

pub fn convert(adc: ADC) u16 {
    const regs = adc.get_regs();
    regs.CR2.modify(.{ .SWSTART = 1 });
    // while (mem.SR.read().EOC == 0) {}
    return regs.DR.read().DATA;
}
