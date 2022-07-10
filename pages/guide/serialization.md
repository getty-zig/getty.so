---
title: Serialization
category: Guide
layout: default
permalink: /guide/serialization/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Serialization

Serialization in Getty is a relatively straightforward process, as can be seen in the figure below.

<img alt="Serialization" src="/assets/images/serialization.svg" class="figure"/>

The process begins whenever data is passed to Getty. Upon receiving data to serialize, Getty selects and executes a _Serialization Block_, serializing the data into its _serialization data model_. The resulting Getty value is then passed to a Getty serializer to be serialized once more into an output data format.

In this section of the guide, we'll focus mainly on the first half of the serialization process:

<img alt="Serialization (users)" src="/assets/images/serialization-left.svg" class="figure-small"/>

## Data Models

Getty has two data models: one for serialization and one for deserialization.

Each data model is a set of abstract types (e.g., Booleans, Integers, Strings, Sequences) that provide (de)serializers with a simple, consistent, and generic interface to (de)serialization. Basically, what that means is that a Getty serializer doesn't have to know how to serialize all possible Zig types, just the ones in Getty's serialization data model, which can greatly simplify the serializer's implementation.

<!--Most of the types within Getty's data models have a corresponding Zig representation. For example, a Getty Boolean is just a `bool` and a Getty String is any valid Zig string like `[]u8` or `[]const u8`. Some types, like Maps and Sequences, are a bit more complicated. But we'll talk about those later.-->

## Serialization Blocks

Upon receiving a value to serialize, Getty will select and execute a Serialization Block. Serialization Blocks are namespaces that specify how to serialize a particular set of types into Getty's serialization data model.

Getty defines Serialization Blocks for a number of common Zig data types, including integers, slices, structs, `std.ArrayList`, `std.StringHashMap`, and [more](https://github.com/getty-zig/getty/tree/main/src/ser/blocks). For these types, you don't need to do anything special in order to serialize them. Just pass your data (and a serializer) to Getty and you're good to go!

For types that aren't supported by Getty out-of-the-box or in cases where Getty's default serialization behavior is insufficient, you can write and use your own Serialization Block(s). Each block is just a namespace (i.e., a `struct` with no fields) that contains two functions:

{% label Zig code %}
{% highlight zig %}
// Specifies the set of types that a Serialization Block applies to.
fn is(comptime T: type) bool
{% endhighlight %}
{% endlabel %}

{% label Zig code %}
{% highlight zig %}
// Specifies how to serialize the types a Serialization Block applies to.
fn serialize(
    value: anytype,
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok
{% endhighlight %}
{% endlabel %}

For example, the following shows a Serialization Block that turns `bool` values into Getty Booleans:

{% label Zig code %}
{% highlight zig %}
const bool_sb = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        return try serializer.serializeBool(value);
    }
};
{% endhighlight %}
{% endlabel %}

As you can see, serializing a value into Getty's data model requires that one of the methods of the `serializer` parameter (a `getty.Serializer` interface value) is called. In this case, we called `serializeBool`, which serialized the `value` parameter into, unsurprisingly, a Getty Boolean.

Of course, we could have just as easily called any other serialization method. For example, the following Serialization Block calls `serializeString` to convert `value` into a Getty String:

{% label Zig code %}
{% highlight zig %}
const string_sb = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        return try serializer.serializeString(if (value) "true" else "false");
    }
};
{% endhighlight %}
{% endlabel %}

<!--Notice how the `serialize` function doesn't do any type validatation for the `value` parameter. That's because the `is` function specified that `bool_sb` should only be used whenever Getty encounters `bool` values. Thus, `serialize` can always safely assume that `value` is a `bool`!-->

<!--I also want to highlight the fact that the serialization logic we've defined in `serialize` is _separate_ from the actual `bool` type itself. This separation allows you to reuse and compose serialization logic, easily change how types are serialized without requiring type modifications or annotations, and define the serialization process for remote/foreign types (i.e., types that you didn't define yourself).-->