# Setup

To get started, let's make a new Zig project.

1. Create a Zig application called `getty-learn`:

    ```sh title="Shell session"
    mkdir getty-learn
    cd getty-learn
    zig init-exe
    ```
&nbsp;

2. Declare Getty as a dependency by writing the following in `build.zig.zon`:

    !!! warning

        Be sure to replace `<COMMIT>` in the URL with a commit SHA from Getty.

    ```zig title="<code>build.zig.zon</code>"
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

3. Expose Getty as a module by adding the following lines to `build.zig`:

    ```zig title="<code>build.zig</code>" hl_lines="7-8 11"
    const std = @import("std");

    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

        const opts = .{ .target = target, .optimize = optimize };
        const getty_mod = b.dependency("getty", opts).module("getty");

        const exe = b.addExecutable(.{ .name = "getty-learn", .root_source_file = .{ .path = "src/main.zig" }, .target = target, .optimize = optimize });
        exe.addModule("getty", getty_mod);
        exe.install();

        // (snip)
    }
    ```
&nbsp;

4. Obtain Getty's package hash (denoted below as `<HASH>`) by running `zig build` once:

    ```console title="Shell session"
    $ zig build
    getty-learn/build.zig.zon:6:20: error: url field is missing corresponding hash field
            .url = "https://github.com/getty-zig/getty/archive/<COMMIT>.tar.gz",
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    note: expected .hash = "<HASH>",
    ```
&nbsp;

5. Update `build.zig.zon` with the obtained hash value:

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

6. To verify everything, replace the contents of `src/main.zig` with the following code:

    ```zig title="<code>src/main.zig</code>"
    const std = @import("std");
    const getty = @import("getty");

    pub fn main() !void {
        std.debug.print("Hello, {}!\n", .{getty});
    }
    ```

    ```console title="Shell session"
    $ zig build run
    Hello, getty!
    ```
