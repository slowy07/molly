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
        takes_value: Values = .none,
    };
}

pub fn parseParams(allocator: mem.Allocator, str: []const u8) ![]Param(Help) {
    var end: usize = undefined;
    return parseParamsEx(allocator, str, &end);
}

pub fn parseParamsEx(allocator: mem.Allocator, str: []const u8, end: *usize) ![]Param(Help) {
    var list = std.ArrayList(Param(Help)).init(allocator);
    errdefer list.deinit();
    try parseParamsIntoArrayListEx(&list, str, end);
    return try list.toOwnedSlice();
}

pub fn parseParamsComptime(comptime str: []const u8) [countParams(str)]Param(Help) {
    var end: usize = undefined;
    var res: [countParams(str)]Param(Help) = undefined;
    _ = parseParamsIntoSliceEx(&res, str, &end) catch {
        const loc = std.zig.findLineColumn(str, end);
        @compileError(std.fmt.comptimePrint("error:{}:{}: failed to parse parameter:\n{}", .{
            loc.line + 1,
            loc.column + 1,
            loc.source_line,
        }));
    };
    return res;
}

fn countParams(str: []const u8) usize {
    @setEvalBranchQuota(std.math.maxInt(u32));

    var res: usize = 0;
    var it = mem.split(u8, str, "\n");
    while (it.next()) |line| {
        const trimmed = mem.trimLeft(u8, line, " \t");
        if (mem.startsWith(u8, trimmed, "-") or mem.startsWith(u8, trimmed, "<")) {
            res += 1;
        }
    }
    return res;
}

pub fn parseParamsIntoSlice(slice: []Param(Help), str: []const u8) ![]Param(Help) {
    var null_alloc = heap.FixedBufferAllocator.init("");
    var list = std.ArrayList(Param(Help)){
        .allocator = null_alloc.allocator(),
        .items = slice[0..0],
        .capacity = slice.len,
    };

    try parseParamsIntoArrayList(&list, str);
    return list.items;
}

pub fn parseParamsIntoSliceEx(slice: []Param(Help), str: []const u8, end: *usize) ![]Param(Help) {
    var null_alloc = heap.FixedBufferAllocator.init("");
    var list = std.ArrayList(Param(Help)){
        .allocator = null_alloc.allocator(),
        .items = slice[0..0],
        .capacity = slice.len,
    };
    try parseParamsIntoArrayListEx(&list, str, end);
    return list.items;
}

pub fn parseParamsIntoArrayList(list: *std.ArrayList(Param(Help)), str: []const u8) !void {
    var end: usize = undefined;
    return parseParamsIntoArrayListEx(list, str, &end);
}

pub fn parseParamsIntoArrayListEx(list: *std.ArrayList(Param(Help)), str: []const u8, end: *usize) !void {
    var i: usize = 0;
    while (i != str.len) {
        var end_of_this: usize = undefined;
        errdefer end.* = i + end_of_this;
        try list.append(try parseParamsEx(str[i..], &end_of_this));
        i += end_of_this;
    }
    end.* = str.len;
}

pub const Help = struct {
    desc: []const u8 = "",
    val: []const u8 = "",

    pub fn description(h: Help) []const u8 {
        return h.desc;
    }

    pub fn value(h: Help) []const u8 {
        return h.val;
    }
};
