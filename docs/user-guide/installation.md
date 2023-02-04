# Installation

!!! warning "Prerequisites"

    Please make sure you have the `master` version of
    [Zig](https://ziglang.org/download/) installed.

To install Getty:

1. Declare Getty as a dependency in `build.zig.zon`:

    ```zig title="<code>build.zig.zon</code>" hl_lines="5-7"
    .{
        .name = "my-project",
        .version = "0.0.0",
        .dependencies = .{
            .getty = .{
                .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
            },
        },
    }
    ```

2. Expose Getty as a module in `build.zig`:

    ```zig title="<code>build.zig</code>" hl_lines="7-8 11"
    const std = @import("std");

    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

        const opts = .{ .target = target, .optimize = optimize };
        const getty_module = b.dependency("getty", opts).module("getty");

        const exe = b.addExecutable(.{ .name = "my-project", .root_source_file = .{ .path = "src/main.zig" }, .target = target, .optimize = optimize });
        exe.addModule("getty", getty_module);
        exe.install();

        ...
    }
    ```

3. Obtain Getty's package hash:

    ```console title="Shell session"
    $ zig build
    my-project/build.zig.zon:6:20: error: url field is missing corresponding hash field
            .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    note: expected .hash = "<HASH>",
    ```

4. Update `build.zig.zon` with the hash value:

    ```zig title="<code>build.zig.zon</code>" hl_lines="7"
    .{
        .name = "my-project",
        .version = "0.0.0",
        .dependencies = .{
            .json = .{
                .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
                .hash = "<HASH>",
            },
        },
    }
    ```
