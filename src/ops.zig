const mpu_core = @import("mpu.zig");
const MPU = mpu_core.MPU;
const Operation = mpu_core.Operation;
const MicroOp = mpu_core.MicroOp;

/// Non-maskable interrupt vector
const NMI_VECTOR_L: u16 = 0xFFFA;
const NMI_VECTOR_H: u16 = 0xFFFB;
/// Reset vector
const RESET_VECTOR_L: u16 = 0xFFFC;
const RESET_VECTOR_H: u16 = 0xFFFD;
/// Interrupt vector
const IRQ_VECTOR_L: u16 = 0xFFFE;
const IRQ_VECTOR_H: u16 = 0xFFFF;

pub const NMI_OPERATION: Operation = Operation{
    .len = 6,
    .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, nmi_vector_to_pc },
    .syntax = "NMI",
};
pub const RESET_OPERATION: Operation = Operation{
    .len = 6,
    .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, reset_vector_to_pc },
    .syntax = "Reset",
};
pub const IRQ_OPERATION: Operation = Operation{
    .len = 6,
    .micro_ops = [6]*const MicroOp{ nop, nop, nop, nop, nop, irq_vector_to_pc },
    .syntax = "IRQ",
};

pub const OPERATIONS = [_]Operation{
    Operation{ .syntax = "BRK impl", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                       // 0x00: BRK impl
    Operation{ .syntax = "ORA X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x01: ORA X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x02:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x03:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x04:
    Operation{ .syntax = "ORA zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, ora, nop, nop, nop, nop } },                                                            // 0x05: ORA zpg
    Operation{ .syntax = "ASL zpg", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_data, asl_data, data_write_to_addr, nop, nop } },                          // 0x06: ASL zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x07:
    Operation{ .syntax = "PHP impl", .len = 2, .micro_ops = [6]* const MicroOp{ inc_sp, push_sr, nop, nop, nop, nop } },                                                                // 0x08: PHP impl
    Operation{ .syntax = "ORA #", .len = 1, .micro_ops = [6]* const MicroOp{ ora_ac, nop, nop, nop, nop, nop } },                                                                       // 0x09: ORA #
    Operation{ .syntax = "ASL A", .len = 1, .micro_ops = [6]* const MicroOp{ asl_a, nop, nop, nop, nop, nop } },                                                                        // 0x0A: ASL A
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x0B:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x0C:
    Operation{ .syntax = "ORA abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, ora, nop, nop, nop } },                                              // 0x0D: ORA abs
    Operation{ .syntax = "ASL abs", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, asl_data, data_write_to_addr, nop } },            // 0x0E: ASL abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x0F:
    Operation{ .syntax = "BPL rel", .len = 1, .micro_ops = [6]* const MicroOp{ bpl, nop, nop, nop, nop, nop } },                                                                        // 0x10: BPL rel
    Operation{ .syntax = "ORA ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x11: ORA ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x12:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x13:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x14:
    Operation{ .syntax = "ORA zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, ora, nop, nop, nop } },                                                  // 0x15: ORA zpg,X
    Operation{ .syntax = "ASL zpg,X", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, asl_data, data_write_to_addr, nop } },                // 0x16: ASL zpg,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x17:
    Operation{ .syntax = "CLC impl", .len = 1, .micro_ops = [6]* const MicroOp{ clc, nop, nop, nop, nop, nop } },                                                                       // 0x18: CLC impl
    Operation{ .syntax = "ORA abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, ora, nop, nop, nop } },                                     // 0x19: ORA abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x1A:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x1B:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x1C:
    Operation{ .syntax = "ORA abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, ora, nop, nop, nop } },                                     // 0x1D: ORA abs,X
    Operation{ .syntax = "ASL abs,X", .len = 6, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, asl_data, addr_read_to_data } },   // 0x1E: ASL abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x1F:
    Operation{ .syntax = "JSR abs", .len = 5, .micro_ops = [6]* const MicroOp{ push_pc_l, push_pc_h, pc_read_to_addr, pc_read_to_addr_h, jsr, nop } },                                  // 0x20: JSR abs
    Operation{ .syntax = "AND X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x21: AND X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x22:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x23:
    Operation{ .syntax = "BIT zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, bit, nop, nop, nop, nop } },                                                            // 0x24: BIT zpg
    Operation{ .syntax = "AND zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, and_data, nop, nop, nop, nop } },                                                       // 0x25: AND zpg
    Operation{ .syntax = "ROL zpg", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_data, rol_data, data_write_to_addr, nop, nop } },                          // 0x26: ROL zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x27:
    Operation{ .syntax = "PLP impl", .len = 2, .micro_ops = [6]* const MicroOp{ pull_sr, dec_sp, nop, nop, nop, nop } },                                                                // 0x28: PLP impl
    Operation{ .syntax = "AND #", .len = 1, .micro_ops = [6]* const MicroOp{ and_ac, nop, nop, nop, nop, nop } },                                                                       // 0x29: AND #
    Operation{ .syntax = "ROL A", .len = 1, .micro_ops = [6]* const MicroOp{ rol_ac, nop, nop, nop, nop, nop } },                                                                       // 0x2A: ROL A
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x2B:
    Operation{ .syntax = "BIT abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, bit, nop, nop, nop } },                                              // 0x2C: BIT abs
    Operation{ .syntax = "AND abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, and_data, nop, nop, nop } },                                         // 0x2D: AND abs
    Operation{ .syntax = "ROL abs", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, rol_data, data_write_to_addr, nop } },            // 0x2E: ROL abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x2F:
    Operation{ .syntax = "BMI rel", .len = 1, .micro_ops = [6]* const MicroOp{ bmi, nop, nop, nop, nop, nop } },                                                                        // 0x30: BMI rel
    Operation{ .syntax = "AND ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x31: AND ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x32:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x33:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x34:
    Operation{ .syntax = "AND zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, and_data, nop, nop, nop } },                                             // 0x35: AND zpg,X
    Operation{ .syntax = "ROL zpg,X", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, rol_data, data_write_to_addr, nop } },                // 0x36: ROL zpg,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x37:
    Operation{ .syntax = "SEC impl", .len = 1, .micro_ops = [6]* const MicroOp{ sec, nop, nop, nop, nop, nop } },                                                                       // 0x38: SEC impl
    Operation{ .syntax = "AND abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, and_data, nop, nop, nop } },                                // 0x39: AND abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x3A:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x3B:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x3C:
    Operation{ .syntax = "AND abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, and_data, nop, nop, nop } },                                // 0x3D: AND abs,X
    Operation{ .syntax = "ROL abs,X", .len = 6, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, rol_data, data_write_to_addr } },  // 0x3E: ROL abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x3F:
    Operation{ .syntax = "RTI impl", .len = 5, .micro_ops = [6]* const MicroOp{ pull_sr, dec_sp, pull_pc_l, pull_pc_h, jmp, nop } },                                                    // 0x40: RTI impl
    Operation{ .syntax = "EOR X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x41: EOR X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x42:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x43:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x44:
    Operation{ .syntax = "EOR zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, eor_data, nop, nop, nop, nop } },                                                       // 0x45: EOR zpg
    Operation{ .syntax = "LSR zpg", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_data, lsr_data, data_write_to_addr, nop, nop } },                          // 0x46: LSR zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x47:
    Operation{ .syntax = "PHA impl", .len = 2, .micro_ops = [6]* const MicroOp{ inc_sp, push_ac, nop, nop, nop, nop } },                                                                // 0x48: PHA impl
    Operation{ .syntax = "EOR #", .len = 1, .micro_ops = [6]* const MicroOp{ eor_ac, nop, nop, nop, nop, nop } },                                                                       // 0x49: EOR #
    Operation{ .syntax = "LSR A", .len = 1, .micro_ops = [6]* const MicroOp{ lsr_ac, nop, nop, nop, nop, nop } },                                                                       // 0x4A: LSR A
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x4B:
    Operation{ .syntax = "JMP abs", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, jmp, nop, nop, nop, nop } },                                                            // 0x4C: JMP abs
    Operation{ .syntax = "EOR abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, eor_data, nop, nop, nop } },                                         // 0x4D: EOR abs
    Operation{ .syntax = "LSR abs", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, lsr_data, data_write_to_addr, nop } },            // 0x4E: LSR abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x4F:
    Operation{ .syntax = "BVC rel", .len = 1, .micro_ops = [6]* const MicroOp{ bvc, nop, nop, nop, nop, nop } },                                                                        // 0x50: BVC rel
    Operation{ .syntax = "EOR ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x51: EOR ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x52:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x53:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x54:
    Operation{ .syntax = "EOR zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, eor_data, nop, nop, nop } },                                             // 0x55: EOR zpg,X
    Operation{ .syntax = "LSR zpg,X", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, lsr_data, data_write_to_addr, nop } },                // 0x56: LSR zpg,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x57:
    Operation{ .syntax = "CLI impl", .len = 1, .micro_ops = [6]* const MicroOp{ cli, nop, nop, nop, nop, nop } },                                                                       // 0x58: CLI impl
    Operation{ .syntax = "EOR abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, eor_data, nop, nop, nop } },                                // 0x59: EOR abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x5A:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x5B:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x5C:
    Operation{ .syntax = "EOR abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, eor_data, nop, nop, nop } },                                // 0x5D: EOR abs,X
    Operation{ .syntax = "LSR abs,X", .len = 6, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, lsr_data, data_write_to_addr } },  // 0x5E: LSR abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x5F:
    Operation{ .syntax = "RTS impl", .len = 3, .micro_ops = [6]* const MicroOp{ pull_pc_l, pull_pc_h, jmp, nop, nop, nop } },                                                           // 0x60: RTS impl
    Operation{ .syntax = "ADC X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x61: ADC X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x62:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x63:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x64:
    Operation{ .syntax = "ADC zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, adc, nop, nop, nop, nop } },                                                            // 0x65: ADC zpg
    Operation{ .syntax = "ROR zpg", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_data, ror_data, data_write_to_addr, nop, nop } },                          // 0x66: ROR zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x67:
    Operation{ .syntax = "PLA impl", .len = 2, .micro_ops = [6]* const MicroOp{ pull_ac, dec_sp, nop, nop, nop, nop } },                                                                // 0x68: PLA impl
    Operation{ .syntax = "ADC #", .len = 1, .micro_ops = [6]* const MicroOp{ adc_immediate, nop, nop, nop, nop, nop } },                                                                // 0x69: ADC #
    Operation{ .syntax = "ROR A", .len = 1, .micro_ops = [6]* const MicroOp{ ror_ac, nop, nop, nop, nop, nop } },                                                                       // 0x6A: ROR A
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x6B:
    Operation{ .syntax = "JMP ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                        // 0x6C: JMP ind
    Operation{ .syntax = "ADC abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, adc, nop, nop, nop } },                                              // 0x6D: ADC abs
    Operation{ .syntax = "ROR abs", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, ror_data, data_write_to_addr, nop } },            // 0x6E: ROR abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x6F:
    Operation{ .syntax = "BVS rel", .len = 1, .micro_ops = [6]* const MicroOp{ bvs, nop, nop, nop, nop, nop } },                                                                        // 0x70: BVS rel
    Operation{ .syntax = "ADC ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x71: ADC ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x72:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x73:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x74:
    Operation{ .syntax = "ADC zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, adc, nop, nop, nop } },                                                  // 0x75: ADC zpg,X
    Operation{ .syntax = "ROR zpg,X", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, ror_data, data_write_to_addr, nop } },                // 0x76: ROR zpg,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x77:
    Operation{ .syntax = "SEI impl", .len = 1, .micro_ops = [6]* const MicroOp{ sei, nop, nop, nop, nop, nop } },                                                                       // 0x78: SEI impl
    Operation{ .syntax = "ADC abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, adc, nop, nop, nop } },                                     // 0x79: ADC abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x7A:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x7B:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x7C:
    Operation{ .syntax = "ADC abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, adc, nop, nop, nop } },                                     // 0x7D: ADC abs,X
    Operation{ .syntax = "ROR abs,X", .len = 6, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, ror_data, data_write_to_addr } },  // 0x7E: ROR abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x7F:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x80:
    Operation{ .syntax = "STA X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x81: STA X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x82:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x83:
    Operation{ .syntax = "STY zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, yr_write_to_addr, nop, nop, nop, nop } },                                               // 0x84: STY zpg
    Operation{ .syntax = "STA zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, ac_write_to_addr, nop, nop, nop, nop } },                                               // 0x85: STA zpg
    Operation{ .syntax = "STX zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, xr_write_to_addr, nop, nop, nop, nop } },                                               // 0x86: STX zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x87:
    Operation{ .syntax = "DEY impl", .len = 1, .micro_ops = [6]* const MicroOp{ dey, nop, nop, nop, nop, nop } },                                                                       // 0x88: DEY impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x89:
    Operation{ .syntax = "TXA impl", .len = 1, .micro_ops = [6]* const MicroOp{ xr_to_ac, nop, nop, nop, nop, nop } },                                                                  // 0x8A: TXA impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x8B:
    Operation{ .syntax = "STY abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, yr_write_to_addr, nop, nop, nop } },                                 // 0x8C: STY abs
    Operation{ .syntax = "STA abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, ac_write_to_addr, nop, nop, nop } },                                 // 0x8D: STA abs
    Operation{ .syntax = "STX abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, xr_write_to_addr, nop, nop, nop } },                                 // 0x8E: STX abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x8F:
    Operation{ .syntax = "BCC rel", .len = 1, .micro_ops = [6]* const MicroOp{ bcc, nop, nop, nop, nop, nop } },                                                                        // 0x90: BCC rel
    Operation{ .syntax = "STA ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0x91: STA ind,Y - Need to understand indirect memory access.
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x92:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x93:
    Operation{ .syntax = "STY zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_yr, yr_write_to_addr, nop, nop, nop } },                                     // 0x94: STY zpg,X
    Operation{ .syntax = "STA zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, ac_write_to_addr, nop, nop, nop } },                                     // 0x95: STA zpg,X
    Operation{ .syntax = "STX zpg,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_yr, xr_write_to_addr, nop, nop, nop } },                                     // 0x96: STX zpg,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x97:
    Operation{ .syntax = "TYA impl", .len = 1, .micro_ops = [6]* const MicroOp{ yr_to_ac, nop, nop, nop, nop, nop } },                                                                  // 0x98: TYA impl
    Operation{ .syntax = "STA abs,Y", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_yr, ac_write_to_addr, nop, nop } },                       // 0x99: STA abs,Y
    Operation{ .syntax = "TXS impl", .len = 1, .micro_ops = [6]* const MicroOp{ xr_to_sp, nop, nop, nop, nop, nop } },                                                                  // 0x9A: TXS impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x9B:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x9C:
    Operation{ .syntax = "STA abs,X", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, ac_write_to_addr, nop, nop } },                       // 0x9D: STA abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x9E:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0x9F:
    Operation{ .syntax = "LDY #", .len = 1, .micro_ops = [6]* const MicroOp{ pc_read_to_yr, nop, nop, nop, nop, nop } },                                                                // 0xA0: LDY #
    Operation{ .syntax = "LDA X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0xA1: LDA X,ind
    Operation{ .syntax = "LDX #", .len = 1, .micro_ops = [6]* const MicroOp{ pc_read_to_xr, nop, nop, nop, nop, nop } },                                                                // 0xA2: LDX #
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xA3:
    Operation{ .syntax = "LDY zpg", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_yr, addr_read_to_yr, nop, nop, nop } },                                    // 0xA4: LDY zpg
    Operation{ .syntax = "LDA zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, lda, nop, nop, nop, nop } },                                                            // 0xA5: LDA zpg
    Operation{ .syntax = "LDX zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_xr, nop, nop, nop, nop } },                                                // 0xA6: LDX zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xA7:
    Operation{ .syntax = "TAY impl", .len = 1, .micro_ops = [6]* const MicroOp{ ac_to_yr, nop, nop, nop, nop, nop } },                                                                  // 0xA8: TAY impl
    Operation{ .syntax = "LDA #", .len = 1, .micro_ops = [6]* const MicroOp{ pc_read_to_ac, nop, nop, nop, nop, nop } },                                                                // 0xA9: LDA #
    Operation{ .syntax = "TAX impl", .len = 1, .micro_ops = [6]* const MicroOp{ ac_to_xr, nop, nop, nop, nop, nop } },                                                                  // 0xAA: TAX impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xAB:
    Operation{ .syntax = "LDY abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_yr, nop, nop, nop } },                                  // 0xAC: LDY abs
    Operation{ .syntax = "LDA abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_ac, nop, nop, nop } },                                  // 0xAD: LDA abs
    Operation{ .syntax = "LDX abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_xr, nop, nop, nop } },                                  // 0xAE: LDX abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xAF:
    Operation{ .syntax = "BCS rel", .len = 1, .micro_ops = [6]* const MicroOp{ bcs, nop, nop, nop, nop, nop } },                                                                        // 0xB0: BCS rel
    Operation{ .syntax = "LDA ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0xB1: LDA ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xB2:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xB3:
    Operation{ .syntax = "LDY zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_xr, nop, nop, nop } },                                      // 0xB4: LDY zpg,X
    Operation{ .syntax = "LDA zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_ac, nop, nop, nop } },                                      // 0xB5: LDA zpg,X
    Operation{ .syntax = "LDX zpg,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_yr, addr_read_to_xr, nop, nop, nop } },                                      // 0xB6: LDX zpg,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xB7:
    Operation{ .syntax = "CLV impl", .len = 1, .micro_ops = [6]* const MicroOp{ clv, nop, nop, nop, nop, nop } },                                                                       // 0xB8: CLV impl
    Operation{ .syntax = "LDA abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, addr_read_to_ac, nop, nop, nop } },                         // 0xB9: LDA abs,Y
    Operation{ .syntax = "TSX impl", .len = 1, .micro_ops = [6]* const MicroOp{ sp_to_xr, nop, nop, nop, nop, nop } },                                                                  // 0xBA: TSX impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xBB:
    Operation{ .syntax = "LDY abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, addr_read_to_yr, nop, nop, nop } },                         // 0xBC: LDY abs,X
    Operation{ .syntax = "LDA abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, addr_read_to_ac, nop, nop, nop } },                         // 0xBD: LDA abs,X
    Operation{ .syntax = "LDX abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, addr_read_to_xr, nop, nop, nop } },                         // 0xBE: LDX abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xBF:
    Operation{ .syntax = "CPY #", .len = 1, .micro_ops = [6]* const MicroOp{ cpy_ac, nop, nop, nop, nop, nop } },                                                                       // 0xC0: CPY #
    Operation{ .syntax = "CMP X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0xC1: CMP X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xC2:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xC3:
    Operation{ .syntax = "CPY zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, cpy_data, nop, nop, nop, nop } },                                                       // 0xC4: CPY zpg
    Operation{ .syntax = "CMP zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, cmp_data, nop, nop, nop, nop } },                                                       // 0xC5: CMP zpg
    Operation{ .syntax = "DEC zpg", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_data, dec_data, data_write_to_addr, nop, nop } },                          // 0xC6: DEC zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xC7:
    Operation{ .syntax = "INY impl", .len = 1, .micro_ops = [6]* const MicroOp{ iny, nop, nop, nop, nop, nop } },                                                                       // 0xC8: INY impl
    Operation{ .syntax = "CMP #", .len = 1, .micro_ops = [6]* const MicroOp{ cmp_ac, nop, nop, nop, nop, nop } },                                                                       // 0xC9: CMP #
    Operation{ .syntax = "DEX impl", .len = 1, .micro_ops = [6]* const MicroOp{ dex, nop, nop, nop, nop, nop } },                                                                       // 0xCA: DEX impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xCB:
    Operation{ .syntax = "CPY abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, cpy_data, nop, nop, nop } },                                         // 0xCC: CPY abs
    Operation{ .syntax = "CMP abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, cmp_data, nop, nop, nop } },                                         // 0xCD: CMP abs
    Operation{ .syntax = "DEC abs", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, dec_data, data_write_to_addr, nop } },            // 0xCE: DEC abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xCF:
    Operation{ .syntax = "BNE rel", .len = 1, .micro_ops = [6]* const MicroOp{ bne, nop, nop, nop, nop, nop } },                                                                        // 0xD0: BNE rel
    Operation{ .syntax = "CMP ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0xD1: CMP ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xD2:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xD3:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xD4:
    Operation{ .syntax = "CMP zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, cmp_data, nop, nop, nop } },                                             // 0xD5: CMP zpg,X
    Operation{ .syntax = "DEC zpg,X", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, dec_data, data_write_to_addr, nop } },                // 0xD6: DEC zpg,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xD7:
    Operation{ .syntax = "CLD impl", .len = 1, .micro_ops = [6]* const MicroOp{ cld, nop, nop, nop, nop, nop } },                                                                       // 0xD8: CLD impl
    Operation{ .syntax = "CMP abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, cmp_data, nop, nop, nop } },                                // 0xD9: CMP abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xDA:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xDB:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xDC:
    Operation{ .syntax = "CMP abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, cmp_data, nop, nop, nop } },                                // 0xDD: CMP abs,X
    Operation{ .syntax = "DEC abs,X", .len = 6, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, dec_data, data_write_to_addr } },  // 0xDE: DEC abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xDF:
    Operation{ .syntax = "CPX #", .len = 1, .micro_ops = [6]* const MicroOp{ cpx_ac, nop, nop, nop, nop, nop } },                                                                       // 0xE0: CPX #
    Operation{ .syntax = "SBC X,ind", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0xE1: SBC X,ind
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xE2:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xE3:
    Operation{ .syntax = "CPX zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, cpx_data, nop, nop, nop, nop } },                                                       // 0xE4: CPX zpg
    Operation{ .syntax = "SBC zpg", .len = 2, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, sbc, nop, nop, nop, nop } },                                                            // 0xE5: SBC zpg
    Operation{ .syntax = "INC zpg", .len = 4, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_read_to_data, abs_data, data_write_to_addr, nop, nop } },                          // 0xE6: INC zpg
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xE7:
    Operation{ .syntax = "INX impl", .len = 1, .micro_ops = [6]* const MicroOp{ inx, nop, nop, nop, nop, nop } },                                                                       // 0xE8: INX impl
    Operation{ .syntax = "SBC #", .len = 1, .micro_ops = [6]* const MicroOp{ sbc_immediate, nop, nop, nop, nop, nop } },                                                                // 0xE9: SBC #
    Operation{ .syntax = "NOP impl", .len = 1, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                       // 0xEA: NOP impl
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xEB:
    Operation{ .syntax = "CPX abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, cpx_data, nop, nop, nop } },                                         // 0xEC: CPX abs
    Operation{ .syntax = "SBC abs", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, sbc, nop, nop, nop } },                                              // 0xED: SBC abs
    Operation{ .syntax = "INC abs", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_read_to_data, abs_data, data_write_to_addr, nop } },            // 0xEE: INC abs
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xEF:
    Operation{ .syntax = "BEQ rel", .len = 1, .micro_ops = [6]* const MicroOp{ beq, nop, nop, nop, nop, nop } },                                                                        // 0xF0: BEQ rel
    Operation{ .syntax = "SBC ind,Y", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                      // 0xF1: SBC ind,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xF2:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xF3:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xF4:
    Operation{ .syntax = "SBC zpg,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, sbc, nop, nop, nop } },                                                  // 0xF5: SBC zpg,X
    Operation{ .syntax = "INC zpg,X", .len = 5, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, addr_add_xr, addr_read_to_data, abs_data, data_write_to_addr, nop } },                // 0xF6: INC zpg,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xF7:
    Operation{ .syntax = "SED impl", .len = 1, .micro_ops = [6]* const MicroOp{ sed, nop, nop, nop, nop, nop } },                                                                       // 0xF8: SED impl
    Operation{ .syntax = "SBC abs,Y", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_yr, sbc, nop, nop, nop } },                                     // 0xF9: SBC abs,Y
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xFA:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xFB:
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xFC:
    Operation{ .syntax = "SBC abs,X", .len = 3, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h_add_xr, sbc, nop, nop, nop } },                                     // 0xFD: SBC abs,X
    Operation{ .syntax = "INC abs,X", .len = 6, .micro_ops = [6]* const MicroOp{ pc_read_to_addr, pc_read_to_addr_h, addr_add_xr, addr_read_to_data, abs_data, data_write_to_addr } },  // 0xFE: INC abs,X
    Operation{ .syntax = "", .len = 0, .micro_ops = [6]* const MicroOp{ nop, nop, nop, nop, nop, nop } },                                                                               // 0xFF:
};

/// Set program counter to reset vector
fn nmi_vector_to_pc(mpu: *MPU) void {
    // Set program counter to reset vector
    mpu.registers.pc = NMI_VECTOR_L;
}

/// Set program counter to reset vector
fn reset_vector_to_pc(mpu: *MPU) void {
    // Set program counter to reset vector
    mpu.registers.pc = RESET_VECTOR_L;
}

/// Set program counter to reset vector
fn irq_vector_to_pc(mpu: *MPU) void {
    // Set program counter to reset vector
    mpu.registers.pc = IRQ_VECTOR_L;
}

fn nop(_: *MPU) void {}

fn pc_read_to_addr(mpu: *MPU) void {
    // Read data at pc into addr
    mpu.read_pc();
    mpu._addr = mpu._data;
}

fn pc_read_to_addr_h(mpu: *MPU) void {
    // Read data at pc into addr high
    mpu.read_pc();
    mpu._addr += @as(u16, mpu._data) << 8;
}
