const microzig = @import("microzig");
pub const peripherals = microzig.chip.peripherals;
const gpio = @import("gpio.zig");

pub const ADC = enum(u2) {
    ADC1 = 0,
    ADC2 = 1,
    ADC3 = 2,

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
    const Resolution = enum(u2) {
        @"12bit" = 0,
        @"10bit" = 1,
        @"8bit" = 2,
        @"6bit" = 3,
    };
    const SamplingTime = enum(u3) {
        @"3",
        @"15",
        @"28",
        @"56",
        @"84",
        @"112",
        @"144",
        @"480",
    };

    pub const ADC1 = peripherals.ADC1;
    pub const ADC2 = peripherals.ADC2;
    pub const ADC3 = peripherals.ADC3;
    const ADCMemory = @TypeOf(ADC1);

    pub fn init(adc: ADC) ADC {
        return .{
            .number = @intFromEnum(adc),
        };
    }

    pub inline fn getRegs(adc: ADC) ADCMemory {
        return switch (adc) {
            .ADC1 => ADC1,
            .ADC2 => ADC2,
            .ADC3 => ADC3,
            else => @panic("This board supports only 3 ADCs (1..3"),
        };
    }

    pub fn setEnabled(adc: ADC, channel: ADCChannel, enable: bool) void {
        const APB2ENR = peripherals.RCC.APB2ENR;
        // .raw |= @as(u32, 0x100) << @as(u2, @intFromEnum(adc));
        switch (adc) {
            .ADC1 => APB2ENR.modify(.{ .ADC1EN = 1 }),
            .ADC2 => APB2ENR.modify(.{ .ADC2EN = 1 }),
            .ADC3 => APB2ENR.modify(.{ .ADC3EN = 1 }),
        }

        if (channel == .ADC1_IN17 or channel == .ADC1_IN18) {
            if (adc.number != 0) {
                // TODO: what to do here?
                return;
            }
            microzig.chip.peripherals.ADC123_COMMON.CCR.modify(.{ .TSVREFE = @intFromBool(enable) });
        }

        const regs = adc.getRegs();
        // enable ADC
        regs.CR2.modify(.{ .ADON = @intFromBool(enable) });

        if (enable) {
            regs.SQR1.modify(.{ .L = 0 }); // squence length == 1
            regs.SQR3.modify(.{ .SQ = @intFromEnum(channel) }); // 1st conversion is channel
        }
    }
    pub fn setResolution(adc: ADC, res: Resolution) void {
        adc.getRegs().CR1.modify(.{ .RES = res });
    }
    pub fn getResolution(adc: ADC) Resolution {
        return @enumFromInt(return adc.getRegs().CR1.read().RES);
    }

    pub fn convert(adc: ADC) u16 {
        const regs = adc.getRegs();
        regs.CR2.modify(.{ .SWSTART = 1 });
        while (regs.SR.read().EOC == 0) {}
        return regs.DR.read().DATA;
    }
    pub fn convert_sequence(adc: ADC, channels: []const ADCChannel) [16]u16 {
        if (channels.len == 0) return undefined;

        var ret: [16]u16 = undefined;

        const regs = adc.getRegs();
        for (channels, 0..) |chan, i| {
            regs.SQR1.modify(.{ .L = channels.len - 1 }); // squence length == 1
            switch (i) {
                0...5 => gpio.setRegValue(ADCChannel, &regs.SQR3.raw, chan, i),
                6...11 => gpio.setRegValue(ADCChannel, &regs.SQR3.raw, chan, i - 6),
                12...15 => gpio.setRegValue(ADCChannel, &regs.SQR3.raw, chan, i - 12),
                else => break,
            }
        }
        const old_eocs = regs.CR2.read().EOCS;
        regs.CR2.modify(.{ .EOCS = 1 });
        for (0..channels.len) |i| {
            regs.CR2.modify(.{ .SWSTART = 1 });
            while (regs.SR.read().EOC == 0) {}
            ret[i] = regs.DR.read().DATA;
            regs.SR.modify(.{ .OVR = 0 });
        }
        regs.CR2.modify(.{ .EOCS = old_eocs });
        return ret;
    }
    pub fn setDMA(adc: ADC, enable: bool) void {
        adc.getRegs().CR2.modify(.{ .DMA = @intFromBool(enable) });
        // adc.getRegs().
    }
};
