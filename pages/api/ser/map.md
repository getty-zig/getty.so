---
title: Map
category: api
layout: default
permalink: /api/ser/Map/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `Map`

## Description

`getty.ser.Map` is an interface that specifies the serialization process for Getty Map values.

Getty Maps are only partially serialized by [`getty.Serializer`](/api/Serializer) implementations
due to the fact that there are many different ways to iterate over and access
the keys and values of a map. As such, this interface is provided so that
serialization can be driven and completed by the user of a serializer.


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
        - `void` on success.
        - A value of type `E` on failure.

- `serializeValue`: Serializes a value in a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: A value to serialize.
    - __Return__:
        - `void` on success.
        - A value of type `E` on failure.

- `end`: Ends the serialization process for a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - A value of type `O` on success.
        - A value of type `E` on failure.

### Provided Methods

- `serializeEntry`: Serializes a key and a value in a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `key`: A key to serialize.
        - `value`: A value to serialize.
    - __Return__:
        - `void` on success.
        - A value of type `E` on failure.
