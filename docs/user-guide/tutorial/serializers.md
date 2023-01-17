# Serializers

We'll write a JSON serializer that serializes values by printing their JSON equivalent to `STDERR`.

!!! warning "Prerequisites"

    This page assumes you understand what __Getty Interfaces__ are and how they
    work. If not, see [here](/user-guide/design/interfaces/) before continuing.

## Scalar Serialization

Every Getty serializer must implement the
[`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface, shown
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
        // (8)!
        serializeBool: ?fn (Context, bool) E!O = null,
        serializeEnum: ?fn (Context, anytype) E!O = null,
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

1.  A [`getty.Serializer`](https://docs.getty.so/#root;Serializer) serializes
    values from Getty's data model.

2.  `Context` is a namespace that owns the method implementations passed to the
    `methods` parameter.

    Usually, this is the type implementing
    [`getty.Serializer`](https://docs.getty.so/#root;Serializer) or a pointer
    to it if mutability is required.

3.  `O` is the successful return type for most of
    [`getty.Serializer`](https://docs.getty.so/#root;Serializer)'s methods.

4.  `E` is the error set returned by
    [`getty.Serializer`](https://docs.getty.so/#root;Serializer)'s methods upon
    failure.

    The value of `E` must contain
    [`getty.ser.Error`](https://docs.getty.so/#root;ser.Error), a base error
    set defined by Getty.

5.  `user_sbt` and `serializer_sbt` are optional user- and serializer-defined
    serialization blocks or tuples, respectively.

    They allow users and serializers to customize Getty's serialization
    behavior. If user- or serializer-defined customization isn't supported,
    you can pass in `null` for these parameters.


6.  `Map`, `Seq`, and `Structure` are optional types that implement Getty's
    aggregate serialization interfaces.

    The aggregate serialization interfaces are
    [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map),
    [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq), and
    [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure). I'm
    sure you can figure out which parameters should implement which interfaces.

    If you don't want to support serialization for aggregate types or if you
    simply haven't implemented it yet, you can pass in `null` for these
    parameters.

7.  `methods` contains all of the methods that implementations of
    [`getty.Serializer`](https://docs.getty.so/#root;Serializer) must provide
    or can override.

8.  These methods are responsible for serializing a value in Getty's data
    model into a data format.

Quite the parameter list!

Luckily, most of the parameters have default values we can use. So, let's
start with the following:

```zig title="<code>src/main.zig</code>"
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{},
    );

    const Ok = void;
    const Error = getty.ser.Error;
};
```

Kind of a useless serializer...

But let's try serializing a value with it anyways! We can do so by calling
[`getty.serialize`](https://docs.getty.so/#root;serialize), which takes a value
to serialize and a [`getty.Serializer`](https://docs.getty.so/#root;Serializer)
interface value.

```zig title="<code>src/main.zig</code>" hl_lines="20-24"
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{},
    );

    const Ok = void;
    const Error = getty.ser.Error;
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);
}
```

```console title="Shell session"
$ zig build run
[...] error: serializeBool is not implemented by type: main.Serializer
```

Oh no, a compile error!

Looks like Getty can't serialize `bool` values unless `serializeBool` is implemented.

```zig title="<code>src/main.zig</code>" hl_lines="1 14-16 22-24 32"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
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

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);

    std.debug.print("\n", .{});
}
```

```console title="Shell session"
$ zig build run
true
```

Success!

Now let's do the same thing for `serializeEnum`, `serializeFloat`,
`serializeInt`, `serializeNull`, `serializeSome`, `serializeString`, and
`serializeVoid`.

```zig title="<code>src/main.zig</code>" hl_lines="16-22 33-51 57-61"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNull,
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeVoid = serializeNull,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) Error!Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSome(self: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    inline for (.{ 10, 10.0, "string", .variant, {}, null }) |v| {
        try getty.serialize(v, s);

        std.debug.print("\n", .{});
    }
}
```

```console title="Shell session"
$ zig build run
10
1.0e+01
"string"
"variant"
null
null
```

And there we have it! Our initial `Serializer` implementation, but now with a
bit of context!

??? tip "Method Reuse"

    Since the signatures of the `serializeFloat` and `serializeInt` methods are
    the same, we were able to implement both of them using one function:
    `serializeNumber`. We were also able to do the same thing for
    `serializeNull` and `serializeVoid`.

??? tip "Private Methods"

    By keeping all of our method implementations private, we avoid polluting
    the public API of `Serializer` with interface-related code. Additionally,
    we ensure that users cannot mistakenly use a `Serializer` value instead of
    an interface value to perform serialization.

??? tip "Type Validation"

    Even though the type of the `value` parameter for many of our methods is
    `anytype`, we didn't perform any type validation. That's because
    Getty ensures that an appropriate type will be passed to each function. For
    example, strings will be passed to `serializeString` and integers and
    floating-points will be passed to `serializeNumber`.


## Aggregate Serialization

Alright, now let's take a look at serialization for aggregate types.

If you'll recall, the
[`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface requires
three associated types from its implementations: `Seq`, `Map`, and `Structure`.
These are optional types that impelement the
[`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq),
[`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) and
[`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure) interfaces,
respectively.

Why do we need these parameters to create a serializer? Well, because aggregate
types have all kinds of different access and iteration patterns, but Getty
can't possibly know about all of them. As such, aggregate serialization methods
like `serializeMap` are only responsible for _starting_ the serialization
process, before returning a value of either `Map`, `Seq`, or `Structure`
(depending on which method was called). The returned value is then used by the
caller to finish off serialization.

To give you an example of what I mean, let's implement the `serializeSeq`
method, which returns a value of type `Seq`, which is expected to implement the
[`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq) interface.

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

    1.  A [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq) is responsible
        for serializing the elements of a _Sequence_ and ending the
        serialization process for a _Sequence_.

    2.  The value of these parameters must match the `O` and `E` values of a
        corresponding
        [`getty.Serializer`](https://docs.getty.so/#root;Serializer)
        implementation.

```zig title="<code>src/main.zig</code>" hl_lines="12 20 46-51 62-90 95-101"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        null,
        Seq,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNull,
            .serializeSeq = serializeSeq,
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeVoid = serializeNull,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    // (1)!
    fn serializeSeq(_: @This(), _: ?usize) Error!Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeSome(s: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, s.serializer());
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Ok,
        Error,
        .{
            .serializeElement = serializeElement,
            .end = end,
        },
    );

    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeElement(s: *@This(), value: anytype) Error!void {
        switch (s.first) {
            true => s.first = false,
            false => std.debug.print(",", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("]", .{});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    var list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer list.deinit();
    try list.append(1);
    try list.append(2);
    try list.append(3);

    try getty.serialize(list, s);

    std.debug.print("\n", .{});
}
```

1. The 2^nd^ parameter of `serializeSeq` is an optional length for the
   _Sequence_ being serialized.

```console title="Shell session"
$ zig build run
[1,2,3]
```

Hooray!

If you'll notice, we didn't have to write any iteration- or access-related code
specific to the `std.ArrayList` type. All we had to do was specify how sequence
serialization should start, how elements should be serialized, and how
serialization should end. And Getty took care of the rest!

Okay, that leaves us with `serializeMap` and `serializeStruct`, which return
implementations of [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) and
[`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure),
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

    1.  A [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) is responsible
        for serializing the keys and values of a _Map_ and ending the
        serialization process for a _Map_.

    2.  The value of these parameters must match the `O` and `E` values of a
        corresponding
        [`getty.Serializer`](https://docs.getty.so/#root;Serializer)
        implementation.

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

    1.  A [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure) is
        responsible for serializing the fields of a _Structure_ and ending the
        serialization process for a _Structure_.

    2.  The value of these parameters must match the `O` and `E` values of a
        corresponding
        [`getty.Serializer`](https://docs.getty.so/#root;Serializer)
        implementation.

```zig title="<code>src/main.zig</code>" hl_lines="11 13 19 24 40-45 69-72 105-155 160-165"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        Map,
        Seq,
        Map,
        .{
            .serializeBool = serializeBool,
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeMap = serializeMap,
            .serializeNull = serializeNull,
            .serializeSeq = serializeSeq,
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeStruct = serializeStruct,
            .serializeVoid = serializeNull,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    // (1)!
    fn serializeMap(_: @This(), _: ?usize) Error!Map {
        std.debug.print("{{", .{});

        return Map{};
    }

    fn serializeNull(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: @This(), _: ?usize) Error!Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeSome(self: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    // (2)!
    fn serializeStruct(self: @This(), comptime _: []const u8, len: usize) Error!Map {
        return try self.serializeMap(len);
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Ok,
        Error,
        .{
            .serializeElement = serializeElement,
            .end = end,
        },
    );

    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeElement(self: *@This(), value: anytype) Error!void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(",", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("]", .{});
    }
};

const Map = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Map(
        *@This(),
        Ok,
        Error,
        .{
            .serializeKey = serializeKey,
            .serializeValue = serializeValue,
            .end = end,
        },
    );

    pub usingnamespace getty.ser.Structure(
        *@This(),
        Ok,
        Error,
        .{
            .serializeField = serializeField,
            .end = end,
        },
    );

    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeKey(self: *@This(), value: anytype) Error!void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(",", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeValue(_: *@This(), value: anytype) Error!void {
        std.debug.print(":", .{});

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeField(self: *@This(), comptime key: []const u8, value: anytype) Error!void {
        try self.serializeKey(key);
        try self.serializeValue(value);
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("}}", .{});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    var map = std.StringHashMap(i32).init(std.heap.page_allocator);
    defer map.deinit();
    try map.put("x", 1);
    try map.put("y", 2);

    try getty.serialize(map, s);

    std.debug.print("\n", .{});
}
```

1. The 2^nd^ parameter of `serializeMap` is an optional length for the
   _Map_ being serialized.

1. The 2^nd^ parameter of `serializeStruct` is the name that should be used
   for the _Structure_ being serialized.

```console title="Shell session"
$ zig build run
{"x":1,"y":2}
```

And there we go! Our JSON serializer is now complete!
