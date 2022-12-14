---
title: Installation
category: Introduction
layout: default
permalink: /installation/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Installation

To install Getty for your project, you may use any of the following methods:

- [Manual](#manual)
- [Gyro](#gyro)
- [Zigmod](#zigmod)

## Manual

First, add Getty to your project:

{% label Shell session %}
{% highlight console %}
git clone https://github.com/getty-zig/getty lib/getty
{% endhighlight %}
{% endlabel %}

Then, add the following line to `build.zig`:

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // ...

    const exe = b.addExecutable("my-project", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("getty", "lib/getty/src/getty.zig"); // 👈
    exe.install();
}
{% endhighlight %}
{% endlabel %}

## Gyro

First, add Getty to your project:

{% label Shell session %}
{% highlight console %}
gyro add -s github getty-zig/getty
gyro fetch
{% endhighlight %}
{% endlabel %}

Then, add the following lines to `build.zig`:

{% label Zig code %}
{% highlight zig %}
const std = @import("std");
const pkgs = @import("deps.zig").pkgs; // 👈

pub fn build(b: *std.build.Builder) void {
    // ...

    const exe = b.addExecutable("my-project", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    pkgs.addAllTo(exe); // 👈
    exe.install();
}
{% endhighlight %}
{% endlabel %}

## Zigmod

First, add the following line to `zigmod.yml`:

{% label YAML %}
{% highlight yaml %}
# ...

root_dependencies:
  - src: git https://gitub.com/getty-zig/getty # 👈
{% endhighlight %}
{% endlabel %}

Then, add Getty to your project:

{% label Shell session %}
{% highlight console %}
zigmod fetch
{% endhighlight %}
{% endlabel %}

Finally, add the following lines to `build.zig`:

{% label Zig code %}
{% highlight zig %}
const std = @import("std");
const deps = @import("deps.zig"); // 👈

pub fn build(b: *std.build.Builder) void {
    // ...

    const exe = b.addExecutable("my-project", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    deps.addAllTo(exe); // 👈
    exe.install();
}
{% endhighlight %}
{% endlabel %}
