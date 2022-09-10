---
title: Setup
category: Guide
layout: default
permalink: /guide/setup/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Setup

To kick things off, create a new Zig project called `getty-learn`:

{% label Shell session %}
{% highlight sh %}
mkdir getty-learn
cd getty-learn
zig init-exe
{% endhighlight %}
{% endlabel %}

Next, install Getty into the `lib/getty` directory within `getty-learn`:

{% label Shell session %}
{% highlight sh %}
git clone https://github.com/getty-zig/getty lib/getty
{% endhighlight %}
{% endlabel %}

Then, make `getty-learn` aware of Getty by calling `addPackagePath` in `build.zig`:

{% label build.zig %}
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

Finally, check to see that everything is working by running the following program:

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

pub fn main() anyerror!void {
    std.debug.print("{}\n", .{getty.TODO});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight sh %}
$ zig build run
lib.TODO
{% endhighlight %}
{% endlabel %}
