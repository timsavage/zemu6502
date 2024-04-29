const std = @import("std");

/// Calculate the checksum of the buffer.
pub inline fn modulo256Sum(buffer: []const u8) u8 {
    var sum: u8 = 0;
    for (buffer) |c| {
        sum = @addWithOverflow(sum, c).@"0";
    }
    return sum;
}

test "modulo256Sum of $qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+;memory-tagging+;xmlRegisters=i386#77" {
    const actual = modulo256Sum("qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+;memory-tagging+;xmlRegisters=i386");

    try std.testing.expectEqual(0x77, actual);
}

/// Convert a u8 into hex, clone of std.fmt.digits2
pub fn hexDigits(value: u8) [2]u8 {
    return ("000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F" ++
        "202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F" ++
        "404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F" ++
        "606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F" ++
        "808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F" ++
        "A0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF" ++
        "C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF" ++
        "E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF")[value * 2 ..][0..2].*;
}

test "hexDigits" {
    const value = hexDigits(0x5D);

    try std.testing.expectEqualStrings("5D", &value);
}
