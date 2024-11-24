const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;

const DMARegs = @TypeOf(peripherals.DMA1);

pub const BURST = enum(u2) {
    ///  Single transfer
    Single = 0x0,
    ///  Incremental burst of 4 beats
    INCR4 = 0x1,
    ///  Incremental burst of 8 beats
    INCR8 = 0x2,
    ///  Incremental burst of 16 beats
    INCR16 = 0x3,
};

pub const CT = enum(u1) {
    ///  The current target memory is Memory 0
    Memory0 = 0x0,
    ///  The current target memory is Memory 1
    Memory1 = 0x1,
};

pub const DIR = enum(u2) {
    ///  Peripheral-to-memory
    PeripheralToMemory = 0x0,
    ///  Memory-to-peripheral
    MemoryToPeripheral = 0x1,
    ///  Memory-to-memory
    MemoryToMemory = 0x2,
    _,
};

pub const DMDIS = enum(u1) {
    ///  Direct mode is enabled
    Enabled = 0x0,
    ///  Direct mode is disabled
    Disabled = 0x1,
};

pub const FS = enum(u3) {
    ///  0 < fifo_level < 1/4
    Quarter1 = 0x0,
    ///  1/4 <= fifo_level < 1/2
    Quarter2 = 0x1,
    ///  1/2 <= fifo_level < 3/4
    Quarter3 = 0x2,
    ///  3/4 <= fifo_level < full
    Quarter4 = 0x3,
    ///  FIFO is empty
    Empty = 0x4,
    ///  FIFO is full
    Full = 0x5,
    _,
};

pub const FTH = enum(u2) {
    ///  1/4 full FIFO
    Quarter = 0x0,
    ///  1/2 full FIFO
    Half = 0x1,
    ///  3/4 full FIFO
    ThreeQuarters = 0x2,
    ///  Full FIFO
    Full = 0x3,
};

pub const PFCTRL = enum(u1) {
    ///  The DMA is the flow controller
    DMA = 0x0,
    ///  The peripheral is the flow controller
    Peripheral = 0x1,
};

pub const PINCOS = enum(u1) {
    ///  The offset size for the peripheral address calculation is linked to the PSIZE
    PSIZE = 0x0,
    ///  The offset size for the peripheral address calculation is fixed to 4 (32-bit alignment)
    Fixed4 = 0x1,
};

pub const PL = enum(u2) {
    ///  Low
    Low = 0x0,
    ///  Medium
    Medium = 0x1,
    ///  High
    High = 0x2,
    ///  Very high
    VeryHigh = 0x3,
};

pub const SIZE = enum(u2) {
    ///  Byte (8-bit)
    Bits8 = 0x0,
    ///  Half-word (16-bit)
    Bits16 = 0x1,
    ///  Word (32-bit)
    Bits32 = 0x2,
    _,
};

const DMA = enum(u1) {
    DMA1 = 0,
    DMA2 = 1,
};
