# Serializers

!!! warning "Prerequisites"

    This page assumes you know what __Getty Interfaces__ are and how they work.
    If not, see [here](/user-guide/design/interfaces/) before continuing.

Let's write a JSON serializer that serializes values by printing their JSON equivalent to `STDERR`.

## Scalar Serialization

Every Getty serializer implements the [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface, shown below.

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

1.  A `Serializer` serializes values from Getty's data model into a data format.

2.  `Context` is a namespace that owns the method implementations passed to the `methods` parameter.

    Usually, this is the type implementing [`getty.Serializer`](https://docs.getty.so/#root;Serializer) or a pointer to it if mutability is required.

3.  `O` is the successful return type for most of a `Serializer`'s methods.

4.  `E` is the error set returned by a `Serializer`'s methods upon failure.

    `E` must contain [`getty.ser.Error`](https://docs.getty.so/#root;ser.Error).

5.  `user_sbt` and `serializer_sbt` are optional user- and serializer-defined serialization blocks or tuples, respectively.

    They allow users and serializers to customize Getty's serialization behavior. If user- or serializer-defined customization isn't supported, you can pass in `null`.


6.  `Map`, `Seq`, and `Structure` are optional types that implement Getty's aggregate serialization interfaces.

    Those interfaces are [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map), [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq), and [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure). I'm sure you can figure out which parameters should implement which interfaces.

7.  `methods` contains all of the methods a `Serializer` must provide or can override.

Quite the parameter list!

Luckily, most of the parameters have default values we can use. So, let's start with this:

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

But let's try serializing a value with it anyways! We can do so by calling [`getty.serialize`](https://docs.getty.so/#root;serialize), which takes a value to serialize and a [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface value.

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

A compile error!

Looks like Getty can't serialize `bool`s unless `serializeBool` is implemented. Let's fix that.

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

Now let's do the same thing for `serializeEnum`, `serializeFloat`, `serializeInt`, `serializeNull`, `serializeSome`, `serializeString`, and `serializeVoid`.

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
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeString = serializeString,
            .serializeVoid = serializeNothing,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) Error!Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeNothing(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeSome(self: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, self.serializer());
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

And there we go!

We've made our initial `Serializer` implementation from before, but now with a bit of context!

??? tip "Method Reuse"

    You can use the same function to implement multiple required methods.

    For example, we used `serializeNumber` to implement `serializeInt` and `serializeFloat`. We also used `serializeNothing` to implement `serializeNull` and `serializeVoid`.

??? tip "Private Methods"

    Method implementations can be kept private.

    By marking them private, we avoid polluting the public API of `Serializer` with interface-related code. Additionally, we ensure that users cannot mistakenly use a value of the implementing type to perform serialization. Instead, they will always be forced to use a [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface value.

??? tip "Type Validation"

    You don't need to validate the `value` parameter of the `serialize*` methods.

    Getty ensures that an appropriate type will be passed to each function. For example, strings will be passed to `serializeString`, and integers and floating-points will be passed to `serializeNumber`.


## Aggregate Serialization

Now let's take a look at serialization for aggregate types.

If you'll recall, [`getty.Serializer`](https://docs.getty.so/#root;Serializer) required three associated types from its implementations: `Seq`, `Map`, and `Structure`. Each type is expected to implement one of Getty's aggregate serialization interfaces, which are [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq), [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) and [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure).

The reason we need `Seq`, `Map`, and `Structure` is because aggregate types
have all kinds of different access and iteration patterns, but Getty can't
possibly know about all of them. Therefore, the aggregate serialization methods
(e.g., `serializeSeq`) are responsible only for _starting_ the serialization
process, before returning a value of either `Seq`, `Map`, or `Structure`. The
returned value is then used by the caller to finish serialization in whatever
way they want.

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

    1.  A `Seq` is responsible for serializing the elements of a _Sequence_ and ending the serialization process for a _Sequence_.

    2.  `O` and `E` must match the `O` and `E` values of a corresponding `Serializer`.

```zig title="<code>src/main.zig</code>" hl_lines="12 23 54-60 63-94 99-105"
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
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeString = serializeString,
            .serializeVoid = serializeNothing,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
            .serializeSeq = serializeSeq,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    fn serializeNothing(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeSome(s: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, s.serializer());
    }

    // (1)!
    fn serializeSeq(_: @This(), len: ?usize) Error!Seq {
        _ = len;

        std.debug.print("[", .{});
        return Seq{};
    }
};

// (2)!
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
        // Prefix element with a comma, if necessary.
        switch (s.first) {
            true => s.first = false,
            false => std.debug.print(",", .{}),
        }

        // Serialize value.
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

1.  All we do here is begin serialization by printing `[` and then return a `Seq` for the caller to use.

2.  This is our [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq) implementation.

    It specifies how to serialize the elements of and how to end the serialization process for _Sequences_.

```console title="Shell session"
$ zig build run
[1,2,3]
```

Success!

Notice how we didn't have to write any code specific to the
[`std.ArrayList`](https://ziglang.org/documentation/master/std/#root;ArrayList)
type in `Serializer`. We simply specified how sequence serialization should start, how elements
should be serialized, and how serialization should end. And Getty took care of
the rest!

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

```zig title="<code>src/main.zig</code>" hl_lines="11 13 24-25 62-73 106-156 161-166"
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
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeString = serializeString,
            .serializeVoid = serializeNothing,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
            .serializeSeq = serializeSeq,
            .serializeMap = serializeMap,
            .serializeStruct = serializeStruct,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    fn serializeNothing(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    fn serializeSome(self: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeSeq(_: @This(), _: ?usize) Error!Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeMap(_: @This(), len: ?usize) Error!Map {
        _ = len;

        std.debug.print("{{", .{});
        return Map{};
    }

    fn serializeStruct(self: @This(), comptime name: []const u8, len: usize) Error!Map {
        _ = name;

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

```console title="Shell session"
$ zig build run
{"x":1,"y":2}
```

Hooray!

Our JSON serializer is now complete!
