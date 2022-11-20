---
title: serialize
category: API
layout: default
permalink: /api/serialize/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.serialize`

## Description

`getty.serialize` serializes a value using a Getty serializer.

## Synopsis

{% label Zig code %}
{% highlight zig %}
fn serialize(
    value: anytype,
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok
{% endhighlight %}
{% endlabel %}

### Parameters

- `value`: A value to serialize.

- `serializer`: A [`getty.Serializer`](/api/Serializer) interface value.

### Return

- On success, a value of the successful return type of `serializer`.
- On failure, an error in the error set of `serializer`.
