const microzig = @import("microzig");
const mmio = microzig.mmio;

pub const SystemControlBlock = extern struct {
    /// CPUID Base Register
    CPUID: u32,
    /// Interrupt Control and State Register
    ICSR: mmio.Mmio(packed struct(u32) {
        VECTACTIVE: u9,
        reserved0: u2 = 0,
        RETTOBASE: u1,
        VECTPENDING: u9,
        reserved1: u1 = 0,
        ISRPENDING: u1,
        ISRPREEMPT: u1,
        reserved2: u1 = 0,
        PENDSTCLR: u1,
        PENDSTSET: u1,
        PENDSVCLR: u1,
        PENDSVSET: u1,
        reserved3: u2 = 0,
        NMIPENDSET: u1,
    }),
    /// Vector Table Offset Register
    VTOR: u32,
    /// Application Interrupt  and Reset Control Register
    AIRCR: u32,
    /// System Control Register
    SCR: u32,
    /// Configuration Control Register
    CCR: mmio.Mmio(packed struct(u32) {
        NONBASETHRDENA: u1,
        USERSETMPEND: u1,
        _reserved0: u1 = 0,
        UNALIGN_TRP: u1,
        DIV_0_TRP: u1,
        _reserved1: u3 = 0,
        BFHFNMIGN: u1,
        STKALIGN: u1,
        _padding: u22 = 0,
    }),
    /// System Handlers Priority Registers
    SHP: [3]u8,
    /// System Handler Contol and State Register
    SHCSR: u32,
    /// Configurable Fault Status Register
    CFSR: u32,
    /// MemManage Fault Status Register
    MMSR: u32,
    /// BusFault Status Register
    BFSR: u32,
    /// UsageFault Status Register
    UFSR: u32,
    /// HardFault Status Register
    HFSR: u32,
    /// MemManage Fault Address Register
    MMAR: u32,
    /// BusFault Address Register
    BFAR: u32,
    /// Auxiliary Fault Status Register not implemented
    AFSR: u32,

    /// Processor Feature Register
    PFR: [2]u32,
    /// Debug Feature Register
    DFR: u32,
    /// Auxilary Feature Register
    ADR: u32,
    /// Memory Model Feature Register
    MMFR: [4]u32,
    /// Instruction Set Attributes Register
    ISAR: [5]u32,
    RESERVED0: [5]u32,
    /// Coprocessor Access Control Register
    CPACR: u32,
};

pub const NestedVectorInterruptController = extern struct {
    /// Interrupt Set-enable Registers
    ISER: [7]u32,
    _reserved0: [25]u32,
    /// Interrupt Clear-enable Registers
    ICER: [7]u32,
    _reserved1: [25]u32,
    /// Interrupt Set-pending Registers
    ISPR: [7]u32,
    _reserved2: [25]u32,
    /// Interrupt Clear-pending Registers
    ICPR: [7]u32,
    _reserved3: [25]u32,
    /// Interrupt Active Bit Registers
    IABR: [7]u32,
    _reserved4: [57]u32,
    /// Interrupt Priority Registers
    IP: [239]u8,
    _reserved5: [2577]u8,
    /// Software Trigger Interrupt Register
    STIR: u32,
};

pub const MemoryProtectionUnit = extern struct {
    /// MPU Type Register
    TYPE: mmio.Mmio(packed struct(u32) {
        SEPARATE: u1,
        _reserved0: u7,
        DREGION: u8,
        IREGION: u8,
        _reserved1: u8,
    }),
    /// MPU Control Register
    CTRL: mmio.Mmio(packed struct(u32) {
        ENABLE: u1,
        HFNMIENA: u1,
        PRIVDEFENA: u1,
        padding: u29,
    }),
    /// MPU RNRber Register
    RNR: mmio.Mmio(packed struct(u32) {
        REGION: u8,
        padding: u24,
    }),
    /// MPU Region Base Address Register
    RBAR: RBAR,
    /// MPU Region Attribute and Size Register
    RASR: RASR,
    /// MPU Alias 1 Region Base Address Register
    RBAR_A1: RBAR,
    /// MPU Alias 1 Region Attribute and Size Register
    RASR_A1: RASR,
    /// MPU Alias 2 Region Base Address Register
    RBAR_A2: RBAR,
    /// MPU Alias 2 Region Attribute and Size Register
    RASR_A2: RASR,
    /// MPU Alias 3 Region Base Address Register
    RBAR_A3: RBAR,
    /// MPU Alias 3 Region Attribute and Size Register
    RASR_A3: RASR,

    pub const RBAR = mmio.Mmio(packed struct(u32) {
        REGION: u4,
        VALID: u1,
        ADDR: u27,
    });

    pub const RASR = mmio.Mmio(packed struct(u32) {
        /// Region enable bit
        ENABLE: u1,
        /// Region Size
        SIZE: u5,
        _reserved0: u2,
        /// Sub-Region Disable
        SRD: u8,
        /// ATTRS.B
        B: u1,
        /// ATTRS.C
        C: u1,
        /// ATTRS.S
        S: u1,
        /// ATTRS.TEX
        TEX: u3,
        _reserved1: u2,
        /// ATTRS.AP
        AP: u3,
        /// ATTRS.XN
        XN: u1,
        padding: u4,
    });
};

pub const DebugRegisters = @import("m4.zig").DebugRegisters;

pub const ITM = extern struct {
    /// TODO: Figure out the actual amount of stim ports
    ITM_STIM: [256]mmio.Mmio(packed union {
        WRITE_U8: u8,
        WRITE_U16: u16,
        WRITE_U32: u32,
        READ: packed struct(u32) {
            _reserved: u31,
            FIFOREADY: u1,
        },
    }),
    _padding0: [2566]u8,
    ITM_TER: [8]mmio.Mmio(packed struct(u32) {
        STIMENA: u32,
    }),
    _padding1: [40]u8,
    ITM_TPR: mmio.Mmio(packed struct(u32) {
        PRIVMASK: u32,
    }),
    _padding2: [64]u8,
    ITM_TCR: mmio.Mmio(packed struct(u32) {
        _reserved0: u8,
        BUSY: u1,
        TraceBusID: u7,
        _reserved1: u4,
        GTSFREQ: u2,
        TSPrescale: u2,
        _reserved2: u3,
        SWOENA: u1,
        TXENA: u1,
        SYNCENA: u1,
        TSENA: u1,
        ITMENA: u1,
    }),
};
