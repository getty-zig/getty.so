---
title: Setup
category: Guide
layout: default
permalink: /guide/setup/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Setup

The first thing we need to do before writing any code is set up a new Zig project:

{% label Shell session %}
{% highlight sh %}
mkdir getty-json
cd getty-json
zig init-exe
{% endhighlight %}
{% endlabel %}

Then, clone Getty into the `lib/getty` directory since there's no official package manager yet:

{% label Shell session %}
{% highlight sh %}
git clone https://github.com/getty-zig/getty lib/getty
{% endhighlight %}
{% endlabel %}

Finally, make `getty-json` aware of Getty by calling `addPackagePath` in `build.zig`:

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    ...

    const exe = b.addExecutable("getty-json", "src/main.zig");

    // 👇
    exe.addPackagePath("getty", "lib/getty/src/lib.zig");

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    ...
}
{% endhighlight %}
{% endlabel %}

And there we go! We've successfully added Getty to our project! 🥳
