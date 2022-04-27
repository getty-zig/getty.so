---
title: Serializers
category: Guide
layout: default
permalink: /guide/serializers/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Serializers

In this section, we will write a simple JSON serializer that serializes values by printing their JSON equivalent to `STDERR`. Any code we write will go into `src/main.zig` and will be labeled as such.

The first step in creating a Getty (de)serializer is learning which interfaces need to be implemented. For serializers, the interface we need to implement is `getty.Serializer`, which is shown below.

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
    //
    // We'll talk more about SBTs later on, so just ignore them for now.
    comptime user_sbt: anytype,
    comptime ser_sbt: anytype,

    // Map, Seq, and Structure are types that implement Getty's compound
    // serialization interfaces.
    //
    // The compound serialization interfaces are getty.ser.Map, getty.ser.Seq,
    // and getty.ser.Structure. I'm sure you can figure out which interfaces
    // are expected to be implemented by which parameters.
    //
    // The reason getty.Serializer needs these types is because serialization
    // for compound types is slightly different compared to serialization for
    // non-compound types. Specifically, compound types aren't fully serialized
    // by their associated serialization methods (e.g., serializeMap). Instead,
    // the methods just start the serialization process before returning a
    // value of either Map, Seq, or Struct. The returned value is then used by
    // each method's caller to finish off serialization.
    //
    // If you don't support serialization for compound types or you simply
    // haven't implemented it yet, you can use the getty.TODO type for Map,
    // Seq, and Structure.
    comptime Map: type,
    comptime Seq: type,
    comptime Structure: type,

    // These are methods that getty.Serializer implementations must provide.
    //
    // For this tutorial, we'll be providing implementations for all of
    // these methods. However, you always can set any of the required methods
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

Quite the parameter list! I assure you though that implementing the interface is actually quite simple. For example, replace the contents of `src/main.zig` with the following:

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

Congratulations! You've just written your first Getty serializer! That's right, `Serializer` is a fully functional (though completely useless) Getty serializer. In fact, why don't we try to serialize something with it by calling `getty.serialize`, which takes a value to serialize and a `getty.Serializer` interface value.

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

To fix this problem, all we have to do is provide a method implementation for `serializeBool`:

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

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}\n", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);
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
        serializeEnum,
        serializeNumber,
        serializeNumber,
        undefined,
        serializeNull,
        undefined,
        serializeSome,
        serializeString,
        undefined,
        serializeNull,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null\n", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("\"{s}\"\n", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();
    const values = .{ true, 10, 10.0, "string", .variant, {}, null };

    inline for (values) |v| {
        try getty.serialize(v, s);
    }
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
true
10
1.0e+01
"string"
"variant"
null
null
{% endhighlight %}
{% endlabel %}

And there we have it! Our initial `Serializer` implementation from the intro! But with more context!

Now all we have to do is implement `serializeMap`, `serializeSeq`, and `serializeStruct`. However, before we move on, I wanted to point out a few things about our implementation:

- By keeping all of our method implementations private, we avoided polluting the public API of `Serializer` with interface-related code. Furthermore, we've ensured that users cannot mistakenly use a `Serializer` value to perform serialization instead of an interface value.

- Since the signatures of the `serializeFloat` and `serializeInt` required methods are the same, we were able to implement both of them using one function: `serializeNumber`. We also did the same thing for `serializeNull` and `serializeVoid`.

- Even though the type of the `value` parameter for many of the required methods is `anytype`, we didn't perform any type validation. That is because Getty ensures that an appropriate type is passed to each function. For example, only string values are passed to `serializeString` and only integers and floating-points are passed to `serializeNumber`. You'll never have to type-check the `value` parameter unless, of course, you wish to further restrict its type.
