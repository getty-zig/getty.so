# Installation

To install Getty for your project, you can use any of the methods listed on
this page.

## Manual

!!! warning "Prerequisites"

    These steps assume that you have the `master` version of
    [Zig](https://ziglang.org/download/) installed.

1. Add Getty to your project.

    ```sh title="Shell session"
    git clone https://github.com/getty-zig/getty lib/getty
    ```

2. Make the following change in `build.zig`.

    ```zig title="<code>build.zig</code>" hl_lines="9"
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

    These steps assume that you have the `master` version of
    [Zig](https://ziglang.org/download/) and the
    [Gyro](https://github.com/mattnite/gyro#installation) package manager
    installed.

1. Add Getty to your project.

    ```sh title="Shell session"
    gyro add -s github getty-zig/getty
    gyro fetch
    ```

2. Make the following changes in `build.zig`.

    ```zig title="<code>build.zig</code>" hl_lines="2 10"
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

    These steps assume that you have the `master` version of
    [Zig](https://ziglang.org/download/) and the
    [Zigmod](https://github.com/nektro/zigmod#download) package manager
    installed.

1. Make the following changes in `zigmod.yml`.

    ```yaml title="<code>zigmod.yml</code>" hl_lines="3 4"
    # ...

    root_dependencies:
      - src: git https://gitub.com/getty-zig/getty
    ```

2. Add Getty to your project.

    ```sh title="Shell session"
    zigmod fetch
    ```

3. Make the following changes in `build.zig`.

    ```zig title="<code>build.zig</code>" hl_lines="2 10"
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
