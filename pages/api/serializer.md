---
title: Serializer
category: API
layout: default
permalink: /api/Serializer/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.Serializer`

## Description

`getty.Serializer` specifies the behavior of a serializer.

## Synopsis

{% label Zig code %}
{% highlight zig %}
fn Serializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime user_sbt: anytype,
    comptime serializer_sbt: anytype,
    comptime Map: ?type,
    comptime Seq: ?type,
    comptime Structure: ?type,
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

### Parameters

- `Context`: The namespace that owns the method implementations you provide in `methods`.

- `O`: The return type for most of `getty.Serializer`'s methods.

- `E`: The error set returned by `getty.Serializer`'s methods upon failure.

- `user_sbt`: A user-defined [Serialization Block or Tuple](/TODO).

- `serializer_sbt`: A serializer-defined [Serialization Block or Tuple](/TODO).

- `Map`: A type that implements the [`getty.ser.Map`](/api/ser/Map) interface.

- `Seq`: A type that implements the [`getty.ser.Seq`](/api/ser/Seq) interface.

- `Structure`: A type that implements the [`getty.ser.Structure`](/api/ser/Structure) interface.

- `methods`: A namespace containing every method that `getty.Serializer` implementations can implement.

### Required Methods

- `serializeBool`: Serializes a Getty Boolean value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Boolean value to serialize.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeEnum`: Serializes a Getty Enum value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Enum value to serialize.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeFloat`: Serializes a Getty Float value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Float value to serialize.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeInt`: Serializes a Getty Integer value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Integer value to serialize.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeMap`: Begins the serialization process for a Getty Map value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `length`: An optional length for the Getty Map that will be returned.
    - __Return__:
        - A value of type `Map` on success.
        - A value of type `E` on failure.

- `serializeNull`: Serializes a Getty Null value.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeSeq`: Begins the serialization process for a Getty Sequence value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `length`: An optional length for the Getty Sequence that will be returned.
    - __Return__:
        - A value of type `Seq` on success.
        - A value of type `E` on failure.

- `serializeSome`: Serializes a Getty Some value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Some value to serialize.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeString`: Serializes a Getty String value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty String value to serialize.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

- `serializeStruct`: Begins the serialization process for a Getty Structure value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `name`: A name for the Getty Structure that will be returned.
        - `length`: An optional length for the Getty Structure that will be returned.
    - __Return__:
        - A value of type `Structure` on success.
        - A value of type `E` on failure.

- `serializeVoid`: Serializes a Getty Void value.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.
