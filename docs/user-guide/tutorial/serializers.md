# Serializers

Every Getty serializer must implement the
[`getty.Serializer`](https://docs.getty.so/#A;getty:Serializer) interface, shown
below.

```zig title="Zig code"
// (1)!
fn Serializer(
    comptime Context: type, // (2)!
    comptime O: type, // (3)!
    comptime E: type, // (4)!

    // (5)!
    comptime user_sbt: anytype,
    comptime serializer_sbt: anytype,

    // (6)!
    comptime Map: ?type,
    comptime Seq: ?type,
    comptime Structure: ?type,

    // (7)!
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
        serializeEnum: ?fn (Context, anytype, []const u8) E!O = null,
        serializeFloat: ?fn (Context, anytype) E!O = null,
        serializeInt: ?fn (Context, anytype) E!O = null,
        serializeMap: ?fn (Context, ?usize) E!Map = null,
        serializeNull: ?fn (Context) E!O = null,
        serializeSeq: ?fn (Context, ?usize) E!Seq = null,
        serializeSome: ?fn (Context, anytype) E!O = null,
        serializeString: ?fn (Context, anytype) E!O = null,
        serializeStruct: ?fn (Context, comptime []const u8, usize) E!Structure = null,
        serializeVoid: ?fn (Context) E!O = null,
    },
) type
```

1.  A `Serializer` serializes values from Getty's data model into a data format.

2.  `Context` is a namespace that owns the method implementations passed to the
    `methods` parameter.

    Usually, this is the type implementing
    [`getty.Serializer`](https://docs.getty.so/#A;getty:Serializer) or a pointer
    to it if mutability is required.

3.  `O` is the successful return type for most of a `Serializer`'s methods.

4.  `E` is the error set returned by a `Serializer`'s methods upon failure.

    `E` must contain [`getty.ser.Error`](https://docs.getty.so/#A;getty:ser.Error).

5.  `user_sbt` and `serializer_sbt` are optional user- and serializer-defined
    SBTs, respectively.

    SBTs allow users and serializers to customize Getty's serialization
    behavior. If user- or serializer-defined customization isn't supported, you
    can pass in `null`.

6.  `Map`, `Seq`, and `Structure` are optional types that implement Getty's
    aggregate serialization interfaces.

    Those interfaces are
    [`getty.ser.Map`](https://docs.getty.so/#A;getty:ser.Map),
    [`getty.ser.Seq`](https://docs.getty.so/#A;getty:ser.Seq), and
    [`getty.ser.Structure`](https://docs.getty.so/#A;getty:ser.Structure).

7.  `methods` lists every method that a `Serializer` must provide or can
    override.

Quite the parameter list!

Luckily, most of the parameters have default values we can use. So let's kick
things off with the following implementation:

```zig title="<code>src/main.zig</code>"
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{},
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;
};
```

## Scalar Serialization

To serialize a value with our brand new `Serializer`, we can call
[`getty.serialize`](https://docs.getty.so/#A;getty:serialize), which takes an
optional allocator, a value to serialize, and a
[`getty.Serializer`](https://docs.getty.so/#A;getty:Serializer) interface
value.

```zig title="<code>src/main.zig</code>" hl_lines="21-26"
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{},
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;
};

pub fn main() !void {
    const s = Serializer{};
    const ss = s.serializer();

    try getty.serialize(null, true, ss);
}
```

```console title="Shell session"
$ zig build run
[...] error: serializeBool is not implemented by type: main.Serializer
```

A compile error!

It looks like Getty can't serialize `bool`s unless `serializeBool` is
implemented. Let's fix that.

```zig title="<code>src/main.zig</code>" hl_lines="1 14-16 23-25 34"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{
            .serializeBool = serializeBool,
        },
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: Context, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }
};

pub fn main() !void {
    const s = Serializer{};
    const ss = s.serializer();

    try getty.serialize(null, true, ss);

    std.debug.print("\n", .{});
}
```

```console title="Shell session"
$ zig build run
true
```

Success!

Now let's do the same thing for the other scalar types.

```zig title="<code>src/main.zig</code>" hl_lines="16-22 34-52 59-63"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeVoid = serializeNothing,
            .serializeString = serializeString,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
        },
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: Context, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNumber(_: Context, value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNothing(_: Context) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeString(_: Context, value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeEnum(c: Context, _: anytype, name: []const u8) Error!Ok {
        try c.serializeString(name);
    }

    fn serializeSome(c: Context, value: anytype) Error!Ok {
        try getty.serialize(null, value, c.serializer());
    }
};

pub fn main() !void {
    const s = Serializer{};
    const ss = s.serializer();

    inline for (.{ 10, 10.0, "foo", .bar, {}, null, @as(?bool, true) }) |v| {
        try getty.serialize(null, v, ss);

        std.debug.print("\n", .{});
    }
}
```

```console title="Shell session"
$ zig build run
10
1.0e+01
"foo"
"bar"
null
null
true
```

Easy peasy! :tada:

??? tip "Type Validation"

    You don't need to validate the `value` parameter of the `serialize*` methods.

    Getty ensures that an appropriate type will be passed to each function. For
    example, strings will be passed to `serializeString`, and integers and
    floating-points will be passed to `serializeNumber`.

??? tip "Method Reuse"

    You can use the same function to implement multiple required methods.

    For example, we used `serializeNumber` to implement `serializeInt` and
    `serializeFloat`. We also used `serializeNothing` to implement
    `serializeNull` and `serializeVoid`.

??? tip "Private Methods"

    Method implementations can be kept private.

    By marking them private, we avoid polluting the public API of `Serializer`
    with interface-related code. Additionally, we ensure that users cannot
    mistakenly use a value of the implementing type to perform serialization.
    Instead, they will always be forced to use a
    [`getty.Serializer`](https://docs.getty.so/#A;getty:Serializer) interface
    value.

## Aggregate Serialization

Now let's take a look at serialization for aggregate types.

If you'll recall,
[`getty.Serializer`](https://docs.getty.so/#A;getty:Serializer) required three
associated types from its implementations: `Seq`, `Map`, and `Structure`. These
types must implement an aggregate serialization interface:

!!! info ""

    [`getty.ser.Seq`](https://docs.getty.so/#A;getty:ser.Seq)

    :  Serializes the elements of and ends the serialization process for _Getty Sequences_.

    [`getty.ser.Map`](https://docs.getty.so/#A;getty:ser.Map)

    :  Serializes the keys and values of and ends the serialization process for _Getty Maps_.

    [`getty.ser.Structure`](https://docs.getty.so/#A;getty:ser.Structure)

    :  Serializes the fields of and ends the serialization process for _Getty Structures_.

The reason why we need `Seq`, `Map`, and `Structure` is because aggregate types
have all kinds of different access and iteration patterns, but Getty can't
possibly know about all of them. As a result, the aggregate serialization methods
(e.g., `serializeSeq`) are responsible only for _starting_ the serialization
process, before returning a value of either `Seq`, `Map`, or `Structure`. The
returned value is then used by the caller to finish serialization in whatever
way they want.

To give you an example of what I mean, let's implement the `serializeSeq`
method, which returns a value of type `Seq`, which is expected to implement the
[`getty.ser.Seq`](https://docs.getty.so/#A;getty:ser.Seq) interface.

??? info "getty.ser.Seq"

    ```zig title="Zig code"
    // (1)!
    fn Seq(
        comptime Context: type,

        // (2)!
        comptime O: type,
        comptime E: type,

        comptime methods: struct {
            serializeElement: ?fn (Context, anytype) E!void = null,
            end: ?fn (Context) E!O = null,
        },
    ) type
    ```

    1.  A `Seq` is responsible for serializing the elements of a _Sequence_ and ending the serialization process for a _Sequence_.

    2.  `O` and `E` must match the `O` and `E` values of a corresponding `Serializer`.

```zig title="<code>src/main.zig</code>" hl_lines="12 23 55-59 62-94 100-106"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        null,
        Seq,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeVoid = serializeNothing,
            .serializeString = serializeString,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
            .serializeSeq = serializeSeq,
        },
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: Context, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNumber(_: Context, value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNothing(_: Context) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeString(_: Context, value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeEnum(c: Context, _: anytype, name: []const u8) Error!Ok {
        try c.serializeString(name);
    }

    fn serializeSome(c: Context, value: anytype) Error!Ok {
        try getty.serialize(null, value, c.serializer());
    }

    // (2)!
    fn serializeSeq(_: Context, _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }
};

// (1)!
const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        Context,
        Ok,
        Error,
        .{
            .serializeElement = serializeElement,
            .end = end,
        },
    );

    const Context = *@This();
    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeElement(c: Context, value: anytype) Error!void {
        // Prefix element with a comma, if necessary.
        switch (c.first) {
            true => c.first = false,
            false => std.debug.print(",", .{}),
        }

        // Serialize element.
        try getty.serialize(null, value, (Serializer{}).serializer());
    }

    fn end(_: Context) Error!Ok {
        std.debug.print("]", .{});
    }
};

pub fn main() !void {
    const s = Serializer{};
    const ss = s.serializer();

    var list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer list.deinit();
    try list.append(1);
    try list.append(2);
    try list.append(3);

    try getty.serialize(null, list, ss);

    std.debug.print("\n", .{});
}
```


1.  This is our [`getty.ser.Seq`](https://docs.getty.so/#A;getty:ser.Seq) implementation.

    It specifies how to serialize the elements of and how to end the serialization process for _Sequences_.

2.  Here, we do two things:

    1. Begin serialization by printing `[`.
    2. Return a `Seq` value for the caller to use to finish off serialization.

<!--The above annotations need to be ordered like they are to avoid weirdness-->
<!--with the second list element in the interface type annotation.-->

```console title="Shell session"
$ zig build run
[1,2,3]
```

It worked!

And notice how we didn't have to write any code specific to the
[`std.ArrayList`](https://ziglang.org/documentation/master/std/#A;std:ArrayList)
type in `Serializer`. We simply specified how sequence serialization should start, how elements
should be serialized, and how serialization should end. And Getty took care of
the rest!

Okay, that leaves us with `serializeMap` and `serializeStruct`, which return
implementations of [`getty.ser.Map`](https://docs.getty.so/#A;getty:ser.Map) and
[`getty.ser.Structure`](https://docs.getty.so/#A;getty:ser.Structure),
respectively.

??? info "getty.ser.Map"

    ```zig title="Zig code"
    // (1)!
    fn Map(
        comptime Context: type,

        // (2)!
        comptime O: type,
        comptime E: type,

        comptime methods: struct {
            serializeKey: ?fn (Context, anytype) E!void = null,
            serializeValue: ?fn (Context, anytype) E!void = null,
            end: ?fn (Context) E!O = null,
        },
    ) type
    ```

    1.  A [`getty.ser.Map`](https://docs.getty.so/#A;getty:ser.Map) is responsible
        for serializing the keys and values of a _Map_ and ending the
        serialization process for a _Map_.

    2.  `O` and `E` must match the `O` and `E` values of a corresponding `Serializer`.

??? info "getty.ser.Structure"

    ```zig title="Zig code"
    // (1)!
    fn Structure(
        comptime Context: type,

        // (2)!
        comptime O: type,
        comptime E: type,

        comptime methods: struct {
            serializeField: ?fn (Context, comptime []const u8, anytype) E!void = null,
            end: ?fn (Context) E!O = null,
        },
    ) type
    ```

    1.  A `Structure` is responsible for serializing the fields of a _Structure_ and ending the serialization process for a _Structure_.

    2.  `O` and `E` must match the `O` and `E` values of a corresponding `Serializer`.

```zig title="<code>src/main.zig</code>" hl_lines="11 13 24-25 63-70 104-155 161-166"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        Map,
        Seq,
        Map,
        .{
            .serializeBool = serializeBool,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeVoid = serializeNothing,
            .serializeString = serializeString,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
            .serializeSeq = serializeSeq,
            .serializeMap = serializeMap,
            .serializeStruct = serializeStruct,
        },
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: Context, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNumber(_: Context, value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNothing(_: Context) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeString(_: Context, value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeEnum(c: Context, _: anytype, name: []const u8) Error!Ok {
        try c.serializeString(name);
    }

    fn serializeSome(c: Context, value: anytype) Error!Ok {
        try getty.serialize(null, value, c.serializer());
    }

    fn serializeSeq(_: Context, _: ?usize) Error!Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeMap(_: Context, _: ?usize) Error!Map {
        std.debug.print("{{", .{});
        return Map{};
    }

    fn serializeStruct(c: Context, comptime _: []const u8, len: usize) Error!Map {
        return try c.serializeMap(len);
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        Context,
        Ok,
        Error,
        .{
            .serializeElement = serializeElement,
            .end = end,
        },
    );

    const Context = *@This();
    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeElement(c: Context, value: anytype) Error!void {
        switch (c.first) {
            true => c.first = false,
            false => std.debug.print(",", .{}),
        }

        try getty.serialize(null, value, (Serializer{}).serializer());
    }

    fn end(_: Context) Error!Ok {
        std.debug.print("]", .{});
    }
};

const Map = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Map(
        Context,
        Ok,
        Error,
        .{
            .serializeKey = serializeKey,
            .serializeValue = serializeValue,
            .end = end,
        },
    );

    pub usingnamespace getty.ser.Structure(
        Context,
        Ok,
        Error,
        .{
            .serializeField = serializeField,
            .end = end,
        },
    );

    const Context = *@This();
    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeKey(c: Context, value: anytype) Error!void {
        switch (c.first) {
            true => c.first = false,
            false => std.debug.print(",", .{}),
        }

        try getty.serialize(null, value, (Serializer{}).serializer());
    }

    fn serializeValue(_: Context, value: anytype) Error!void {
        std.debug.print(":", .{});

        try getty.serialize(null, value, (Serializer{}).serializer());
    }

    fn serializeField(c: Context, comptime key: []const u8, value: anytype) Error!void {
        try c.serializeKey(key);
        try c.serializeValue(value);
    }

    fn end(_: Context) Error!Ok {
        std.debug.print("}}", .{});
    }
};

pub fn main() !void {
    const s = Serializer{};
    const ss = s.serializer();

    var map = std.StringHashMap(i32).init(std.heap.page_allocator);
    defer map.deinit();
    try map.put("x", 1);
    try map.put("y", 2);

    try getty.serialize(null, map, ss);

    std.debug.print("\n", .{});
}
```

```console title="Shell session"
$ zig build run
{"x":1,"y":2}
```

And there we go! Our serializer is complete! :tada:
