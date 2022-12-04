---
title: Serializers
category: Guide
layout: default
permalink: /guide/serializers/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Serializers

Let's write a JSON serializer that serializes values by printing their JSON equivalent to `STDERR`. Note that any code we write will be in `src/main.zig` and will be labeled as such.


## Scalar Serialization

Every Getty serializer must implement the [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface, shown below.

{% label Zig code %}
{% highlight zig %}
// getty.Serializer specifies the behavior of a serializer, and must be
// implemented by all Getty serializers.
fn Serializer(
    // Context is the namespace that owns the method implementations you want
    // to use to implement getty.Serializer.
    //
    // Usually, this is whatever type is implementing getty.Serializer (or a
    // pointer to it if mutability is required in your method implementations).
    comptime Context: type,

    // O is the return type for most of getty.Serializer's methods.
    comptime O: type,

    // E is the error set returned by getty.Serializer's methods upon failure.
    comptime E: type,

    // user_sbt and serializer_sbt are user- and serializer- defined
    // Serialization Blocks or Tuples (SBT), respectively.
    //
    // SBTs define Getty's serialization behavior. If user- or serializer-
    // defined customization is not supported or needed by your serializer,
    // you can pass in null for these parameters.
    //
    // You can ignore these parameters for now. We'll come back to them later.
    comptime user_sbt: anytype,
    comptime serializer_sbt: anytype,

    // Map, Seq, and Structure are types that implement Getty's aggregate
    // serialization interfaces.
    //
    // The aggregate serialization interfaces are getty.ser.Map, getty.ser.Seq,
    // and getty.ser.Structure. I'm sure you can figure out which interfaces
    // are expected to be implemented by which parameters.
    //
    // If you don't want to support serialization for aggregate types or you
    // just haven't implemented it yet, you can pass in null for these parameters.
    comptime Map: ?type,
    comptime Seq: ?type,
    comptime Structure: ?type,

    // methods contains every method that getty.Serializer implementations can
    // implement.
    //
    // In this tutorial, we'll be providing implementations for all of
    // these methods. However, if you don't want to implement a specific
    // method, you can simply omit its corresponding field.
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
{% endhighlight %}
{% endlabel %}

Quite the parameter list!

Luckily though, most of the parameters seem to have default values we can use, so let's kick things off with the following implementation.

{% label src/main.zig %}
{% highlight zig %}
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
    const Error = error{};
};
{% endhighlight %}
{% endlabel %}

Quite a useless serializer, but let's try serializing a value with it anyway. We can do so by calling [`getty.serialize`](https://docs.getty.so/#root;serialize), which takes a value to serialize and a [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface value.

{% label src/main.zig %}
{% highlight zig %}
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
    const Error = error{};
};

// 👇
pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
[...] error: serializeBool is not implemented by type: main.Serializer
{% endhighlight %}
{% endlabel %}

Oh no, a compile error!

Looks like Getty can't serialize `bool` values for us unless the `serializeBool` method has been implemented. So, let's go ahead and do that.

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std"); // 👈
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
            .serializeBool = serializeBool, // 👈
        },
    );

    const Ok = void;
    const Error = error{};

    // 👇
    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);

    // 👇
    std.debug.print("\n", .{});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
true
{% endhighlight %}
{% endlabel %}

Success!

Now let's do the exact same thing for `serializeEnum`, `serializeFloat`, `serializeInt`, `serializeNull`, `serializeSome`, `serializeString`, and `serializeVoid`.

{% label src/main.zig %}
{% highlight zig %}
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
            .serializeEnum = serializeEnum,     // 👈
            .serializeFloat = serializeNumber,  // 👈
            .serializeInt = serializeNumber,    // 👈
            .serializeNull = serializeNull,     // 👈
            .serializeSome = serializeSome,     // 👈
            .serializeString = serializeString, // 👈
            .serializeVoid = serializeNull,     // 👈
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    // 👇
    fn serializeEnum(self: @This(), value: anytype) Error!Ok {
        try self.serializeString(@tagName(value));
    }

    // 👇
    fn serializeNull(_: @This()) Error!Ok {
        std.debug.print("null", .{});
    }

    // 👇
    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    // 👇
    fn serializeSome(self: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, self.serializer());
    }

    // 👇
    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    // 👇
    inline for (.{ 10, 10.0, "string", .variant, {}, null }) |v| {
        try getty.serialize(v, s);

        std.debug.print("\n", .{});
    }
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
10
1.0e+01
"string"
"variant"
null
null
{% endhighlight %}
{% endlabel %}

And there we have it! Our initial `Serializer` implementation from the intro! But now with context!

At this point, the only methods left to implement are those related to aggregate serialization. However, before we move on, I want to highlight out a few things about our `Serializer` type:

- Because the signatures of the `serializeFloat` and `serializeInt` methods are the same, we were able to implement them both using one function: `serializeNumber`. We were also able to do the same thing for `serializeNull` and `serializeVoid`.

- By keeping all of our method implementations private, we avoided polluting the public API of `Serializer` with interface-related code. Additionally, we've ensured that users cannot mistakenly use a `Serializer` value instead of an interface value to perform serialization.

- Even though the type of the `value` parameter for many of our methods is `anytype`, we didn't perform any type validation. That is because Getty ensures that an appropriate type will be passed to each function. For example, strings will be passed to `serializeString` and integers and floating-points will be passed to `serializeNumber`.


## Aggregate Serialization

Alright, let's move on to serialization for aggregate types!

Among the parameters of the [`getty.Serializer`](https://docs.getty.so/#root;Serializer) interface are the `Map`, `Seq`, and `Structure` types. So far, we've just been passing in `null` for these parameters. But now we need to update them in order to do aggregate serialization.

The reason we need these parameters is because aggregate types have all kinds of different access and iteration patterns, but Getty can't possibly know about all of them. As such, serialization methods like `serializeMap` are only responsible for _starting_ the serialization process, before returning a value of either `Map`, `Seq`, or `Structure`. The returned value is then used by the caller to finish off serialization.

To give you an example of what I mean, let's implement the `serializeSeq` method, which returns a value of type `Seq`, which is expected to implement the [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq) interface.

{% label Zig code %}
{% highlight zig %}
// getty.ser.Seq specifies how to serialize the elements of a Getty Sequence,
// as well as how to end the serialization process for a Getty Sequence.
//
// The O and E values of a getty.ser.Seq implementation must match the O and E
// values of a corresponding getty.Serializer implementation.
fn Seq(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeElement: ?fn (Context, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type
{% endhighlight %}
{% endlabel %}

{% label src/main.zig %}
{% highlight zig %}
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
        Seq, // 👈
        null,
        .{
            .serializeBool = serializeBool,
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNull,
            .serializeSeq = serializeSeq, // 👈
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeVoid = serializeNull,
        },
    );

    const Ok = void;
    const Error = error{};

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

    // 👇
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

// 👇
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
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("]", .{});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    // 👇
    var list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer list.deinit();
    try list.append(1);
    try list.append(2);
    try list.append(3);

    // 👇
    try getty.serialize(list, s);

    std.debug.print("\n", .{});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
[1, 2, 3]
{% endhighlight %}
{% endlabel %}

Hooray!

If you'll notice, we didn't have to write any iteration- or access-related code specific to the `std.ArrayList` type. All we did was specify how sequence serialization should start, how elements should be serialized, and how serialization should end. And Getty took care of the rest!

Alright, that leaves us with `serializeMap` and `serializeStruct`, which return implementations of [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) and [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure), respectively.

{% label Zig code %}
{% highlight zig %}
// getty.ser.Map specifies how to serialize the keys and values of a Getty Map,
// as well as how to end the serialization process for a Getty Map.
//
// The O and E values of a getty.ser.Map implementation must match the O and E
// values of a corresponding getty.Serializer implementation.
fn Map(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeKey: ?fn (Context, anytype) E!void = null,
        serializeValue: ?fn (Context, anytype) E!void = null,
        end: ?fn (Context) E!O = null,

        // Provided method.
        serializeEntry: ?fn (Context, anytype, anytype) E!void = null,
    },
) type
{% endhighlight %}
{% endlabel %}

{% label Zig code %}
{% highlight zig %}
// getty.ser.Structure specifies how to serialize the fields of a Getty Structure,
// as well as how to end the serialization process for a Getty Structure.
//
// The O and E values of a getty.ser.Structure implementation must match the O
// and E values of a corresponding getty.Serializer implementation.
fn Structure(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeField: ?fn (Context, comptime []const u8, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type
{% endhighlight %}
{% endlabel %}

{% label src/main.zig %}
{% highlight zig %}
{% raw %}
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        Map, // 👈
        Seq,
        Map, // 👈
        .{
            .serializeBool = serializeBool,
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeMap = serializeMap,       // 👈
            .serializeNull = serializeNull,
            .serializeSeq = serializeSeq,
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeStruct = serializeStruct, // 👈
            .serializeVoid = serializeNull,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    // 👇
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

    // 👇
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
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("]", .{});
    }
};

// 👇
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
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeValue(_: *@This(), value: anytype) Error!void {
        std.debug.print(": ", .{});

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

    // 👇
    try getty.serialize(.{ .x = 1, .y = 2 }, s);

    std.debug.print("\n", .{});
}
{% endraw %}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
{"x": 1, "y": 2}
{% endhighlight %}
{% endlabel %}

Huzzah! Our JSON serializer is now complete!
