---
title: Serializer
category: API
layout: default
permalink: /api/Serializer/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.Serializer`

## Description

`getty.Serializer` is an interface that specifies the behavior of a serializer.

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

- `user_sbt`: An optional user-defined [Serialization Block or Tuple](/TODO).

- `serializer_sbt`: An optional serializer-defined [Serialization Block or Tuple](/TODO).

- `Map`: An optional type that implements [`getty.ser.Map`](/api/ser/Map).

- `Seq`: An optional type that implements [`getty.ser.Seq`](/api/ser/Seq).

- `Structure`: An optional type that implements [`getty.ser.Structure`](/api/ser/Structure).

- `methods`: A namespace containing every method that `getty.Serializer` implementations can implement.

### Required Methods

- `serializeBool`: Serializes a Getty Boolean value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Boolean value to serialize.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeEnum`: Serializes a Getty Enum value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Enum value to serialize.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeFloat`: Serializes a Getty Float value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Float value to serialize.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeInt`: Serializes a Getty Integer value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Integer value to serialize.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeMap`: Begins the serialization process for a Getty Map value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `length`: An optional length for the Getty Map that will be returned.
    - __Return__:
        - On success, a value of type `Map`.
        - On failure, an error in the error set `E`.

- `serializeNull`: Serializes a Getty Null value.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeSeq`: Begins the serialization process for a Getty Sequence value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `length`: An optional length for the Getty Sequence that will be returned.
    - __Return__:
        - On success, a value of type `Map`.
        - On failure, an error in the error set `E`.

- `serializeSome`: Serializes a Getty Some value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty Some value to serialize.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeString`: Serializes a Getty String value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A Getty String value to serialize.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

- `serializeStruct`: Begins the serialization process for a Getty Structure value.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `name`: A name for the Getty Structure that will be returned.
        - `length`: An optional length for the Getty Structure that will be returned.
    - __Return__:
        - On success, a value of type `Structure`.
        - On failure, an error in the error set `E`.

- `serializeVoid`: Serializes a Getty Void value.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.
