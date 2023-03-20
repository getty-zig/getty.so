# Installation

To install Getty:

1. Declare Getty as a dependency by writing the following in `build.zig.zon`:

    !!! warning

        Be sure to replace `<COMMIT>` in the URL with a commit from Getty.

    ```zig title="<code>build.zig.zon</code>"
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
&nbsp;

2. Expose Getty as a module by adding the following lines to `build.zig`:

    ```zig title="<code>build.zig</code>" hl_lines="7-8 17"
    const std = @import("std");

    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

        const opts = .{ .target = target, .optimize = optimize };
        const getty_mod = b.dependency("getty", opts).module("getty");

        const exe = b.addExecutable(.{
            .name = "my-project",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        exe.addModule("getty", getty_mod);
        exe.install();

        // (snip)
    }
    ```
&nbsp;

3. Obtain Getty's package hash by running `zig build`:

    ```console title="Shell session" hl_lines="5"
    $ zig build
    my-project/build.zig.zon:6:20: error: url field is missing corresponding hash field
            .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    note: expected .hash = "<HASH>",
    ```
&nbsp;

4. Update `build.zig.zon` with the obtained hash value:

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
