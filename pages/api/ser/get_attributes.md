---
title: get_attributes
category: API
layout: default
permalink: /api/ser/get_attributes/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.ser.getAttributes`

## Description

Returns the attributes defined within a type. If none exists, `null` is returned.

## Synopsis

{% label Zig code %}
{% highlight zig %}
fn getAttributes(
    comptime T: type,
    comptime Serializer: type
) ...
{% endhighlight %}
{% endlabel %}

### Parameters

- `T`: The type for which attributes should be returned.
- `Serializer`: A [`getty.Serializer`](/api/Serializer) interface type.

### Return

- If no attributes exist in `T`, `null` is returned.
- If attributes do exist in `T`, they'll be validated and then returned.
