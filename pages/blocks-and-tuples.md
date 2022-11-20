---
title: Blocks and Tuples
category: Concepts
layout: default
permalink: /blocks-and-tuples/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Blocks and Tuples

A __Block__ is a `struct` namespace that is responsible for specifying two things:

1. The types that should be (de)serialized by the block.
1. How to serialize values those types or deserialize into those types.

A __Tuple__ is a tuple of blocks.

## Blocks

Every block requires a few specific declarations. What and how many declarations a block requires depends on whether you're serializing or deserializing, and which customization method you're using.

In any case, the [`getty.Serializer`](/api/Serializer) and [`getty.Deserializer`](/api/Deserializer) interfaces have parameters such as `user_sbt`, `serializer_sbt`, `user_dbt` and `deserializer_dbt`. These are where you'd pass in your blocks and tuples in order to customize Getty's behavior.

### Attribute Blocks (AB)

One of the ways you can customize Getty's behavior is through attributes. Attributes provide a convenient way to customize the (de)serialization process for `struct`, `enum`, and `union` values.

ABs are defined the same whether you're serializing or deserializing. They all look something like this:

{% label Zig code %}
{% highlight zig %}
const Point = struct {
    x: i32,
    y: i32,
};

const ab = struct {
    // 👋 is specifies which types should be serialized by this block.
    pub fn is(comptime T: type) bool {
        return T == Point;
    }

    // 👋 attributes specifies serialization properties for values relevant to
    //    this block.
    //
    //    As you can see, attributes is an anonymous struct literal.
    //
    //    Every field name in attributes must match either the fields or
    //    variants in your struct/enum/union, or the word "Container". The
    //    former are known as field/variant attributes, while the latter are
    //    known as container attributes.
    //
    //    Each field in attributes is also an anonymous struct literal. The
    //    fields in this struct depend on the kind of attribute you are
    //    specifying.
    pub const attributes = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
};
{% endhighlight %}
{% endlabel %}

For a complete list of all of the attributes you can specify, see [here](/attributes).

### Serialization Blocks (SB)

In cases where attributes aren't sufficient, you can manually customize the serialization process by simply replacing the `attributes` declaration with a `serialize` function:

{% label Zig code %}
{% highlight zig %}
const sb = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // 👋 serialize specifies how to serialize values relevant to this block.
    //
    //    Here, we're telling Getty to serialize bool values as Getty Integers.
    pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
        const v: i32 = if (value) 1 else 0;
        return try serializer.serializeInt(v);
    }
};
{% endhighlight %}
{% endlabel %}

### Deserialization Blocks (DB)

Of course, you can also manually customize the deserialization process with a Deserialization Block.

{% label Zig code %}
{% highlight zig %}
const db = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // 👋 deserialize specifies how to deserialize into types relevant to this
    //    block.
    //
    //    Here, we're telling Getty to hint to the deserializer that it should
    //    deserialize its input data into a Getty Integer. This will allow us
    //    to deserialize JSON Numbers into bool values.
    //
    //    The second parameter of deserialize is the current type being
    //    deserialized into. Generally, you don't need it unless you're doing
    //    pointer deserialization.
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
    //    knows how to deserialize Getty Integers into bool values.
    //
    //    The Value parameter is the type that will be produced by the visitor.
    //    In this case, Value would be bool. The parameter's mostly useful for
    //    when you're creating visitors for generic types.
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
                return switch (input) {
                    0 => false,
                    1 => true,
                    else => error.InvalidType,
                };
            }
        };
    }
};
{% endhighlight %}
{% endlabel %}

