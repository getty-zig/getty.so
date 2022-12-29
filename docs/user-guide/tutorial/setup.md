# Setup

First things first, we need to set up a new project to work in.

1. Create a new Zig project called `getty-learn`:

    ```sh title="Shell session"
    mkdir getty-learn
    cd getty-learn
    zig init-exe
    ```

2. Install Getty into the `lib/getty` directory within `getty-learn`:

    ```sh title="Shell session"
    git clone https://github.com/getty-zig/getty lib/getty
    ```

3. Make `getty-learn` aware of Getty by calling `addPackagePath` in `build.zig`:

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

4. Replace the contents of `src/main.zig` with the following:

    ```zig title="<code>src/main.zig</code>"
    const std = @import("std");
    const getty = @import("getty");

    pub fn main() anyerror!void {
        std.debug.print("{}\n", .{getty});
    }
    ```

5. Run the application to make sure everything is working correctly.

    ```sh title="Shell session"
    $ zig build run
    getty
    ```
