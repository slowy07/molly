const std = @import("std");
const cpp = @import("cpp");
const mem = std.mem;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "cpp_nested_struct" {
    const fii = @import("test_nested_struct_cpp.zig");
    const zig_size_struct = @as(c_int, @sizeOf(fii.RootStruct));
    const cpp_size_struct = fii.test_sizeof_RootStruct();
    try expectEqual(zig_size_struct, cpp_size_struct);

    const zig_size_union = @as(c_int, @sizeOf(fii.RootUnion));
    const cpp_size_union = fii.test_sizeof_RootUnion();
    try expectEqual(zig_size_union, cpp_size_union);
}
