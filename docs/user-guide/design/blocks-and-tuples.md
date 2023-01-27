# Blocks and Tuples

__Blocks__ are the fundamental building blocks (pun intended) of Getty's
(de)serialization process.

They define how types should be serialized or deserialized into. For example,
all of the ways a `bool` value can be serialized by Getty are specified
in the [`getty.ser.blocks.Bool`](https://github.com/getty-zig/getty/blob/main/src/ser/blocks/bool.zig)
block, and all of the ways that you can deserialize into a `[5]i32` are defined in
[`getty.de.blocks.Array`](https://github.com/getty-zig/getty/blob/main/src/de/blocks/array.zig).

Internally, Getty uses blocks to form its core (de)serialization behavior.
However, they are also the main mechanism for customization in Getty.
Users and (de)serializers can take advantage of blocks in order to customize
the way Getty (de)serializes values, as we'll see later on.

## Blocks

A block is nothing more than a `struct` namespace that specifies two
things:

1. The type(s) that should be (de)serialized by the block.
1. How to serialize or deserialize into values of those types.

There are a few different kinds of blocks you can make in Getty, so let's go
over them now.

### Serialization Blocks

To manually define the serialization process for a type, you can use a
__serialization block__.

```zig title="Zig code"
const sb = struct {
    // (1)!
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // (2)!
    pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
        // Convert bool value to a Getty Integer.
        const v: i32 = if (value) 1 else 0;

        // Pass the Getty Integer value to the serializer.
        return try serializer.serializeInt(v);
    }
};
```

1.  `is` specifies which types can be serialized by the `sb` block.
    <br>
    <br>
    In this case, the `sb` block applies only to `bool` values.

1.  `serialize` specifies how to serialize values relevant to the `sb` block into Getty's data model.
    <br>
    <br>
    In this case, we're telling Getty to serialize `bool` values as _Integers_.

### Deserialization Blocks

To manually define the deserialization process for a type, you can use a __deserialization block__.

```zig title="Zig code"
const db = struct {
    // (1)!
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // (2)!
    pub fn deserialize(
        allocator: ?std.mem.Allocator,
        comptime _: type, // (3)!
        deserializer: anytype,
        visitor: anytype,
    ) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
        return try deserializer.deserializeInt(allocator, visitor);
    }

    // (4)!
    pub fn Visitor(comptime Value: type) type {
        return struct {
            pub usingnamespace getty.de.Visitor(
                @This(),
                Value,
                .{ .visitInt = visitInt },
            );

            pub fn visitInt(
                _: @This(),
                allocator: ?std.mem.Allocator,
                comptime Deserializer: type,
                input: anytype,
            ) Deserializer.Error!Value {
                return input != 0;
            }
        };
    }
};
```

1.  `is` specifies which types can be deserialized into by the `db` block.
    <br>
    <br>
    In this case, the `db` block applies only to `bool` values.

1.  `deserialize` specifies the hint that Getty should provide a deserializer
    about the type being deserialized into.
    <br>
    <br>
    In this case, we call `deserializeInt`, which means that Getty will tell
    the deserializer that the Zig type being deserialized into can probably be
    made from a Getty Integer.

1.  This parameter (often named `T`) is the current type being deserialized into.
    <br>
    <br>
    Usually, you don't need it unless you're doing pointer deserialization.

1. `Visitor` is a generic type that implements [`getty.de.Visitor`](https://docs.getty.so/#A;std:de.Visitor).
    <br>
    <br>
    Visitors are responsible for specifying how to deserialize values from
    Getty's data model into Zig. In this case, our visitor can deserialize
    _Integers_ into `bool` values, which it does by simply returning
    whether or not the integer is 0.


### Attribute Blocks

SBs and DBs are typically used for complex modifications to Getty's
(de)serialization processes. For simpler customizations, you can usually get
away with the more convenient __attribute blocks__.

!!! warning "Compatibility"

    Attribute blocks may only be defined by `struct` and `union` types.

With ABs, Getty's default (de)serialization processes are used. For
example, `struct` values would be serialized using the default
`getty.ser.blocks.Struct` block and deserialized with the default
`getty.de.blocks.Struct` block. However, based on the attributes that you
specify, slight changes to these default processes will take effect.

Regardless of whether you're serializing or deserializing, ABs are always
defined like so:

```zig title="Zig code"
const Point = struct {
    x: i32,
    y: i32 = 123,
};

const ab = struct {
    pub fn is(comptime T: type) bool {
        return T == Point;
    }

    // (1)!
    pub const attributes = .{ // (2)!
        .x = .{ .rename = "X" }, // (3)!
        .y = .{ .skip = true },
    };
};
```

1. `attributes` specifies various (de)serialization properties for values
   relevant to the `ab` block.
   <br>
   <br>
   If `ab` is used for serialization, then `attributes` specifies that the `x`
   field of `Point` should be serialized as `"X"`, and that the `y` field of
   `Point` should be skipped.
   <br>
   <br>
   If `ab` is used for deserialization, then `attributes` specifies that the
   value for the `x` field of `Point` has been serialized as `"X"`, and that
   the `y` field of `Point` should not be deserialized.
   <br>
   <br>

2. `attributes` is an anonymous struct literal.
    <br>
    <br>
    Each field name in `attributes` must match either a field or variant in
    your `struct` or `union`, or the word `Container`. The former are known as
    __field/variant attributes__, while the latter are known as __container
    attributes__.

3. Each field in `attributes` is also an anonymous struct literal. The
   fields in these inner `struct` values depend on the kind of attribute
   you're specifying (i.e., field/variant or container).

!!! info "Supported Attributes"

    For a complete list of the attributes supported by Getty, see
    [here](https://github.com/getty-zig/getty/blob/develop/src/attributes.zig).

### Type-Defined Blocks

The blocks we've discussed so far are known as _out-of-band blocks_. They're
defined separately from the type(s) that they operate on. Out-of-band blocks have
their place, such as when you want to customize a type that you didn't define
(e.g., the types in `std`). However, there's a more convenient way to do
things for `struct` and `union` types that you did define yourself.

If you define a block _within_ a `struct` or `union`, Getty will automatically
process it without you having to pass it to a (de)serializer. All you have to
do is make sure the block is public and named `@"getty.sb"` (for serialization)
or `@"getty.db"` (for deserialization).

Type-defined blocks are defined exactly the same as attribute, serialization,
and deserialization blocks are. The only difference is that you don't need an
`is` function in a type-defined block.

```zig title="Zig code"
const Point = struct {
    x: i32,
    y: i32,

    pub const @"getty.sb" = struct {
        pub const attributes = .{
            .x = .{ .rename = "X" },
            .y = .{ .skip = true },
        };
    };
};
```

### Usage

Once you've defined a block, you can pass them along to Getty via the
[`getty.Serializer`](https://docs.getty.so/#A;std:Serializer) and
[`getty.Deserializer`](https://docs.getty.so/#A;std:Deserializer) interfaces.
They take optional (de)serialization blocks as arguments.

For example, the following defines a serializer that can serialize _Booleans_
and _Integers_ into JSON. It's generic over an SB, which it passes to Getty,
making it even easier for us to customize Getty's behavior.

```zig title="Zig code"
const std = @import("std");
const getty = @import("getty");

fn Serializer(comptime user_sb: ?type) type {
    return struct {
        pub usingnamespace getty.Serializer(
            @This(),
            Ok,
            Error,
            user_sb orelse null,
            null,
            null,
            null,
            null,
            .{
                .serializeBool = serializeBool,
                .serializeInt = serializeInt,
            },
        );

        const Ok = void;
        const Error = error{};

        fn serializeBool(_: @This(), value: bool) Error!Ok {
            std.debug.print("{}\n", .{value});
        }

        fn serializeInt(_: @This(), value: anytype) Error!Ok {
            std.debug.print("{}\n", .{value});
        }
    };
}

const sb = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        const v: i32 = if (value) 1 else 0;
        return try serializer.serializeInt(v);
    }
};

pub fn main() anyerror!void {
    // Normal
    {
        var s = Serializer(null){};
        const serializer = s.serializer();

        try getty.serialize(true, serializer);
        try getty.serialize(false, serializer);
    }

    // Custom
    {
        var s = Serializer(sb){};
        const serializer = s.serializer();

        try getty.serialize(true, serializer);
        try getty.serialize(false, serializer);
    }
}
```

```console title="Shell session"
$ zig build run
true
false
1
0
```

## Tuples

In order to pass multiple (de)serialization blocks to Getty, you can use
__(de)serialization tuples__.

A (de)serialization tuple is, well, a tuple of (de)serialization blocks. They
can be used wherever a (de)serialization block can be used and allow you to do
some pretty cool things. For example, suppose you had the following type:


```zig title="Zig code"
const Point = struct {
    x: i32,
    y: i32,
};
```

If all you wanted to do was serialize `Point` values as _Sequences_, you'd
just write an SB and pass it along to Getty. However, what if you also wanted
to serialize `i32` values as _Booleans_? One option is to stuff all of
your custom serialization logic into a single block. But that gets messy really
quick and inevitably becomes a pain to maintain.

A much better solution is to break up your serialization logic into separate
blocks. One for `Point` values and one for `i32` values. Then, you just
group them together as a serialization tuple!

```zig title="Zig code"
const point_sb = struct { ... };
const i32_sb = struct { ... };

const point_st = .{ point_sb, i32_sb };
```
