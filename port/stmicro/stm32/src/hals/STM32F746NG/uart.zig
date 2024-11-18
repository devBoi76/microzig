const std = @import("std");
const microzig = @import("microzig");
pub const peripherals = microzig.chip.peripherals;

const gpio = @import("gpio.zig");

const UartRegs = @TypeOf(peripherals.USART1);

pub const UART = enum(u8) {
    USART1 = 0,
    USART2,
    USART3,
    UART4,
    UART5,
    USART6,
    UART7,
    UART8,

    pub fn getRegs(n: UART) UartRegs {
        return switch (n) {
            inline else => |nn| @field(peripherals, @tagName(nn)),
        };
    }
    /// Note: check documentation for which pins can be used as UART pins
    pub fn init(n: UART, tx_pin: gpio.Pin, rx_pin: gpio.Pin, baud_rate: usize) UART {
        // enable all gpio
        gpio.enable_gpio(true);
        // configure gpio for alternate function
        tx_pin.set_mode(.alternate_function);
        rx_pin.set_mode(.alternate_function);
        // common for all stm32f745xx and stm32f746xx

        tx_pin.set_alternate_function(switch (n) {
            .USART1, .USART2, .USART3 => 7,
            .USART6, .UART4, .UART7, .UART8 => 8,
            .UART5 => switch (tx_pin.port) { // >:(
                2 => 7, // PC8, PC9
                else => 8, // PC12, PD2,
            },
        });
        rx_pin.set_alternate_function(switch (n) {
            .USART1, .USART2, .USART3 => 7,
            .USART6, .UART4, .UART7, .UART8 => 8,
            .UART5 => switch (rx_pin.port) { // >:(
                2 => 7, // PC8, PC9
                else => 8, // PC12, PD2,
            },
        });
        // enable UART clock
        switch (n) {
            .USART1 => peripherals.RCC.APB2ENR.modify(.{ .USART1EN = 1 }),
            .USART6 => peripherals.RCC.APB2ENR.modify(.{ .USART6EN = 1 }),

            .USART2 => peripherals.RCC.APB1ENR.modify(.{ .USART2EN = 1 }),
            .USART3 => peripherals.RCC.APB1ENR.modify(.{ .USART3EN = 1 }),
            .UART4 => peripherals.RCC.APB1ENR.modify(.{ .UART4EN = 1 }),
            .UART5 => peripherals.RCC.APB1ENR.modify(.{ .UART5EN = 1 }),
            .UART7 => peripherals.RCC.APB1ENR.modify(.{ .UART7EN = 1 }),
            .UART8 => peripherals.RCC.APB1ENR.modify(.{ .UART8EN = 1 }),
        }
        // configure baud rate
        n.setBaudRate(baud_rate);

        // UARTEnable, TxEnable, RxEnable
        n.getRegs().CR1.modify(.{ .UE = 1, .TE = 1, .RE = 1 });

        return n;
    }

    pub fn setBaudRate(uart: UART, rate: usize) void {
        // TODO: get automatically
        const PCLK = 16_000_000;
        // TODO: Verify baud rate
        uart.getRegs().BRR.modify(.{ .BRR = @as(u16, @intCast(PCLK / rate)) });
    }

    pub fn txReady(uart: UART) bool {
        return uart.getRegs().ISR.read().TXE == 1;
    }

    pub fn writeByte(uart: UART, b: u8) void {
        while (uart.txReady() == false) {}
        uart.getRegs().TDR.raw = @intCast(b);
    }

    pub fn writeBytes(uart: UART, bytes: []const u8) void {
        for (bytes) |b| uart.writeByte(b);
    }
};
