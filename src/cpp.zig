// Copyright (c) 2023 arfy slowy
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
const builtin = @import("builtin");

pub fn targetSwitch(
    comptime T: type,
    comptime lookup: anytype,
) T {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const tuple = builtin.target.linuxTriple(fba.allocator()) catch unreachable;
    for (lookup) |entry| {
        if (std.mem.eql(u8, entry[0], tuple)) {
            return entry[1];
        }
    }

    @compileError("target `" ++ tuple ++ "` not listed");
}
pub fn FlagsMixin(comptime FlagsType: type) type {
    return struct {
        pub const IntType = @typeInfo(FlagsType).Struct.fields[0].type;
        pub inline fn init(flags: IntType) FlagsType {
            return .{ .bits = flags };
        }
        pub inline fn merge(lhs: FlagsType, rhs: FlagsType) FlagsType {
            return init(lhs.bits | rhs.bits);
        }
        pub inline fn intersect(lhs: FlagsType, rhs: FlagsType) FlagsType {
            return init(lhs.bits & rhs.bits);
        }
        pub inline fn complement(self: FlagsType) FlagsType {
            return init(~self.bits);
        }
        pub inline fn subtract(lhs: FlagsType, rhs: FlagsType) FlagsType {
            return init(lhs.bits & rhs.complement().bits);
        }
        pub inline fn contains(lhs: FlagsType, rhs: FlagsType) bool {
            return intersect(lhs, rhs).bits == rhs.bits;
        }
    };
}

extern fn memset(ptr: *anyopaque, value: c_int, num: usize) *anyopaque;
extern fn memcpy(destination: *anyopaque, source: *const anyopaque, num: usize) *anyopaque;
extern fn memmove(destination: *anyopaque, source: *const anyopaque, num: usize) *anyopaque;
extern fn strcmp(str1: *const c_char, str2: *const c_char) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn free(ptr: ?*anyopaque) void;

pub fn Allocator(comptime T: type) type {
    return extern struct {
        const Self = @This();

        pub fn allocate(self: *Self, size: usize) !*T {
            _ = self;
            if (@as(?*T, @ptrCast(malloc(@sizeOf(T) * size)))) |ptr| {
                return ptr;
            } else {
                return std.mem.Allocator.Error.OutOfMemory;
            }
        }

        pub fn deallocate(self: *Self, ptr: *T, size: usize) void {
            _ = self;
            _ = size;
            free(ptr);
        }
    };
}

pub const native = switch (builtin.abi) {
    .msvc => msvc,
    else => gnu,
};

pub const msvc = struct {
    const Container =
        if (builtin.mode == .Debug)
        extern struct {
            const Self = @This();

            const Iter = extern struct {
                proxy: ?*const ContainerProxy = null,
                next: ?*Iter = null,
            };

            const ContainerProxy = extern struct {
                cont: ?*const Self = null,
                iter: ?*Iter = null,
            };

            proxy: ?*ContainerProxy,

            pub fn init() Self {
                const proxy = @as(?*ContainerProxy, @ptrCast(@alignCast(malloc(@sizeOf(ContainerProxy)))));
                proxy.?.* = .{};
                return .{ .proxy = proxy };
            }

            pub fn deinit(self: *Self) void {
                _ = self;
            }
        }
    else
        extern struct {
            const Self = @This();

            pub fn init() Self {
                return .{};
            }
            pub fn deinit(_: *Self) void {}
        };

    pub fn Vector(comptime T: type) type {
        return msvc.VectorRaw(T, Allocator(T));
    }
    pub fn VectorRaw(comptime T: type, comptime Alloc: type) type {
        return extern struct {
            const Self = @This();

            __proxy: Container,
            allocator: Alloc,
            head: ?*T = null,
            tail: ?*T = null,
            limit: ?*T = null,

            pub fn init(allocator: Alloc) Self {
                return .{
                    .__proxy = Container.init(),
                    .allocator = allocator,
                };
            }

            pub inline fn size(self: *const Self) usize {
                return (@intFromPtr(self.tail) - @intFromPtr(self.head));
            }

            pub inline fn capacity(self: *const Self) usize {
                return (@intFromPtr(self.limit) - @intFromPtr(self.head));
            }

            pub inline fn values(self: Self) []T {
                return if (self.head) |head| @as([*]T, @ptrCast(head))[0..self.size()] else &[_]T{};
            }

            pub fn deinit(self: *Self) void {
                if (self.head) |head| {
                    self.allocator.deallocate(head, self.size());

                    self.head = null;
                    self.tail = null;
                    self.limit = null;
                }
                self.__proxy.deinit();
            }
        };
    }

    pub const String = msvc.StringRaw(Allocator(u8));

    pub fn StringRaw(comptime Alloc: type) type {
        const Heap = extern struct {
            ptr: [*]u8,
            __payload: usize,
        };

        const Data = extern union {
            in_place: [@sizeOf(Heap)]u8,
            heap: Heap,
        };

        return extern struct {
            const Self = @This();

            __proxy: Container,
            allocator: Alloc,
            data: Data,
            len: usize,
            cap: usize,

            pub fn init(allocator: Alloc) Self {
                return .{
                    .__proxy = Container.init(),
                    .allocator = allocator,
                    .data = undefined,
                    .len = 0,
                    .cap = @sizeOf(Heap) - 1,
                };
            }

            inline fn inHeap(self: *const Self) bool {
                return self.cap > (@sizeOf(Heap) - 1);
            }

            pub inline fn size(self: *const Self) usize {
                return self.len;
            }

            pub inline fn capacity(self: *const Self) usize {
                return self.cap;
            }

            pub inline fn values(self: *Self) []u8 {
                return if (self.inHeap())
                    self.data.heap.ptr[0..self.len]
                else
                    self.data.in_place[0..self.len];
            }

            pub fn deinit(self: *Self) void {
                if (self.inHeap()) {
                    self.allocator.deallocate(@as(*u8, @ptrCast(self.data.heap.ptr)), self.cap);
                    self.data.in_place[0] = 0;
                }
                self.__proxy.deinit();
            }
        };
    }
};

pub const gnu = struct {
    pub fn Vector(comptime T: type) type {
        return gnu.VectorRaw(T, Allocator(T));
    }
    pub fn VectorRaw(comptime T: type, comptime Alloc: type) type {
        return extern struct {
            const Self = @This();

            head: ?*T = null,
            tail: ?*T = null,
            limit: ?*T = null,
            allocator: Alloc,

            pub fn init(allocator: Alloc) Self {
                return .{ .allocator = allocator };
            }

            pub inline fn size(self: *const Self) usize {
                return (@intFromPtr(self.tail) - @intFromPtr(self.head));
            }

            pub inline fn capacity(self: *const Self) usize {
                return (@intFromPtr(self.limit) - @intFromPtr(self.head));
            }

            pub inline fn values(self: Self) []T {
                return if (self.head) |head| @as([*]T, @ptrCast(head))[0..self.size()] else &[_]T{};
            }

            pub fn deinit(self: *Self) void {
                if (self.head) |head| {
                    self.allocator.deallocate(head, self.size());

                    self.head = null;
                    self.tail = null;
                    self.limit = null;
                }
            }
        };
    }
    pub const String = gnu.StringRaw(Allocator(u8));

    pub fn StringRaw(comptime Alloc: type) type {
        const Heap = extern struct {
            cap: usize,
            len: usize,
            ptr: [*]u8,
        };

        const Data = extern union {
            in_place: [@sizeOf(Heap)]u8,
            heap: Heap,
        };

        return extern struct {
            const Self = @This();

            data: Data,
            allocator: Alloc,

            pub fn init(allocator: Alloc) Self {
                return Self{
                    .data = Data{ .in_place = [_]u8{0} ** @sizeOf(Heap) },
                    .allocator = allocator,
                };
            }

            inline fn inHeap(self: *const Self) bool {
                return (self.data.in_place[0] & 1) != 0;
            }

            pub inline fn size(self: *const Self) usize {
                return if (self.inHeap()) self.data.heap.len else (self.data.in_place[0] >> 1);
            }

            pub inline fn capacity(self: *const Self) usize {
                return if (self.inHeap())
                    self.data.heap.cap
                else
                    @sizeOf(Heap) - 2;
            }

            pub inline fn values(self: *Self) []u8 {
                return if (self.inHeap())
                    self.data.heap.ptr[0..self.data.heap.len]
                else
                    self.data.in_place[1 .. (self.data.in_place[0] >> 1) + 1];
            }

            pub fn deinit(self: *Self) void {
                if (self.inHeap()) {
                    self.allocator.deallocate(@as(*u8, @ptrCast(self.data.heap.ptr)), self.data.heap.cap);
                    self.data.in_place[0] = 0;
                }
            }
        };
    }
};

pub fn Array(
    comptime T: type,
    comptime N: comptime_int,
) type {
    return @Type([N]T);
}

pub const Vector = native.Vector;
pub const VectorRaw = native.VectorRaw;

pub const String = native.String;
pub const StringRaw = native.StringRaw;
