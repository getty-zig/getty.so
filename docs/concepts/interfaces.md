# Interfaces

When building a (de)serializer in Getty, you will eventually have to implement
an interface.

Unfortunately, interfaces in Zig are a userspace thing so everyone has their
own way of doing things. So, let's quickly go over how Getty implements interfaces and how you can use them.

## Definition

A __Getty interface__ is a function, and its constraints are specified as a
parameter list. For instance, the following interface requires 3 associated
types and 1 method from its implementations.

```zig title="Zig code"
// (1)!
fn BoolSerializer(
    // (2)!
    comptime Context: type,
    comptime O: type,
    comptime E: type,

    // (3)!
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
    },
) type

```

1.  This function is an interface similar to the ones defined in Getty.

1.  These parameters are associated types that implementations of `BoolSerializer` must provide.

1.  This parameter contains the methods that implementations of `BoolSerializer` must or can provide.

    If a method is not provided by an implementation, it is up to the interface
    to decide what happens. Generally, a compile error is raised or an error is
    returned.

The return value of a Getty interface is a `#!zig struct` namespace that
contains two declarations: an __interface type__ and an __interface function__.
A value of the interface type is an __interface value__.

```zig title="Zig code"
fn BoolSerializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
    },
) type {
    return struct {
        // (2)!
        pub const Interface = struct {
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

        // (1)!
        pub fn boolSerializer(self: Context) Interface {
            return .{ .context = self };
        }
    };
}
```

1.  This function is an interface function. Its job is to return an interface value.

1.  This declaration is an interface type. They generally have:
      - A single field to store an instance of an implementation.
      - A few declarations that may be useful to implementations.
      - Wrapper methods that define the interface's behavior.

<!--The above annotations need to be ordered like they are to avoid weirdness-->
<!--with the second list element in the interface type annotation.-->

!!! info "Naming Conventions"

    - Interface types are named after the interface's import path. For example,
      the interface type for the
      [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface is
      named `#!zig @"getty.Serializer"`.

    - Interface functions have the same name as the interface, except in
      `camelCase` format. For example, the interface type for the
      [`getty.de.SeqAccess`](https://docs.getty.so/#root;de.SeqAccess)
      interface is named `seqAccess`.

## Implementation

To implement a Getty interface, call the interface and apply `#!zig
usingnamespace` to its return value. This will import an interface type and
interface function into your implementation.

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

To use a value of, say `OppositeSerializer`, as an implementation of `BoolSerializer`:

```zig title="Zig code"
pub fn main() anyerror!void {
    const os = OppositeSerializer{}; // (1)!
    const bs = os.boolSerializer();  // (2)!

    // (3)!
    try bs.serializeBool(true);
    try bs.serializeBool(false);
}
```

1. Create a value of the implementing type, `OppositeSerializer`.
1. Create an interface value from your implementation using the interface function.
1. Use the interface value for all of your interface-y needs!

```console title="Shell session"
$ zig build run
false
true
```
