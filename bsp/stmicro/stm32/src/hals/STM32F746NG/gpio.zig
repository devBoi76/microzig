//! references:
//! - reference manual: https://www.st.com/resource/en/reference_manual/rm0385-stm32f75xxx-and-stm32f74xxx-advanced-armbased-32bit-mcus-stmicroelectronics.pdf
//! - datasheet: https://www.st.com/resource/en/datasheet/stm32f746ng.pdf
const std = @import("std");
const assert = std.debug.assert;

const microzig = @import("microzig");
pub const peripherals = microzig.chip.peripherals;

pub const GPIOA = peripherals.GPIOA;
pub const GPIOB = peripherals.GPIOB;
pub const GPIOC = peripherals.GPIOC;
pub const GPIOD = peripherals.GPIOD;
pub const GPIOE = peripherals.GPIOE;
pub const GPIOF = peripherals.GPIOF;
pub const GPIOG = peripherals.GPIOG;
pub const GPIOH = peripherals.GPIOH;
pub const GPIOI = peripherals.GPIOI;
pub const GPIOJ = peripherals.GPIOJ;
pub const GPIOK = peripherals.GPIOK;

const GPIO = @TypeOf(GPIOA);

const log = std.log.scoped(.gpio);

pub const Mode = enum(u2) {
    input = 0b00,
    general_purpose_output = 0b01,
    alternate_function = 0b10,
    analog = 0b11,
};

pub const OutputType = enum(u2) {
    general_purpose_push_pull = 0,
    general_purpose_open_drain = 1,
};

/// Speeds in datasheet Table 58
pub const Speed = enum(u2) {
    low = 0,
    medium = 1,
    high = 2,
    very_high = 3,
};

pub const Pull = enum(u2) {
    none = 0,
    up = 1,
    down = 2,
};

pub inline fn set_reg_value(comptime T: type, reg: *volatile u32, val: T, offset: u4) void {
    const v = if (comptime @typeInfo(T) == .Enum) @intFromEnum(val) else val;
    const off: u5 = @as(u5, @intCast(offset)) * @bitSizeOf(T);
    reg.* &= ~(@as(u32, (2 << @bitSizeOf(T)) - 1) << off); // zero the bits
    reg.* |= (@as(u32, v) << off); // write the value
}

/// Must be called to enable GPIO clock. Reference manual 5.3.10
pub fn enable_gpio(enable_in_low_power: bool) void {
    peripherals.RCC.AHB1ENR.raw |= 0x000007FF;
    if (enable_in_low_power) {
        peripherals.RCC.AHB1LPENR.raw |= 0x000007FF;
    }
}

// NOTE: With this current setup, every time we want to do anythting we go through a switch
//       Do we want this?
pub const Pin = packed struct(u8) {
    number: u4,
    port: u4,

    pub fn init(port: u4, number: u4) Pin {
        return Pin{
            .number = number,
            .port = port,
        };
    }

    // NOTE: Im not sure I like this
    //       We could probably calculate an offset from GPIOA?
    pub fn get_port(gpio: Pin) GPIO {
        return switch (gpio.port) {
            0 => GPIOA,
            1 => GPIOB,
            2 => GPIOC,
            3 => GPIOD,
            4 => GPIOE,
            5 => GPIOF,
            6 => GPIOG,
            7 => GPIOH,
            8 => GPIOI,
            9 => GPIOJ,
            10 => GPIOK,
            else => @panic("The STM32 only has ports 0..10 (A..K)"),
        };
    }

    inline fn mask(gpio: Pin) u16 {
        return @as(u16, 1) << gpio.number;
    }

    pub inline fn set_mode(gpio: Pin, mode: Mode) void {
        const port = gpio.get_port();
        set_reg_value(Mode, &port.MODER.raw, mode, gpio.number);
    }

    pub inline fn set_alternate_function(gpio: Pin, n: u4) void {
        const regs = gpio.get_port();
        if (gpio.number < 8) {
            set_reg_value(u4, &regs.AFR[0].raw, n, gpio.number);
        } else {
            set_reg_value(u4, &regs.AFR[1].raw, n, gpio.number - 8);
        }
    }
    pub inline fn set_pull(gpio: Pin, pull: Pull) void {
        set_reg_value(Pull, &gpio.get_port().PUPDR.raw, pull, gpio.number);
    }

    pub inline fn set_output_type(gpio: Pin, output_type: OutputType) void {
        set_reg_value(OutputType, &gpio.get_port().OTYPER, output_type, gpio.number);
    }

    pub inline fn read(gpio: Pin) u1 {
        const port = gpio.get_port();
        return @intFromBool(port.IDR.raw & gpio.mask() != 0);
    }

    pub inline fn put(gpio: Pin, value: u1) void {
        var port = gpio.get_port();
        switch (value) {
            0 => port.BSRR.raw = (@as(u32, 1) << gpio.number) << 16,
            1 => port.BSRR.raw = (@as(u32, 1) << gpio.number),
        }
    }

    pub inline fn toggle(gpio: Pin) void {
        gpio.put(~gpio.read());
        // var port = gpio.get_port();
        // port.ODR.raw ^= gpio.mask();
    }
};
