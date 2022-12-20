---
title: Blocks and Tuples
category: Concepts
layout: default
permalink: /blocks-and-tuples/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Blocks and Tuples

__Blocks__ are the fundamental building blocks (no pun intended) of Getty's
(de)serialization process.

They define how a type should be serialized or deserialized into. For example,
the ways a `bool` value can be serialized by Getty are specified in the
`getty.ser.blocks.Bool` block. Similarly, the ways to deserialize into a
`[5]i32` are defined in the `getty.de.blocks.Array` block.

Getty uses blocks internally to form its core (de)serialization behavior.
However, blocks are also the the main mechanism for customization in Getty.
Users and (de)serializers can take advantage of blocks to customize the way
Getty serializes or deserializes a value.

## Blocks

Blocks are `struct` namespaces that are responsible for specifying two things:

1. The type(s) that should be (de)serialized by the block.
1. How to serialize or deserialize into values of those types.

The way a block is defined varies depending on whether you're serializing or
deserializing and the kind of block you're making. To show you what I mean,
let's go through the different kinds of blocks.

<!--How you specify these two things varies depending on whether you're serializing-->
<!--or deserializing, and the customization methods you're using. Once you have a-->
<!--block though, you can pass them to Getty via the-->
<!--[`getty.Serializer`](https://docs.getty.so/#root;Serializer) and-->
<!--[`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) interfaces,-->
<!--which have parameters such as `user_sbt`, `serializer_sbt`, `user_dbt` and-->
<!--`deserializer_dbt`. Those parameter are where you'd pass in your blocks.-->

### Serialization Blocks

To manually define the serialization process, you can use a serialization block:

{% label Zig code %}
{% highlight zig %}
const sb = struct {
    // 👋 is specifies which types should be serialized by this block.
    //
    //    In this case, the block applies only to Boolean values.
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // 👋 serialize specifies how to serialize values relevant to this block.
    //
    //    Here, we're telling Getty to serialize bool values as Getty Integers.
    pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
        // Convert value to a Getty Integer (represented by any integer type).
        const v: i32 = if (value) 1 else 0;

        // Pass the Getty Integer value to the serializer.
        return try serializer.serializeInt(v);
    }
};
{% endhighlight %}
{% endlabel %}

### Deserialization Blocks

To manually define the deserialization process, you can use a deserialization block:

{% label Zig code %}
{% highlight zig %}
const db = struct {
    // 👋 is specifies which types can be deserialized into by this block.
    //
    //    In this case, the block can only deserialize into bool values.
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // 👋 deserialize specifies what hint Getty should provide a deserializer.
    //
    //    In this case, we call `deserializeInt`, which means that Getty will
    //    tell the deserializer that we can probably make whatever value we're
    //    deserializing into from a Getty Integer. That's right! We'll be making
    //    a bool from an integer!
    //
    //    ❓ The second parameter of deserialize is the current type being
    //       deserialized into. Generally, you don't need it unless you're
    //       doing pointer deserialization.
    pub fn deserialize(
        allocator: ?std.mem.Allocator,
        comptime _: type,
        deserializer: anytype,
        visitor: anytype,
    ) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
        return try deserializer.deserializeInt(allocator, visitor);
    }

    // 👋 Visitor returns a type that implements getty.de.Visitor.
    //
    //    Visitors are responsible for specifying how to deserialize values
    //    from Getty's data model into Zig. Here, we've made a visitor that
    //    can deserialize Getty Integers into bool values, which it does by
    //    simply returning whether or not the integer is 0.
    //
    //    ❓ The Value parameter is the type that will be produced by the
    //       visitor. In this case, Value would be bool. The parameter's mostly
    //       useful for when you're creating visitors for generic types.
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
{% endhighlight %}
{% endlabel %}

### Attribute Blocks

For simpler modifications to Getty's (de)serialization processes for `struct`,
`enum`, or `union` types, you can use attribute blocks.

With attribute blocks, the default (de)serialization processes are used. For
example, `struct`s will be serialized using the default
`getty.ser.blocks.Struct` block and deserialized using the default
`getty.de.blocks.Struct` block. However, slight changes to these processes will
take effect based on which attributes you specify. For a complete list of the
attributes in Getty, see [here](/attributes).


Attribute blocks are defined the same whether you're serializing or
deserializing:

{% label Zig code %}
{% highlight zig %}
const Point = struct {
    x: i32,
    y: i32,
};

const ab = struct {
    pub fn is(comptime T: type) bool {
        return T == Point;
    }

    // 👋 attributes specifies (de)serialization properties for values relevant
    //    to this block.
    //
    //    If this block is used for serialization, then we've specified that
    //    the "x" field of Point should be serialized as "X", and that the "y"
    //    field should be skipped.
    //
    //    If this block is used for deserialization, then we've specified that
    //    the value for the "x" field of Point is serialized as "X", and that
    //    we should not try to deserialize the "y" field.
    //
    //    ❓ attributes is an anonymous struct literal. Every field name in
    //       attributes must match either the fields or variants in your
    //       struct, enum, or union, or the word "Container". The former kind
    //       of attributes are known as field/variant attributes, while the
    //       latter are known as container attributes.
    //
    //    ❓ Each field in attributes is also an anonymous struct literal. The
    //       fields in these inner structs depend on the kind of attribute
    //       you're specifying.
    pub const attributes = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
};
{% endhighlight %}
{% endlabel %}


### Usage

Once you've defined a block, you can pass them along to Getty via the
[`getty.Serializer`](https://docs.getty.so/#root;Serializer) and
[`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) interfaces.
They take optional (de)serialization blocks as arguments:

- `user_sbt`, `user_dbt`: User-defined (de)serialization blocks.
- `serializer_sbt`, `deserializer_dbt`: (De)serializer-defined (de)serialization blocks.

For example, the following defines a serializer that can serialize Getty
Booleans and Integers into JSON. It is generic over a serialization block,
which it passes along to Getty, allowing us to easily customize Getty's
serialization behavior.

{% label Zig code %}
{% highlight zig %}
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

        try getty.serialize(true, serializer);  // output: true
        try getty.serialize(false, serializer); // output: false
    }

    // Custom
    {
        var s = Serializer(sb){};
        const serializer = s.serializer();

        try getty.serialize(true, serializer);  // output: 1
        try getty.serialize(false, serializer); // output: 0
    }
}
{% endhighlight %}
{% endlabel %}

## Tuples

Occassionally, you may want to pass multiple (de)serialization blocks to Getty. To do so, you can use __(de)serialization tuples__.

A (de)serialization tuple is, well, a tuple of (de)serialization blocks. They
can be used wherever a (de)serialization block can be used and allow you to do
some pretty handy things. For example, suppose you had the following type:


{% label Zig code %}
{% highlight zig %}
const Point = struct {
    x: i32,
    y: i32,
};
{% endhighlight %}
{% endlabel %}

If you just wanted to serialize `Point` values as sequences, you'd simply write
a serialization block doing so and pass it along to Getty. However, what if you
also wanted to serialize `i32` values as Booleans?

One option is to stuff all of your custom serialization logic into a single
block. But that gets messy real quick and inevitably becomes a pain in the butt
to maintain.

A much better solution is to break up your custom serialization behaviors into
their own separate blocks. One for `Point` values and one for `i32` values.
Then, you can just group them together as a serialization tuple and have Getty
process both blocks!

{% label Zig code %}
{% highlight zig %}
const point_sb = struct {
    // ...
};

const i32_sb = struct {
    // ...
};

const point_st = .{ point_sb, i32_sb };
{% endhighlight %}
{% endlabel %}
