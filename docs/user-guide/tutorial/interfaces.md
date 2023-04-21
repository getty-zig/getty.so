# Interfaces

Interfaces are a big part of Getty, so let's take some time now to learn a bit about them.

## Interface

In Getty, an __interface__ is a function whose parameter list specifies
constraints and behaviors. For example, the following code defines an interface
that requires from its implementations three associated types (`Context`, `O`,
`E`) and one method (`serializeBool`).

```zig title="Zig code"
fn BoolSerializer(
    // (1)!
    comptime Context: type,
    comptime O: type,
    comptime E: type,

    // (2)!
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
    },
) type

```

1.  `Context`, `O`, and `E` are types that implementations of `BoolSerializer`
    must provide.

1.  `methods` lists every method that implementations of `BoolSerializer` must
    provide or can override.

    If a method is not provided by an implementation, it is up to the interface
    to decide what happens. Generally, a compile error is raised, an error is
    returned, or a default implementation is used.

The return value of an interface is a namespace (i.e., a `struct` type with no
fields) that contains two declarations: an __interface type__ and an
__interface function__.

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

1.  `boolSerializer` is an interface function.

    Its job is to return a value of the interface type, also known as an
    __interface value__.

1.  `Interface` is an interface type. They generally have:

      - A single field to store an instance of an implementation.
      - Wrapper declarations that may come in handy.
      - Wrapper methods that define the interface's behavior.

<!--The above annotations need to be ordered like they are to avoid weirdness-->
<!--with the second list element in the interface type annotation.-->

!!! info "Naming Conventions"

    - Interface types are always named after the interface's import path. For
      example, the interface type for the
      [`getty.de.SeqAccess`](https://docs.getty.so/#A;std:de.SeqAccess)
      interface is named `@"getty.de.SeqAccess"`.

    - Interface functions are always named after the interface in `camelCase`
      format. For example, the interface function for the
      [`getty.de.SeqAccess`](https://docs.getty.so/#A;std:de.SeqAccess)
      interface is named `seqAccess`.

## Implementation

To implement a Getty interface, call the interface and apply `usingnamespace`
to the returned value. An interface type and an interface function will be imported into
your implementation.

```zig title="Zig code"
const std = @import("std");

const SerializerA = struct {
    usingnamespace BoolSerializer(
        @This(),
        void,
        error{},
        .{},
    );
};

const SerializerB = struct {
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

To use a value of, say `SerializerB`, as an implementation of `BoolSerializer`:

```zig title="Zig code"
pub fn main() !void {
    const s = SerializerB{}; // (1)!
    const bs = s.boolSerializer();  // (2)!

    // (3)!
    try bs.serializeBool(true);
    try bs.serializeBool(false);
}
```

1. Create a value of the implementing type, `OppositeSerializer`.
1. Create an interface value from the implementation using the interface function.
1. Use the interface value for all of your interface-y needs!

```console title="Shell session"
$ zig build run
false
true
```

## Next Steps

Okay, that should be enough to get us through the tutorial. Let's get started!

<!--If you want to learn more about interfaces in Getty, check out the-->
<!--[Interfaces](/user-guide/design/interfaces/) page.-->
