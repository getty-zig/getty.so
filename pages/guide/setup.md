---
title: Setup
category: Guide
layout: default
permalink: /guide/setup/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Setup

To get started, create a new (executable) Zig project called `getty-learn`:

{% label Shell session %}
{% highlight sh %}
mkdir getty-learn
cd getty-learn
zig init-exe
{% endhighlight %}
{% endlabel %}

Then, we'll act as our own package manager and install Getty into the `lib/getty` directory:

{% label Shell session %}
{% highlight sh %}
git clone https://github.com/getty-zig/getty lib/getty
{% endhighlight %}
{% endlabel %}

Finally, we can make our project aware of Getty by calling `addPackagePath` in `build.zig`:

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    ...

    const exe = b.addExecutable("getty-learn", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("getty", "lib/getty/src/lib.zig"); // 👈
    exe.install();

    ...
}
{% endhighlight %}
{% endlabel %}

And there we go! We've successfully added Getty to our project!
