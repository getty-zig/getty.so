# Setup

1. Create a new Zig project called `getty-learn`:

    ```sh title="Shell session"
    mkdir getty-learn
    cd getty-learn
    zig init
    ```
&nbsp;

2. Declare Getty as a dependency with `zig fetch`:

    ```sh title="Shell session"
    # Latest version
    zig fetch --save git+https://github.com/getty-zig/getty.git#main

    # Specific version
    zig fetch --save git+https://github.com/getty-zig/getty.git#<COMMIT>
    ```
&nbsp;

2. Expose Getty as a module in `build.zig`:

    ```zig title="<code>build.zig</code>" hl_lines="5-6 14"
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
        exe.root_module.addImport("getty", getty_mod);

        // ...
    }
    ```
&nbsp;

3. Replace `src/main.zig`'s content with the following code to ensure everything is correct:

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
