---
title: Serializers
category: Guide
layout: default
permalink: /guide/serializers/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Serializers

In this section, we will write a simple JSON serializer that serializes values by printing their JSON equivalent to `STDERR`. Any code we write will be in `src/main.zig` and will be labeled as such.

Every Getty serializer is required to implement the `getty.Serializer` interface, shown below.

{% label Zig code %}
{% highlight zig %}
// getty.Serializer specifies the behavior of a serializer, and must be
// implemented by all Getty serializers.
fn Serializer(
    // Context is a namespace that contains the method implementations you want
    // to use to implement getty.Serializer.
    //
    // Typically, this is whatever type is implementing getty.Serializer (or a
    // pointer to it if mutability is required in your method implementations).
    comptime Context: type,

    // Ok is the return type for most of getty.Serializer's required methods.
    comptime Ok: type,

    // Error is the error set returned by getty.Serializer's required methods
    // upon failure.
    comptime Error: type,

    // user_sbt and ser_sbt are user- and serializer- defined Serialization
    // Blocks or Tuples (SBT), respectively.
    //
    // SBTs define Getty's serialization behavior. The default serialization
    // behavior of Getty is defined as getty.default_st and should be set for
    // user_sbt or ser_sbt if user- or serializer-defined customization is not
    // supported or needed.
    comptime user_sbt: anytype,
    comptime ser_sbt: anytype,

    // Map, Seq, and Structure are types that implement Getty's compound
    // serialization interfaces.
    //
    // The compound serialization interfaces are getty.ser.Map, getty.ser.Seq,
    // and getty.ser.Structure. I'm sure you can figure out which interfaces
    // are expected to be implemented by which parameters.
    //
    // If you don't want to support serialization for compound types or you
    // just haven't implemented it yet, you should assign the getty.TODO type
    // to Map, Seq, and Structure.
    comptime Map: type,
    comptime Seq: type,
    comptime Structure: type,

    // These are methods that getty.Serializer implementations must provide.
    //
    // For this tutorial, we'll be providing implementations for all of
    // these methods. However, you can always set any of the required methods
    // to `undefined` if you don't want to support a specific behavior.
    comptime serializeBool: fn (Context, bool) Error!Ok,
    comptime serializeEnum: fn (Context, anytype) Error!Ok,
    comptime serializeFloat: fn (Context, anytype) Error!Ok,
    comptime serializeInt: fn (Context, anytype) Error!Ok,
    comptime serializeMap: fn (Context, ?usize) Error!Map,
    comptime serializeNull: fn (Context) Error!Ok,
    comptime serializeSeq: fn (Context, ?usize) Error!Seq,
    comptime serializeSome: fn (Context, anytype) Error!Ok,
    comptime serializeString: fn (Context, anytype) Error!Ok,
    comptime serializeStruct: fn (Context, comptime []const u8, usize) Error!Structure,
    comptime serializeVoid: fn (Context) Error!Ok,
) type
{% endhighlight %}
{% endlabel %}

Quite the parameter list!

Luckily though, most of the parameters seem to have default values we can use, so go ahead and replace the contents of `src/main.zig` with the following `getty.Serializer` implementation:

{% label src/main.zig %}
{% highlight zig %}
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        getty.TODO,
        getty.TODO,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };
};
{% endhighlight %}
{% endlabel %}

Congratulations! You've just written your first Getty serializer!

Let's try to serialize something with it by calling `getty.serialize`, which takes a value to serialize and a `getty.Serializer` interface value (i.e., a value of the interface type):

{% label src/main.zig %}
{% highlight zig %}
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        getty.TODO,
        getty.TODO,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };
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
[...] error: use of undefined value here causes undefined behavior
  return try serializeBool(self.context, value);
             ^
{% endhighlight %}
{% endlabel %}

A compile error!

What happened was that Getty saw we were trying to serialize a `bool` value and so it called the `serializeBool` method of the interface value we passed in. That method then tried to call the `serializeBool` parameter of the `getty.Serializer` interface, which our `Serializer` implementation was supposed to provide. However, since we set all of the required methods to `undefined`, the compiler kindly reminded us about the dangers of using undefined values.

To fix this, all we have to do is provide a method implementation for `serializeBool`.

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std"); // 👈
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        getty.TODO,
        getty.TODO,
        serializeBool, // 👈
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    // 👇
    fn serializeBool(_: @This(), value: bool) !Ok {
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

Now let's do the same thing for `serializeEnum`, `serializeFloat`, `serializeInt`, `serializeNull`, `serializeSome`, `serializeString`, and `serializeVoid`.

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        getty.TODO,
        getty.TODO,
        serializeBool,
        serializeEnum,   // 👈
        serializeNumber, // 👈
        serializeNumber, // 👈
        undefined,
        serializeNull,   // 👈
        undefined,
        serializeSome,   // 👈
        serializeString, // 👈
        undefined,
        serializeNull,   // 👈
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}", .{value});
    }

    // 👇
    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    // 👇
    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null", .{});
    }

    // 👇
    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}", .{value});
    }

    // 👇
    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    // 👇
    fn serializeString(_: @This(), value: anytype) !Ok {
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

At this point, the only methods left to implement are those related to compound serialization. However, before we move on, I want to highlight out a few things about our `Serializer` type:

- By keeping all of our method implementations private, we avoid polluting the public API of `Serializer` with interface-related code. Additionally, we've ensured that users cannot mistakenly use a `Serializer` value instead of an interface value to perform serialization.

- Because the signatures of the `serializeFloat` and `serializeInt` required methods are the same, we were able to implement them both using one function: `serializeNumber`. We were also able to do the same thing for `serializeNull` and `serializeVoid`.

- Even though the type of the `value` parameter for many of the required methods is `anytype`, we didn't perform any type validation. That is because Getty ensures that an appropriate type will be passed to each function. For example, strings will be passed to `serializeString` and integers and floating-points will be passed to `serializeNumber`. In other words, you'll never have to type-check the `value` parameter unless you wish to further restrict its type.

Alright, let's move on to compound serialization. Remember the `Map`, `Seq`, and `Structure` parameters of `getty.Serializer`? Well, the reason they exist is because compound types have different access and iteration patterns, but Getty can't possibly know about all of them. To solve this, compound serialization methods (e.g., `serializeSeq`) are only responsible for _starting_ the serialization process before returning a value of either `Map`, `Seq`, or `Structure`. The returned value is then used by the method's caller to finish off serialization.

To help you understand what I mean, let's implement the `serializeSeq` required method, which returns a value of type `Seq`, which is expected to implement the `getty.ser.Seq` interface.

{% label Zig code %}
{% highlight zig %}
// getty.ser.Seq specifies how to serialize the elements of a Getty Sequence,
// as well as how to end the serialization process for a Getty Sequence.
//
// The Ok and Error values of a getty.ser.Seq implementation must match the
// Ok and Error values of its corresponding getty.Serializer implementation.
fn Seq(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeElement: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
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
        getty.default_st,
        getty.default_st,
        getty.TODO,
        Seq,          // 👈
        getty.TODO,
        serializeBool,
        serializeEnum,
        serializeNumber,
        serializeNumber,
        undefined,
        serializeNull,
        serializeSeq, // 👈
        serializeSome,
        serializeString,
        undefined,
        serializeNull,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}", .{value});
    }

    // 👇
    fn serializeSeq(_: @This(), _: ?usize) !Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("\"{s}\"", .{value});
    }
};

// 👇
const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(self: *@This(), value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) !Serializer.Ok {
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

If you'll notice, we didn't have to write any iteration- or access-related code. We simply specified how sequence elements should be serialized and how sequence serialization should end, and Getty took care of the rest!

All that is left is `serializeMap` and `serializeStruct`. Think you can handle them yourself?

{% label Zig code %}
{% highlight zig %}
// getty.ser.Map specifies how to serialize the keys and values of a Getty Map,
// as well as how to end the serialization process for a Getty Map.
//
// The Ok and Error values of a getty.ser.Map implementation must match the
// Ok and Error values of its corresponding getty.Serializer implementation.
fn Map(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeKey: fn (Context, anytype) Error!void,
    comptime serializeValue: fn (Context, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type
{% endhighlight %}
{% endlabel %}

{% label Zig code %}
{% highlight zig %}
// getty.ser.Structure specifies how to serialize the fields of a Getty Structure,
// as well as how to end the serialization process for a Getty Structure.
//
// The Ok and Error values of a getty.ser.Structure implementation must match
// the Ok and Error values of its corresponding getty.Serializer implementation.
fn Structure(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeField: fn (Context, comptime []const u8, anytype) Error!void,
    comptime end: fn (Context) Error!Ok,
) type
{% endhighlight %}
{% endlabel %}

Did you implement them yet?

<br>

You _are_ trying to implement them, right?

<br>

You wouldn't lie to me about that, would you?

<br>

_Right?_

<br>

You better not be lying to me.

<br>

This is your last chance.

<br>

. . .

<br>

Okay, here's how I did it.

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
        getty.default_st,
        getty.default_st,
        Map,             // 👈
        Seq,
        Map,             // 👈
        serializeBool,
        serializeEnum,
        serializeNumber,
        serializeNumber,
        serializeMap,    // 👈
        serializeNull,
        serializeSeq,
        serializeSome,
        serializeString,
        serializeStruct, // 👈
        serializeNull,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    // 👇
    fn serializeMap(_: @This(), _: ?usize) !Map {
        std.debug.print("{{", .{});

        return Map{};
    }

    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: @This(), _: ?usize) !Seq {
        std.debug.print("[", .{});

        return Seq{};
    }

    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    // 👇
    fn serializeStruct(self: @This(), comptime _: []const u8, len: usize) !Map {
        return try self.serializeMap(len);
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(self: *@This(), value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) !Serializer.Ok {
        std.debug.print("]", .{});
    }
};

// 👇
const Map = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Map(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeKey,
        serializeValue,
        end,
    );

    pub usingnamespace getty.ser.Structure(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeField,
        end,
    );

    fn serializeKey(self: *@This(), value: anytype) !void {
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeValue(_: *@This(), value: anytype) !void {
        std.debug.print(": ", .{});

        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn serializeField(self: *@This(), comptime key: []const u8, value: anytype) !void {
        try self.serializeKey(key);
        try self.serializeValue(value);
    }

    fn end(_: *@This()) !Serializer.Ok {
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

Well done! &nbsp; 🎉
