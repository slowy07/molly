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

const builtin = @import("builtin");
const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const mem = std.mem;
const process = std.process;
const testing = std.testing;

pub const ExampleArgIterator = struct {
    pub fn next(iter: *ExampleArgIterator) ?[]const u8 {
        _ = iter;
        return "2";
    }
};

pub const SliceIterator = struct {
    args: []const []const u8,
    index: usize = 0,

    pub fn next(iter: *SliceIterator) ?[]const u8 {
        if (iter.args.len <= iter.index) {
            return null;
        }
        defer iter.index += 1;
        return iter.args[iter.index];
    }
};

test "SliceIterator" {
    const args = [_][]const u8{ "A", "BB", "CCC" };
    var iter = SliceIterator{ .args = &args };
    for (args) |a| {
        try testing.expectEqualStrings(a, iter.next().?);
    }
    try testing.expectEqual(@as(?[]const u8, null), iter.next());
}
