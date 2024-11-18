const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
const gpio = @import("gpio.zig");

pub fn enable_clocks() void {
    peripherals.RCC.APB1ENR.modify(.{
        .TIM2EN = 1,
        .TIM3EN = 1,
        .TIM4EN = 1,
        .TIM5EN = 1,
        .TIM6EN = 1,
        .TIM7EN = 1,
        .TIM12EN = 1,
        .TIM13EN = 1,
        .TIM14EN = 1,
    });
    peripherals.RCC.APB2ENR.modify(.{
        .TIM1EN = 1,
        .TIM8EN = 1,
        .TIM9EN = 1,
        .TIM10EN = 1,
        .TIM11EN = 1,
    });
    // TODO: enable clocks in low power mode
}
pub const Advanced = struct {
    pub const Timer = enum(u1) {
        TIM1,
        TIM8,
    };
    pub const TIM1 = peripherals.TIM1;
    pub const TIM8 = peripherals.TIM8;
    pub const TIM = @TypeOf(TIM1);

    number: Timer,
    pub fn init(t: Timer) Advanced {
        return .{
            .number = t,
        };
    }
    pub fn get_regs(timer: Advanced) TIM {
        return switch (timer.number) {
            .TIM1 => TIM1,
            .TIM8 => TIM8,
        };
    }
    pub fn put(timer: Advanced, freq: u16, duty: u16, channel: u4) void {
        const regs_core: *volatile microzig.chip.types.peripherals.timer_v1.TIM_CORE = @ptrCast(timer.get_regs());
        regs_core.ARR.modify(.{ .ARR = freq });
        const regs = timer.get_regs();
        if (channel < 4) {
            regs.CCR[channel].modify(.{
                .CCR = duty,
            });
            // PWM mode 1
            regs.CCMR_Input[0].modify(.{
                // TODO: switch to enum
                .ICF = .{ .raw = 0b0110 },
                .ICPSC = 0b10,
            });
            regs_core.CR1.modify(.{
                .ARPE = 1,
                .CEN = 1,
            });
            regs_core.EGR.modify(.{
                .UG = 1,
            });
            regs.BDTR.raw |= 1 << 15; // MOE
            gpio.set_reg_value(u4, &regs.CCER.raw, 0b0001, channel);
        } else {
            // TODO: Other channels
        }
    }
};
