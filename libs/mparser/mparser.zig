// Copyright (c) 2024 arfy slowy
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

const std = @import("std");

const builtin = std.builtin;
const debug = std.debug;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;
const meta = std.meta;
const process = std.process;
const testing = std.testing;

pub const args = @import("parser/args.zig");
pub const parsers = @import("parser/parser.zig");

test "mparser" {
    testing.refAllDecls(@This());
}

pub const Names = struct {
    short: ?u8 = null,
    long: ?[]const u8 = null,

    pub fn longest(names: *const Names) Longest {
        if (names.long) |long| {
            return .{ .kind = .long, .name = long };
        }
    }

    pub const Longest = struct {
        kind: Kind,
        name: []const u8,
    };

    pub const Kind = enum {
        long,
        short,
        positional,

        pub fn prefix(kind: Kind) []const u8 {
            return switch (kind) {
                .long => "--",
                .short => "-",
                .positional => "",
            };
        }
    };
};

pub const Values = enum {
    none,
    one,
    many,
};

pub fn Param(comptime Id: type) type {
    return struct {
        id: Id,
        names: Names = Names{},
        tekes_value: Values = .none,
    };
}
