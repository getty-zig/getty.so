# Interfaces

Interfaces are a big part of Getty, so let's take some time now to learn a bit about them.

## Interface

In Getty, an __interface__ is a function whose parameter list specifies
constraints and behaviors. For example, the following code defines an interface
that requires from its implementations three associated types (`Context`, `O`,
`E`) and one method (`serializeBool`).

```zig title="Zig code"
fn BoolSerializer(
    // Context, O, and E are associated types that must be provided.
    comptime Context: type,
    comptime O: type,
    comptime E: type,

    // methods lists every method that implementations of BoolSerializer must
    // provide or can override.
    //
    // If a method is not provided by an implementation, it is up to the
    // interface to decide what happens. Generally, a compile error is raised,
    // an error is returned, or a default implementation is used.
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
    },
) type

```

The return value of an interface is a namespace (i.e., a `struct` type with no
fields) that contains two declarations: an __interface type__ and an
__interface function__.

```zig title="Zig code"
struct {
    // Iface is an interface type. These generally have:
    //
    //   * A field to store an instance of an implementation.
    //   * Wrapper declarations for important associated types.
    //   * Wrapper methods that define the interface's behavior.
    pub const Iface = struct {
        context: Context,

        pub const Ok = O;
        pub const Error = E;

        pub fn serializeBool(self: @This(), value: bool) Error!Ok {
            if (methods.serializeBool) |f| {
                return try f(self.context, value);
            }

            @compileError("serializeBool is unimplemented");
        }
    };

    // boolSerializer is an interface function.
    //
    // Its job is to return a value of the interface type, also known as
    // an interface value.
    pub fn boolSerializer(self: Context) Iface {
        return .{ .context = self };
    }
};
```

!!! info "Naming Conventions"

    - Interface types are always named after the interface's import path. For
      example, the interface type for the
      [`getty.de.SeqAccess`](https://docs.getty.so/#A;getty:de.SeqAccess)
      interface is named `@"getty.de.SeqAccess"`.

    - Interface functions are always named after the interface in `camelCase`
      format. For example, the interface function for the
      [`getty.de.SeqAccess`](https://docs.getty.so/#A;getty:de.SeqAccess)
      interface is named `seqAccess`.

## Implementation

To implement a Getty interface, call the interface and apply `usingnamespace`
to the returned value. An interface type and an interface function will be imported into
your implementation.

```zig title="Zig code"
const std = @import("std");

const UselessSerializer = struct {
    usingnamespace BoolSerializer(
        @This(),
        void,
        error{},
        .{},
    );
};

const OppositeSerializer = struct {
    usingnamespace BoolSerializer(
        Context,
        Ok,
        Error,
        .{ .serializeBool = serializeBool },
    );

    const Context = @This();
    const Ok = void;
    const Error = error{};

    fn serializeBool(_: Context, value: bool) Error!Ok {
        std.debug.print("{}\n", .{!value});
    }
};
```

## Usage

To use a value of `OppositeSerializer` as an implementation of `BoolSerializer`:

```zig title="Zig code"
pub fn main() !void {
    // Create a value of the implementing type.
    const s = OppositeSerializer{};

    // Create an interface value from `s` using the interface function.
    const bs = s.boolSerializer();

    // Use the interface value for all of our interface-y needs!
    try bs.serializeBool(true);
    try bs.serializeBool(false);
}
```

```console title="Shell session"
$ zig build run
false
true
```
