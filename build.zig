const std = @import("std");

// From https://github.com/mitchellh/zig-libuv/blob/main/build.zig
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "uv",
        .target = target,
        .optimize = optimize,
    });

    // Include dirs
    lib.addIncludePath("include");
    lib.addIncludePath("src");

    // Links
    if (target.isWindows()) {
        lib.linkSystemLibrary("psapi");
        lib.linkSystemLibrary("user32");
        lib.linkSystemLibrary("advapi32");
        lib.linkSystemLibrary("iphlpapi");
        lib.linkSystemLibrary("userenv");
        lib.linkSystemLibrary("ws2_32");
    }
    if (target.isLinux()) {
        lib.linkSystemLibrary("pthread");
    }
    lib.linkLibC();

    // Compilation
    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();

    if (!target.isWindows()) {
        try flags.appendSlice(&.{
            "-D_FILE_OFFSET_BITS=64",
            "-D_LARGEFILE_SOURCE",
        });
    }

    if (target.isLinux()) {
        try flags.appendSlice(&.{
            "-D_GNU_SOURCE",
            "-D_POSIX_C_SOURCE=200112",
        });
    }

    if (target.isDarwin()) {
        try flags.appendSlice(&.{
            "-D_DARWIN_UNLIMITED_SELECT=1",
            "-D_DARWIN_USE_64_BIT_INODE=1",
        });
    }

    // C files common to all platforms
    lib.addCSourceFiles(&.{
        "src/fs-poll.c",
        "src/idna.c",
        "src/inet.c",
        "src/random.c",
        "src/strscpy.c",
        "src/strtok.c",
        "src/threadpool.c",
        "src/timer.c",
        "src/uv-common.c",
        "src/uv-data-getter-setters.c",
        "src/version.c",
    }, flags.items);

    if (!target.isWindows()) {
        lib.addCSourceFiles(&.{
            "src/unix/async.c",
            "src/unix/core.c",
            "src/unix/dl.c",
            "src/unix/fs.c",
            "src/unix/getaddrinfo.c",
            "src/unix/getnameinfo.c",
            "src/unix/loop-watcher.c",
            "src/unix/loop.c",
            "src/unix/pipe.c",
            "src/unix/poll.c",
            "src/unix/process.c",
            "src/unix/random-devurandom.c",
            "src/unix/signal.c",
            "src/unix/stream.c",
            "src/unix/tcp.c",
            "src/unix/thread.c",
            "src/unix/tty.c",
            "src/unix/udp.c",
        }, flags.items);
    }

    if (target.isLinux() or target.isDarwin()) {
        lib.addCSourceFiles(&.{
            "src/unix/proctitle.c",
        }, flags.items);
    }

    if (target.isLinux()) {
        lib.addCSourceFiles(&.{
            "src/unix/linux.c",
            "src/unix/procfs-exepath.c",
            "src/unix/random-getrandom.c",
            "src/unix/random-sysctl-linux.c",
        }, flags.items);
    }

    if (target.isDarwin() or
        target.isOpenBSD() or
        target.isNetBSD() or
        target.isFreeBSD() or
        target.isDragonFlyBSD())
    {
        lib.addCSourceFiles(&.{
            "src/unix/bsd-ifaddrs.c",
            "src/unix/kqueue.c",
        }, flags.items);
    }

    if (target.isDarwin() or target.isOpenBSD()) {
        lib.addCSourceFiles(&.{
            "src/unix/random-getentropy.c",
        }, flags.items);
    }

    if (target.isDarwin()) {
        lib.addCSourceFiles(&.{
            "src/unix/darwin-proctitle.c",
            "src/unix/darwin.c",
            "src/unix/fsevents.c",
        }, flags.items);
    }
}
