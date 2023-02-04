# Setup

To begin, we need to set up a new project.

1. Create a Zig application called `getty-learn`:

    ```sh title="Shell session"
    mkdir getty-learn
    cd getty-learn
    zig init-exe
    ```
&nbsp;

2. Declare Getty as a dependency in `build.zig.zon`:

    ```zig title="<code>build.zig.zon</code>" hl_lines="5-7"
    .{
        .name = "getty-learn",
        .version = "0.0.0",
        .dependencies = .{
            .getty = .{
                .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
            },
        },
    }
    ```
&nbsp;

3. Expose Getty as a module in `build.zig`:

    ```zig title="<code>build.zig</code>" hl_lines="7-8 11"
    const std = @import("std");

    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

        const opts = .{ .target = target, .optimize = optimize };
        const getty_module = b.dependency("getty", opts).module("getty");

        const exe = b.addExecutable(.{ .name = "getty-learn", .root_source_file = .{ .path = "src/main.zig" }, .target = target, .optimize = optimize });
        exe.addModule("getty", getty_module);
        exe.install();

        ...
    }
    ```
&nbsp;

4. Obtain Getty's package hash:

    ```console title="Shell session"
    $ zig build
    getty-learn/build.zig.zon:6:20: error: url field is missing corresponding hash field
            .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    note: expected .hash = "<HASH>",
    ```
&nbsp;

5. Update `build.zig.zon` with the hash value:

    ```zig title="<code>build.zig.zon</code>" hl_lines="7"
    .{
        .name = "getty-learn",
        .version = "0.0.0",
        .dependencies = .{
            .json = .{
                .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
                .hash = "<HASH>",
            },
        },
    }
    ```
&nbsp;

6. Replace the contents of `src/main.zig` with the following:

    ```zig title="<code>src/main.zig</code>"
    const std = @import("std");
    const getty = @import("getty");

    pub fn main() anyerror!void {
        std.debug.print("{}\n", .{getty});
    }
    ```
&nbsp;

7. Run the application to make sure everything is working correctly:

    ```sh title="Shell session"
    $ zig build run
    getty
    ```
