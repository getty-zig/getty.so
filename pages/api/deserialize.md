---
title: deserialize
category: API
layout: default
permalink: /api/deserialize/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.deserialize`

## Description

`getty.deserialize` deserializes a value from a Getty deserializer.

## Synopsis

{% label Zig code %}
{% highlight zig %}
const Allocator = @import("std").mem.Allocator;

fn deserialize(
    allocator: ?Allocator,
    comptime T: type,
    deserializer: anytype,
) @TypeOf(deserializer).Error!T
{% endhighlight %}
{% endlabel %}

### Parameters

- `allocator`: An optional memory allocator.

- `T`: The type to deserialize into.

- `deserializer`: A [`getty.Deserializer`](/api/Deserializer) interface value.

### Return

- On success, a value of type `T`.
- On failure, an error in the error set of `deserializer`.
