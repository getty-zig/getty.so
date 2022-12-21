# Installation

To install Getty for your project, you can use any of the following methods.

## Manually

1. Add Getty to your project.

    === "Shell session"

        ```sh
        git clone https://github.com/getty-zig/getty lib/getty
        ```

2. Add the following line to `build.zig`.

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

1. Add Getty to your project.

    === "Shell session"

        ```sh
        gyro add -s github getty-zig/getty
        gyro fetch
        ```

2. Add the following lines to `build.zig`.

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

1. Add the following lines to `zigmod.yml`.

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

3. Add the following lines to `build.zig`.

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
