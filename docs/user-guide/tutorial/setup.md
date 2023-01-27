# Setup

To begin, we need to set up a new project.

1. Create a Zig application called `getty-learn`:

    ```sh title="Shell session"
    mkdir getty-learn
    cd getty-learn
    zig init-exe
    ```
&nbsp;

2. Install Getty into the `libs/getty` directory within `getty-learn`:

    ```sh title="Shell session"
    git clone https://github.com/getty-zig/getty libs/getty
    ```
&nbsp;

3. Make `getty-learn` aware of Getty by adding it as a package in `build.zig`:

    ```zig title="<code>build.zig</code>" hl_lines="2 10"
    const std = @import("std");
    const getty = @import("libs/getty/build.zig");

    pub fn build(b: *std.build.Builder) void {
        // ...

        const exe = b.addExecutable("getty-learn", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackage(getty.pkg(b));
        exe.install();
    }
    ```
&nbsp;

4. Replace the contents of `src/main.zig` with the following:

    ```zig title="<code>src/main.zig</code>"
    const std = @import("std");
    const getty = @import("getty");

    pub fn main() anyerror!void {
        std.debug.print("{}\n", .{getty});
    }
    ```
&nbsp;

5. Run the application to make sure everything is working correctly:

    ```sh title="Shell session"
    $ zig build run
    getty
    ```
