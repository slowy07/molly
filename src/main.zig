const Transpiler = @import("transpiler.zig");
const std = @import("std");
const builtin = @import("builtin");

const debug = std.debug;
const io = std.io;
const log = std.log;
const json = std.json;
const mem = std.mem;
const fmt = std.fmt;

const Allocator = mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() != .leak) catch @panic("memory leak");
    const allocator = gpa.allocator();
    var clang = std.ArrayList([]const u8).init(allocator);
    defer clang.deinit();

    try clang.append("zig");
    try clang.append("cc");
    try clang.append("-x");
    try clang.append("c++");
    try clang.append("-lc++");
    try clang.append("-Xclang");
    try clang.append("-ast-dump=json");
    try clang.append("-fsyntax-only");
    try clang.append("-fparse-all-comments");

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    var target_tuple: ?[]const u8 = null;
    var transpiler = Transpiler.init(allocator);
    defer transpiler.deinit();
    var output_ast = false;

    var i: usize = 1;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (mem.eql(u8, arg, "-h") or mem.eql(u8, arg, "-help")) {
            _ = try io.getStdErr().writer().write(
                \\-h, -help                    Display this help and exit
                \\-target TARGET_TUPLE         Clang target tuple, e.g. x86_86-windows-gnu
                \\-R                           Recursive transpiling, use to also parse includes
                \\-no-glue                     No C++ glue code, bindings will be target specific
                \\-no-comments                 Don't write comments
                \\-c99                         Use C99 instead of C++
                \\[clang arguments]            Pass any clang arguments, e.g. -DNDEBUG -I.\include -target x86-linux-gnu
                \\[--] [FILES]                 Input files
                \\
            );
            return;
        } else if (mem.eql(u8, arg, "-c99")) {
            clang.items[3] = "c";
            clang.items[4] = "-std=c99";
            transpiler.no_glue = true;
            continue;
        } else if (mem.eql(u8, arg, "-R")) {
            transpiler.recursive = true;
            continue;
        } else if (mem.eql(u8, arg, "-output-ast")) {
            output_ast = true;
            continue;
        } else if (i == argv.len - 1 and arg[0] != '-') {
            break;
        }
        try clang.append(arg);
    }
    const host_target = try builtin.target.linuxTriple(allocator);
    defer allocator.free(host_target);
    if (target_tuple == null) {
        target_tuple = host_target;
    }

    var dclang = std.ArrayList(u8).init(allocator);
    defer dclang.deinit();
    for (clang.items) |arg| {
        try dclang.appendSlice(arg);
        try dclang.appendSlice(" ");
    }
    log.info("{s}", .{dclang.items});

    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd);

    var output_path = std.ArrayList(u8).init(allocator);
    defer output_path.deinit();

    while (i < argv.len) : (i += 1) {
        const file_path = argv[i];
        log.info("binding `{s}`", .{file_path});
        try clang.append(file_path);
        defer _ = clang.pop();

        const astdump = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = clang.items,
            .max_output_bytes = 4 * 512 * 1024 * 1024,
        });
        defer {
            allocator.free(astdump.stdout);
            allocator.free(astdump.stderr);
        }

        if (output_ast) {
            var astfile = try std.fs.cwd().createFile("molly_ast.json", .{});
            try astfile.writeAll(astdump.stdout);
            astfile.close();
        }
    }
}
