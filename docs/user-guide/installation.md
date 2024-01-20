# Installation

To install Getty:

1. Declare Getty as a dependency (replace `<COMMIT>` with an actual commit SHA):

    ```sh
    zig fetch --save git+https://github.com/getty-zig/getty.git#<COMMIT>
    ```

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
