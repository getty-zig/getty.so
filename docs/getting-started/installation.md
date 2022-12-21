# Installation

To install Getty for your project, you can use any of the methods listed on this page.

??? info "Confirming the Installation"

    Once you've installed Getty, you can check that everything works by running the following program.

    === "`src/main.zig`"

        ```zig
        const std = @import("std");
        const getty = @import("getty");

        pub fn main() !void {
            std.debug.print("{}\n", .{getty});
        }
        ```

        <div class="result" markdown>

        ```console
        $ zig build run
        getty
        ```

        </div>


## Manual

!!! warning "Prerequisites"

    For this section, you must have the latest version of [Zig](https://ziglang.org/download/) (`master`) installed.

1. Add Getty to your project.

    === "Shell session"

        ```sh
        git clone https://github.com/getty-zig/getty lib/getty
        ```

2. Make the following change in `build.zig`.

    === "`build.zig`"

        ```zig hl_lines="9"
        const std = @import("std");

        pub fn build(b: *std.build.Builder) void {
            // ...

            const exe = b.addExecutable("getty-learn", "src/main.zig");
            exe.setTarget(target);
            exe.setBuildMode(mode);
            exe.addPackagePath("getty", "lib/getty/src/getty.zig");
            exe.install();
        }
        ```

## Gyro

!!! warning "Prerequisites"

    For this section, you must have the latest version of [Zig](https://ziglang.org/download/) (`master`) and the [Gyro](https://github.com/mattnite/gyro#installation) package manager installed.

1. Add Getty to your project.

    === "Shell session"

        ```sh
        gyro add -s github getty-zig/getty
        gyro fetch
        ```

2. Make the following changes to `build.zig`.

    === "`build.zig`"

        ```zig hl_lines="2 10"
        const std = @import("std");
        const pkgs = @import("deps.zig").pkgs;

        pub fn build(b: *std.build.Builder) void {
            // ...

            const exe = b.addExecutable("getty-learn", "src/main.zig");
            exe.setTarget(target);
            exe.setBuildMode(mode);
            pkgs.addAllTo(exe);
            exe.install();
        }
        ```

## Zigmod

!!! warning "Prerequisites"

    For this section, you must have the latest version of [Zig](https://ziglang.org/download/) (`master`) and the [Zigmod](https://github.com/nektro/zigmod#download) package manager installed.

1. Make the following changes to `zigmod.yml`.

    === "`zigmod.yml`"

        ```yaml hl_lines="3 4"
        # ...

        root_dependencies:
          - src: git https://gitub.com/getty-zig/getty
        ```

2. Add Getty to your project.

    === "Shell session"

        ```sh
        zigmod fetch
        ```

3. Make the following changes in `build.zig`.

    === "`build.zig`"

        ```zig hl_lines="2 10"
        const std = @import("std");
        const deps = @import("deps.zig");

        pub fn build(b: *std.build.Builder) void {
            // ...

            const exe = b.addExecutable("getty-learn", "src/main.zig");
            exe.setTarget(target);
            exe.setBuildMode(mode);
            deps.addAllTo(exe);
            exe.install();
        }
        ```
