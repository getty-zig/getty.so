---
title: Map
category: api
layout: default
permalink: /api/ser/Map/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.ser.Map`

## Description

`getty.ser.Map` is an interface that specifies how to serialize Getty Maps.

## Synopsis

{% label Zig code %}
{% highlight zig %}
fn Map(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeKey: ?fn (Context, anytype) E!void = null,
        serializeValue: ?fn (Context, anytype) E!void = null,
        serializeEntry: ?fn (Context, anytype, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type
{% endhighlight %}
{% endlabel %}

### Interface

- `@"getty.ser.Map"`: Interface type.
- `map`: Interface function.

### Parameters

- `Context`: The namespace that owns the method implementations you provide in `methods`.

- `O`: The return type for `getty.ser.Map`'s `end` method.

- `E`: The error set returned by `getty.ser.Map`'s methods upon failure.

- `methods`: A namespace containing every method that `getty.ser.Map` implementations can implement.

### Required Methods

- `serializeKey`: Serializes a key in a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A key to serialize.
    - __Return__:
        - On success, `void`.
        - On failure, an error in the error set `E`.

- `serializeValue`: Serializes a value in a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A value to serialize.
    - __Return__:
        - on success, `void`.
        - on failure, an error in the error set `E`.

- `end`: Ends the serialization process for a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.

### Provided Methods

- `serializeEntry`: Serializes a key and a value in a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `key`: A key to serialize.
        - `value`: A value to serialize.
    - __Return__:
        - on success, `void`.
        - on failure, an error in the error set `E`.
