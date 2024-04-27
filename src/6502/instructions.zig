//! Instructions for the 65c02 Micro Processor
//!
//! This file defines all Instructions and the micro-optomisations that make up each
//! operation.
const mpu_core = @import("mpu.zig");
const MPU = mpu_core.MPU;
const Instruction = mpu_core.Instruction;
const MicroOp = mpu_core.MicroOp;
const MicroOpError = mpu_core.MicroOpError;

const adc = @import("micro-ops/arithmetic.zig").adc;
const adc_immediate = @import("micro-ops/arithmetic.zig").adc_immediate;
const and_ = @import("micro-ops/logical.zig").and_;
const and_immediate = @import("micro-ops/logical.zig").and_immediate;
const ac_to_xr = @import("micro-ops/transfer.zig").ac_to_xr;
const ac_to_yr = @import("micro-ops/transfer.zig").ac_to_yr;
const asl = @import("micro-ops/bitshift.zig").asl;
const asl_immediate = @import("micro-ops/bitshift.zig").asl_immediate;
const bcc = @import("micro-ops/branch.zig").bcc;
const bcs = @import("micro-ops/branch.zig").bcs;
const beq = @import("micro-ops/branch.zig").beq;
const bmi = @import("micro-ops/branch.zig").bmi;
const bne = @import("micro-ops/branch.zig").bne;
const bpl = @import("micro-ops/branch.zig").bpl;
const bvc = @import("micro-ops/branch.zig").bvc;
const bvs = @import("micro-ops/branch.zig").bvs;
const clc = @import("micro-ops/flag.zig").clc;
const cld = @import("micro-ops/flag.zig").cld;
const cli = @import("micro-ops/flag.zig").cli;
const clv = @import("micro-ops/flag.zig").clv;
const cmp = @import("micro-ops/comparison.zig").cmp;
const cmp_immediate = @import("micro-ops/comparison.zig").cmp_immediate;
const cpx = @import("micro-ops/comparison.zig").cpx;
const cpx_immediate = @import("micro-ops/comparison.zig").cpx_immediate;
const cpy = @import("micro-ops/comparison.zig").cpy;
const cpy_immediate = @import("micro-ops/comparison.zig").cpy_immediate;
const dec = @import("micro-ops/increments.zig").dec;
const dex = @import("micro-ops/increments.zig").dex;
const dey = @import("micro-ops/increments.zig").dey;
const eor = @import("micro-ops/logical.zig").eor;
const eor_immediate = @import("micro-ops/logical.zig").eor_immediate;
const inc = @import("micro-ops/increments.zig").inc;
const inx = @import("micro-ops/increments.zig").inx;
const iny = @import("micro-ops/increments.zig").iny;
const lsr = @import("micro-ops/bitshift.zig").lsr;
const lsr_immediate = @import("micro-ops/bitshift.zig").lsr_immediate;
const ora = @import("micro-ops/logical.zig").ora;
const ora_immediate = @import("micro-ops/logical.zig").ora_immediate;
const pull_ac = @import("micro-ops/stack.zig").pull_ac;
const pull_pc_l = @import("micro-ops/stack.zig").pull_pc_l;
const pull_pc_h = @import("micro-ops/stack.zig").pull_pc_h;
const pull_sr = @import("micro-ops/stack.zig").pull_sr;
const push_ac = @import("micro-ops/stack.zig").push_ac;
const push_pc_l = @import("micro-ops/stack.zig").push_pc_l;
const push_pc_l_word_offset = @import("micro-ops/stack.zig").push_pc_l_word_offset;
const push_pc_h = @import("micro-ops/stack.zig").push_pc_h;
const push_pc_h_word_offset = @import("micro-ops/stack.zig").push_pc_h_word_offset;
const push_sr = @import("micro-ops/stack.zig").push_sr;
const rol = @import("micro-ops/bitshift.zig").rol;
const rol_immediate = @import("micro-ops/bitshift.zig").rol_immediate;
const ror = @import("micro-ops/bitshift.zig").ror;
const ror_immediate = @import("micro-ops/bitshift.zig").ror_immediate;
const sbc = @import("micro-ops/arithmetic.zig").sbc;
const sbc_immediate = @import("micro-ops/arithmetic.zig").sbc_immediate;
const sec = @import("micro-ops/flag.zig").sec;
const sed = @import("micro-ops/flag.zig").sed;
const sei = @import("micro-ops/flag.zig").sei;
const sp_to_xr = @import("micro-ops/transfer.zig").sp_to_xr;
const xr_to_ac = @import("micro-ops/transfer.zig").xr_to_ac;
const xr_to_sp = @import("micro-ops/transfer.zig").xr_to_sp;
const yr_to_ac = @import("micro-ops/transfer.zig").yr_to_ac;

/// Non-maskable interrupt vector
pub const NMI_VECTOR_L: u16 = 0xFFFA;
const NMI_VECTOR_H: u16 = 0xFFFB;
/// Reset vector
pub const RESET_VECTOR_L: u16 = 0xFFFC;
const RESET_VECTOR_H: u16 = 0xFFFD;
/// Interrupt vector
pub const IRQ_VECTOR_L: u16 = 0xFFFE;
const IRQ_VECTOR_H: u16 = 0xFFFF;

pub const NMI_OPERATION: Instruction = Instruction{
    .len = 6,
    .micro_ops = [6]*const MicroOp{ sei, push_pc_h, push_pc_l, push_sr, nmi_vector_to_pc, jmp },
    .syntax = "NMI",
};
pub const RESET_OPERATION: Instruction = Instruction{
    .len = 6,
    .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, reset_vector_to_pc, jmp },
    .syntax = "Reset",
};
pub const IRQ_OPERATION: Instruction = Instruction{
    .len = 6,
    .micro_ops = [6]*const MicroOp{ sei, push_pc_h, push_pc_l, push_sr, irq_vector_to_pc, jmp },
    .syntax = "IRQ",
};

pub const OPERATIONS = [_]Instruction{
    Instruction{ .syntax = "BRK impl", .len = 6, .micro_ops = [6]*const MicroOp{ sei, push_pc_h, push_pc_l, push_sr, irq_vector_to_pc, jmp } }, // 0x00: BRK impl
    Instruction{ .syntax = "ORA X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x01: ORA X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x02:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x03:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x04:
    Instruction{ .syntax = "ORA zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, ora, nop, nop, nop, nop } }, // 0x05: ORA zpg
    Instruction{ .syntax = "ASL zpg", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_data, asl, data_write_to_addr, nop, nop } }, // 0x06: ASL zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x07:
    Instruction{ .syntax = "PHP impl", .len = 2, .micro_ops = [6]*const MicroOp{ nop, push_sr, nop, nop, nop, nop } }, // 0x08: PHP impl
    Instruction{ .syntax = "ORA #", .len = 1, .micro_ops = [6]*const MicroOp{ ora_immediate, nop, nop, nop, nop, nop } }, // 0x09: ORA #
    Instruction{ .syntax = "ASL A", .len = 1, .micro_ops = [6]*const MicroOp{ asl_immediate, nop, nop, nop, nop, nop } }, // 0x0A: ASL A
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x0B:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x0C:
    Instruction{ .syntax = "ORA abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, ora, nop, nop, nop } }, // 0x0D: ORA abs
    Instruction{ .syntax = "ASL abs", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, asl, data_write_to_addr, nop } }, // 0x0E: ASL abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x0F:
    Instruction{ .syntax = "BPL rel", .len = 2, .micro_ops = [6]*const MicroOp{ bpl, nop, nop, nop, nop, nop } }, // 0x10: BPL rel
    Instruction{ .syntax = "ORA ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x11: ORA ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x12:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x13:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x14:
    Instruction{ .syntax = "ORA zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, ora, nop, nop, nop } }, // 0x15: ORA zpg,X
    Instruction{ .syntax = "ASL zpg,X", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, asl, data_write_to_addr, nop } }, // 0x16: ASL zpg,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x17:
    Instruction{ .syntax = "CLC impl", .len = 1, .micro_ops = [6]*const MicroOp{ clc, nop, nop, nop, nop, nop } }, // 0x18: CLC impl
    Instruction{ .syntax = "ORA abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, ora, nop, nop, nop } }, // 0x19: ORA abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x1A:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x1B:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x1C:
    Instruction{ .syntax = "ORA abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, ora, nop, nop, nop } }, // 0x1D: ORA abs,X
    Instruction{ .syntax = "ASL abs,X", .len = 6, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, asl, addr_read_to_data } }, // 0x1E: ASL abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x1F:
    Instruction{ .syntax = "JSR abs", .len = 5, .micro_ops = [6]*const MicroOp{ push_pc_h_word_offset, push_pc_l_word_offset, pc_read_to_addr, pc_read_to_addr_h, jsr, nop } }, // 0x20: JSR abs
    Instruction{ .syntax = "AND X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x21: AND X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x22:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x23:
    Instruction{ .syntax = "BIT zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, bit, nop, nop, nop, nop } }, // 0x24: BIT zpg
    Instruction{ .syntax = "AND zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, and_, nop, nop, nop, nop } }, // 0x25: AND zpg
    Instruction{ .syntax = "ROL zpg", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_data, rol, data_write_to_addr, nop, nop } }, // 0x26: ROL zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x27:
    Instruction{ .syntax = "PLP impl", .len = 2, .micro_ops = [6]*const MicroOp{ pull_sr, nop, nop, nop, nop, nop } }, // 0x28: PLP impl
    Instruction{ .syntax = "AND #", .len = 1, .micro_ops = [6]*const MicroOp{ and_immediate, nop, nop, nop, nop, nop } }, // 0x29: AND #
    Instruction{ .syntax = "ROL A", .len = 1, .micro_ops = [6]*const MicroOp{ rol_immediate, nop, nop, nop, nop, nop } }, // 0x2A: ROL A
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x2B:
    Instruction{ .syntax = "BIT abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, bit, nop, nop, nop } }, // 0x2C: BIT abs
    Instruction{ .syntax = "AND abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, and_, nop, nop, nop } }, // 0x2D: AND abs
    Instruction{ .syntax = "ROL abs", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, rol, data_write_to_addr, nop } }, // 0x2E: ROL abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x2F:
    Instruction{ .syntax = "BMI rel", .len = 2, .micro_ops = [6]*const MicroOp{ bmi, nop, nop, nop, nop, nop } }, // 0x30: BMI rel
    Instruction{ .syntax = "AND ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x31: AND ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x32:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x33:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x34:
    Instruction{ .syntax = "AND zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, and_, nop, nop, nop } }, // 0x35: AND zpg,X
    Instruction{ .syntax = "ROL zpg,X", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, rol, data_write_to_addr, nop } }, // 0x36: ROL zpg,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x37:
    Instruction{ .syntax = "SEC impl", .len = 1, .micro_ops = [6]*const MicroOp{ sec, nop, nop, nop, nop, nop } }, // 0x38: SEC impl
    Instruction{ .syntax = "AND abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, and_, nop, nop, nop } }, // 0x39: AND abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x3A:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x3B:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x3C:
    Instruction{ .syntax = "AND abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, and_, nop, nop, nop } }, // 0x3D: AND abs,X
    Instruction{ .syntax = "ROL abs,X", .len = 6, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, rol, data_write_to_addr } }, // 0x3E: ROL abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x3F:
    Instruction{ .syntax = "RTI impl", .len = 5, .micro_ops = [6]*const MicroOp{ pull_sr, pull_pc_l, pull_pc_h, addr_to_pc, rti, nop } }, // 0x40: RTI impl
    Instruction{ .syntax = "EOR X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x41: EOR X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x42:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x43:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x44:
    Instruction{ .syntax = "EOR zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, eor, nop, nop, nop, nop } }, // 0x45: EOR zpg
    Instruction{ .syntax = "LSR zpg", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_data, lsr, data_write_to_addr, nop, nop } }, // 0x46: LSR zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x47:
    Instruction{ .syntax = "PHA impl", .len = 2, .micro_ops = [6]*const MicroOp{ nop, push_ac, nop, nop, nop, nop } }, // 0x48: PHA impl
    Instruction{ .syntax = "EOR #", .len = 1, .micro_ops = [6]*const MicroOp{ eor_immediate, nop, nop, nop, nop, nop } }, // 0x49: EOR #
    Instruction{ .syntax = "LSR A", .len = 1, .micro_ops = [6]*const MicroOp{ lsr_immediate, nop, nop, nop, nop, nop } }, // 0x4A: LSR A
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x4B:
    Instruction{ .syntax = "JMP abs", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, jmp, nop, nop, nop, nop } }, // 0x4C: JMP abs
    Instruction{ .syntax = "EOR abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, eor, nop, nop, nop } }, // 0x4D: EOR abs
    Instruction{ .syntax = "LSR abs", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, lsr, data_write_to_addr, nop } }, // 0x4E: LSR abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x4F:
    Instruction{ .syntax = "BVC rel", .len = 2, .micro_ops = [6]*const MicroOp{ bvc, nop, nop, nop, nop, nop } }, // 0x50: BVC rel
    Instruction{ .syntax = "EOR ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x51: EOR ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x52:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x53:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x54:
    Instruction{ .syntax = "EOR zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, eor, nop, nop, nop } }, // 0x55: EOR zpg,X
    Instruction{ .syntax = "LSR zpg,X", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, lsr, data_write_to_addr, nop } }, // 0x56: LSR zpg,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x57:
    Instruction{ .syntax = "CLI impl", .len = 1, .micro_ops = [6]*const MicroOp{ cli, nop, nop, nop, nop, nop } }, // 0x58: CLI impl
    Instruction{ .syntax = "EOR abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, eor, nop, nop, nop } }, // 0x59: EOR abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x5A:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x5B:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x5C:
    Instruction{ .syntax = "EOR abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, eor, nop, nop, nop } }, // 0x5D: EOR abs,X
    Instruction{ .syntax = "LSR abs,X", .len = 6, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, lsr, data_write_to_addr } }, // 0x5E: LSR abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x5F:
    Instruction{ .syntax = "RTS impl", .len = 3, .micro_ops = [6]*const MicroOp{ pull_pc_l, pull_pc_h, jmp, nop, nop, nop } }, // 0x60: RTS impl
    Instruction{ .syntax = "ADC X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x61: ADC X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x62:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x63:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x64:
    Instruction{ .syntax = "ADC zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, adc, nop, nop, nop, nop } }, // 0x65: ADC zpg
    Instruction{ .syntax = "ROR zpg", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_data, ror, data_write_to_addr, nop, nop } }, // 0x66: ROR zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x67:
    Instruction{ .syntax = "PLA impl", .len = 2, .micro_ops = [6]*const MicroOp{ pull_ac, nop, nop, nop, nop, nop } }, // 0x68: PLA impl
    Instruction{ .syntax = "ADC #", .len = 1, .micro_ops = [6]*const MicroOp{ adc_immediate, nop, nop, nop, nop, nop } }, // 0x69: ADC #
    Instruction{ .syntax = "ROR A", .len = 1, .micro_ops = [6]*const MicroOp{ ror_immediate, nop, nop, nop, nop, nop } }, // 0x6A: ROR A
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x6B:
    Instruction{ .syntax = "JMP ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x6C: JMP ind
    Instruction{ .syntax = "ADC abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, adc, nop, nop, nop } }, // 0x6D: ADC abs
    Instruction{ .syntax = "ROR abs", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, ror, data_write_to_addr, nop } }, // 0x6E: ROR abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x6F:
    Instruction{ .syntax = "BVS rel", .len = 2, .micro_ops = [6]*const MicroOp{ bvs, nop, nop, nop, nop, nop } }, // 0x70: BVS rel
    Instruction{ .syntax = "ADC ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x71: ADC ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x72:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x73:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x74:
    Instruction{ .syntax = "ADC zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, adc, nop, nop, nop } }, // 0x75: ADC zpg,X
    Instruction{ .syntax = "ROR zpg,X", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, ror, data_write_to_addr, nop } }, // 0x76: ROR zpg,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x77:
    Instruction{ .syntax = "SEI impl", .len = 1, .micro_ops = [6]*const MicroOp{ sei, nop, nop, nop, nop, nop } }, // 0x78: SEI impl
    Instruction{ .syntax = "ADC abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, adc, nop, nop, nop } }, // 0x79: ADC abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x7A:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x7B:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x7C:
    Instruction{ .syntax = "ADC abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, adc, nop, nop, nop } }, // 0x7D: ADC abs,X
    Instruction{ .syntax = "ROR abs,X", .len = 6, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, ror, data_write_to_addr } }, // 0x7E: ROR abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x7F:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x80:
    Instruction{ .syntax = "STA X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x81: STA X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x82:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x83:
    Instruction{ .syntax = "STY zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, yr_write_to_addr, nop, nop, nop, nop } }, // 0x84: STY zpg
    Instruction{ .syntax = "STA zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, ac_write_to_addr, nop, nop, nop, nop } }, // 0x85: STA zpg
    Instruction{ .syntax = "STX zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, xr_write_to_addr, nop, nop, nop, nop } }, // 0x86: STX zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x87:
    Instruction{ .syntax = "DEY impl", .len = 1, .micro_ops = [6]*const MicroOp{ dey, nop, nop, nop, nop, nop } }, // 0x88: DEY impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x89:
    Instruction{ .syntax = "TXA impl", .len = 1, .micro_ops = [6]*const MicroOp{ xr_to_ac, nop, nop, nop, nop, nop } }, // 0x8A: TXA impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x8B:
    Instruction{ .syntax = "STY abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, yr_write_to_addr, nop, nop, nop } }, // 0x8C: STY abs
    Instruction{ .syntax = "STA abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, ac_write_to_addr, nop, nop, nop } }, // 0x8D: STA abs
    Instruction{ .syntax = "STX abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, xr_write_to_addr, nop, nop, nop } }, // 0x8E: STX abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x8F:
    Instruction{ .syntax = "BCC rel", .len = 2, .micro_ops = [6]*const MicroOp{ bcc, nop, nop, nop, nop, nop } }, // 0x90: BCC rel
    Instruction{ .syntax = "STA ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x91: STA ind,Y - Need to understand indirect memory access. TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x92:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x93:
    Instruction{ .syntax = "STY zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_yr, yr_write_to_addr, nop, nop, nop } }, // 0x94: STY zpg,X
    Instruction{ .syntax = "STA zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, ac_write_to_addr, nop, nop, nop } }, // 0x95: STA zpg,X
    Instruction{ .syntax = "STX zpg,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_yr, xr_write_to_addr, nop, nop, nop } }, // 0x96: STX zpg,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x97:
    Instruction{ .syntax = "TYA impl", .len = 1, .micro_ops = [6]*const MicroOp{ yr_to_ac, nop, nop, nop, nop, nop } }, // 0x98: TYA impl
    Instruction{ .syntax = "STA abs,Y", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_yr, ac_write_to_addr, nop, nop } }, // 0x99: STA abs,Y
    Instruction{ .syntax = "TXS impl", .len = 1, .micro_ops = [6]*const MicroOp{ xr_to_sp, nop, nop, nop, nop, nop } }, // 0x9A: TXS impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x9B:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x9C:
    Instruction{ .syntax = "STA abs,X", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, ac_write_to_addr, nop, nop } }, // 0x9D: STA abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x9E:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0x9F:
    Instruction{ .syntax = "LDY #", .len = 1, .micro_ops = [6]*const MicroOp{ pc_read_to_yr, nop, nop, nop, nop, nop } }, // 0xA0: LDY #
    Instruction{ .syntax = "LDA X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xA1: LDA X,ind TODO
    Instruction{ .syntax = "LDX #", .len = 1, .micro_ops = [6]*const MicroOp{ pc_read_to_xr, nop, nop, nop, nop, nop } }, // 0xA2: LDX #
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xA3:
    Instruction{ .syntax = "LDY zpg", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_yr, addr_read_to_yr, nop, nop, nop } }, // 0xA4: LDY zpg
    Instruction{ .syntax = "LDA zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_ac, nop, nop, nop, nop } }, // 0xA5: LDA zpg
    Instruction{ .syntax = "LDX zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_xr, nop, nop, nop, nop } }, // 0xA6: LDX zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xA7:
    Instruction{ .syntax = "TAY impl", .len = 1, .micro_ops = [6]*const MicroOp{ ac_to_yr, nop, nop, nop, nop, nop } }, // 0xA8: TAY impl
    Instruction{ .syntax = "LDA #", .len = 1, .micro_ops = [6]*const MicroOp{ pc_read_to_ac, nop, nop, nop, nop, nop } }, // 0xA9: LDA #
    Instruction{ .syntax = "TAX impl", .len = 1, .micro_ops = [6]*const MicroOp{ ac_to_xr, nop, nop, nop, nop, nop } }, // 0xAA: TAX impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xAB:
    Instruction{ .syntax = "LDY abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_yr, nop, nop, nop } }, // 0xAC: LDY abs
    Instruction{ .syntax = "LDA abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_ac, nop, nop, nop } }, // 0xAD: LDA abs
    Instruction{ .syntax = "LDX abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_xr, nop, nop, nop } }, // 0xAE: LDX abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xAF:
    Instruction{ .syntax = "BCS rel", .len = 2, .micro_ops = [6]*const MicroOp{ bcs, nop, nop, nop, nop, nop } }, // 0xB0: BCS rel
    Instruction{ .syntax = "LDA ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xB1: LDA ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xB2:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xB3:
    Instruction{ .syntax = "LDY zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_xr, nop, nop, nop } }, // 0xB4: LDY zpg,X
    Instruction{ .syntax = "LDA zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_ac, nop, nop, nop } }, // 0xB5: LDA zpg,X
    Instruction{ .syntax = "LDX zpg,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_yr, addr_read_to_xr, nop, nop, nop } }, // 0xB6: LDX zpg,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xB7:
    Instruction{ .syntax = "CLV impl", .len = 1, .micro_ops = [6]*const MicroOp{ clv, nop, nop, nop, nop, nop } }, // 0xB8: CLV impl
    Instruction{ .syntax = "LDA abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, addr_read_to_ac, nop, nop, nop } }, // 0xB9: LDA abs,Y
    Instruction{ .syntax = "TSX impl", .len = 1, .micro_ops = [6]*const MicroOp{ sp_to_xr, nop, nop, nop, nop, nop } }, // 0xBA: TSX impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xBB:
    Instruction{ .syntax = "LDY abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, addr_read_to_yr, nop, nop, nop } }, // 0xBC: LDY abs,X
    Instruction{ .syntax = "LDA abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, addr_read_to_ac, nop, nop, nop } }, // 0xBD: LDA abs,X
    Instruction{ .syntax = "LDX abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, addr_read_to_xr, nop, nop, nop } }, // 0xBE: LDX abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xBF:
    Instruction{ .syntax = "CPY #", .len = 1, .micro_ops = [6]*const MicroOp{ cpy_immediate, nop, nop, nop, nop, nop } }, // 0xC0: CPY #
    Instruction{ .syntax = "CMP X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xC1: CMP X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xC2:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xC3:
    Instruction{ .syntax = "CPY zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, cpy, nop, nop, nop, nop } }, // 0xC4: CPY zpg
    Instruction{ .syntax = "CMP zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, cmp, nop, nop, nop, nop } }, // 0xC5: CMP zpg
    Instruction{ .syntax = "DEC zpg", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_data, dec, data_write_to_addr, nop, nop } }, // 0xC6: DEC zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xC7:
    Instruction{ .syntax = "INY impl", .len = 1, .micro_ops = [6]*const MicroOp{ iny, nop, nop, nop, nop, nop } }, // 0xC8: INY impl
    Instruction{ .syntax = "CMP #", .len = 1, .micro_ops = [6]*const MicroOp{ cmp_immediate, nop, nop, nop, nop, nop } }, // 0xC9: CMP #
    Instruction{ .syntax = "DEX impl", .len = 1, .micro_ops = [6]*const MicroOp{ dex, nop, nop, nop, nop, nop } }, // 0xCA: DEX impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xCB:
    Instruction{ .syntax = "CPY abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, cpy, nop, nop, nop } }, // 0xCC: CPY abs
    Instruction{ .syntax = "CMP abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, cmp, nop, nop, nop } }, // 0xCD: CMP abs
    Instruction{ .syntax = "DEC abs", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, dec, data_write_to_addr, nop } }, // 0xCE: DEC abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xCF:
    Instruction{ .syntax = "BNE rel", .len = 2, .micro_ops = [6]*const MicroOp{ bne, nop, nop, nop, nop, nop } }, // 0xD0: BNE rel
    Instruction{ .syntax = "CMP ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xD1: CMP ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xD2:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xD3:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xD4:
    Instruction{ .syntax = "CMP zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, cmp, nop, nop, nop } }, // 0xD5: CMP zpg,X
    Instruction{ .syntax = "DEC zpg,X", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, dec, data_write_to_addr, nop } }, // 0xD6: DEC zpg,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xD7:
    Instruction{ .syntax = "CLD impl", .len = 1, .micro_ops = [6]*const MicroOp{ cld, nop, nop, nop, nop, nop } }, // 0xD8: CLD impl
    Instruction{ .syntax = "CMP abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, cmp, nop, nop, nop } }, // 0xD9: CMP abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xDA:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xDB:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xDC:
    Instruction{ .syntax = "CMP abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, cmp, nop, nop, nop } }, // 0xDD: CMP abs,X
    Instruction{ .syntax = "DEC abs,X", .len = 6, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, dec, data_write_to_addr } }, // 0xDE: DEC abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xDF:
    Instruction{ .syntax = "CPX #", .len = 1, .micro_ops = [6]*const MicroOp{ cpx_immediate, nop, nop, nop, nop, nop } }, // 0xE0: CPX #
    Instruction{ .syntax = "SBC X,ind", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xE1: SBC X,ind TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xE2:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xE3:
    Instruction{ .syntax = "CPX zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, cpx, nop, nop, nop, nop } }, // 0xE4: CPX zpg
    Instruction{ .syntax = "SBC zpg", .len = 2, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, sbc, nop, nop, nop, nop } }, // 0xE5: SBC zpg
    Instruction{ .syntax = "INC zpg", .len = 4, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_read_to_data, inc, data_write_to_addr, nop, nop } }, // 0xE6: INC zpg
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xE7:
    Instruction{ .syntax = "INX impl", .len = 1, .micro_ops = [6]*const MicroOp{ inx, nop, nop, nop, nop, nop } }, // 0xE8: INX impl
    Instruction{ .syntax = "SBC #", .len = 1, .micro_ops = [6]*const MicroOp{ sbc_immediate, nop, nop, nop, nop, nop } }, // 0xE9: SBC #
    Instruction{ .syntax = "NOP impl", .len = 1, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xEA: NOP impl
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xEB:
    Instruction{ .syntax = "CPX abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, cpx, nop, nop, nop } }, // 0xEC: CPX abs
    Instruction{ .syntax = "SBC abs", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, sbc, nop, nop, nop } }, // 0xED: SBC abs
    Instruction{ .syntax = "INC abs", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, inc, data_write_to_addr, nop } }, // 0xEE: INC abs
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xEF:
    Instruction{ .syntax = "BEQ rel", .len = 2, .micro_ops = [6]*const MicroOp{ beq, nop, nop, nop, nop, nop } }, // 0xF0: BEQ rel
    Instruction{ .syntax = "SBC ind,Y", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xF1: SBC ind,Y TODO
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xF2:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xF3:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xF4:
    Instruction{ .syntax = "SBC zpg,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, sbc, nop, nop, nop } }, // 0xF5: SBC zpg,X
    Instruction{ .syntax = "INC zpg,X", .len = 5, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, inc, data_write_to_addr, nop } }, // 0xF6: INC zpg,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xF7:
    Instruction{ .syntax = "SED impl", .len = 1, .micro_ops = [6]*const MicroOp{ sed, nop, nop, nop, nop, nop } }, // 0xF8: SED impl
    Instruction{ .syntax = "SBC abs,Y", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, sbc, nop, nop, nop } }, // 0xF9: SBC abs,Y
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xFA:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xFB:
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xFC:
    Instruction{ .syntax = "SBC abs,X", .len = 3, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, sbc, nop, nop, nop } }, // 0xFD: SBC abs,X
    Instruction{ .syntax = "INC abs,X", .len = 6, .micro_ops = [6]*const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, inc, data_write_to_addr } }, // 0xFE: INC abs,X
    Instruction{ .syntax = "", .len = 0, .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nop } }, // 0xFF:
};

/// Set program counter to reset vector and read first byte
fn nmi_vector_to_pc(mpu: *MPU) MicroOpError!void {
    // Set program counter to reset vector
    mpu.registers.pc = NMI_VECTOR_L;
    mpu.read_pc();
    mpu.addr = mpu.data;
}

/// Set program counter to reset vector and read first byte
fn reset_vector_to_pc(mpu: *MPU) MicroOpError!void {
    // Set program counter to reset vector
    mpu.registers.pc = RESET_VECTOR_L;
    mpu.read_pc();
    mpu.addr = mpu.data;
}

/// Set program counter to reset vector and read first byte
fn irq_vector_to_pc(mpu: *MPU) MicroOpError!void {
    // Set program counter to reset vector
    mpu.registers.pc = IRQ_VECTOR_L;
    mpu.read_pc();
    mpu.addr = mpu.data;
}

/// Write value in accumulator to address in _addr
fn ac_write_to_addr(mpu: *MPU) MicroOpError!void {
    mpu.data = mpu.registers.ac;
    mpu.write(mpu.addr);
}

fn addr_add_xr(mpu: *MPU) MicroOpError!void {
    mpu.addr += mpu.registers.xr;
}

fn addr_add_yr(mpu: *MPU) MicroOpError!void {
    mpu.addr += mpu.registers.yr;
}

// Transfer address to program counter
fn addr_to_pc(mpu: *MPU) MicroOpError!void {
    mpu.registers.pc = mpu.addr;
}

/// Read data at addr into accumulator
fn addr_read_to_ac(mpu: *MPU) MicroOpError!void {
    mpu.read(mpu.addr);
    mpu.registers.ac = mpu.data;
    mpu.registers.sr.update_negative(mpu.data);
    mpu.registers.sr.update_zero(mpu.data);
}

/// Read data at pc into addr
fn addr_read_to_data(mpu: *MPU) MicroOpError!void {
    mpu.read(mpu.addr);
}

/// Read data at addr into x-register
fn addr_read_to_xr(mpu: *MPU) MicroOpError!void {
    mpu.read(mpu.addr);
    mpu.registers.xr = mpu.data;
    mpu.registers.sr.update_negative(mpu.data);
    mpu.registers.sr.update_zero(mpu.data);
}

/// Read data at addr into yr
fn addr_read_to_yr(mpu: *MPU) MicroOpError!void {
    mpu.read(mpu.addr);
    mpu.registers.yr = mpu.data;
    mpu.registers.sr.update_negative(mpu.data);
    mpu.registers.sr.update_zero(mpu.data);
}

/// Bit test (accumulator & memory)
fn bit(mpu: *MPU) MicroOpError!void {
    mpu.read(mpu.addr);
    mpu.registers.sr.zero = (mpu.data & mpu.registers.ac) != 0;
    mpu.registers.sr.negative = (mpu.data & 0x80) != 0; // Bit 7
    mpu.registers.sr.overflow = (mpu.data & 0x40) != 0; // Bit 6
}

/// Write data to addr
fn data_write_to_addr(mpu: *MPU) MicroOpError!void {
    mpu.write(mpu.addr);
}

/// Read value from pc to _addr high byte assign _addr to pc
fn jmp(mpu: *MPU) MicroOpError!void {
    mpu.read(mpu.registers.pc);
    mpu.addr += @as(u16, mpu.data) << 8;
    mpu.registers.pc = mpu.addr;
}

/// Set pc to addr.
fn jsr(mpu: *MPU) MicroOpError!void {
    mpu.registers.pc = mpu.addr;
}

/// Clear interrupt state.
fn rti(mpu: *MPU) MicroOpError!void {
    try cli(mpu);
    mpu.interrupt = false;
}

/// No Instruction
fn nop(_: *MPU) MicroOpError!void {}

/// Read data at pc into accumulator
fn pc_read_to_ac(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    mpu.registers.ac = mpu.data;
}

/// Read data at pc into addr
fn pc_read_to_addr(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    mpu.addr = mpu.data;
}

/// Read data at pc into addr high
fn pc_read_to_addr_h(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    mpu.addr += @as(u16, mpu.data) << 8;
}

/// Read data at pc into x-register
fn pc_read_to_xr(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    mpu.registers.xr = mpu.data;
}

/// Read data at pc into y-register
fn pc_read_to_yr(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    mpu.registers.yr = mpu.data;
}

/// Read data at pc into addr high and index using x-register
fn pc_read_to_addr_h_add_xr(mpu: *MPU) MicroOpError!void {
    try pc_read_to_addr_h(mpu);
    mpu.addr += mpu.registers.xr;
}

fn pc_read_to_addr_h_add_yr(mpu: *MPU) MicroOpError!void {
    try pc_read_to_addr_h(mpu);
    mpu.addr += mpu.registers.yr;
}

/// Write value in x-register to address in _addr
fn xr_write_to_addr(mpu: *MPU) MicroOpError!void {
    mpu.data = mpu.registers.xr;
    mpu.write(mpu.addr);
}

/// Write value in y-register to address in _addr
fn yr_write_to_addr(mpu: *MPU) MicroOpError!void {
    mpu.data = mpu.registers.yr;
    mpu.write(mpu.addr);
}
