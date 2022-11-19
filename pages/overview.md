---
title: Overview
category: Introduction
layout: default
permalink: /overview/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Overview

Getty is a framework for building serializers and deserializers in Zig.

Usually, (de)serializers written in Zig are just functions that take a value, switch on its type, and (de)serialize based on the resulting type information. In fact, this is exactly what `std.json` does! The problem with this approach though, is that it is very brittle, inflexible, and ends up being a lot of unnecessary work. The goal of Getty is to help you avoid all of that and reduce the amount of code you need to write a (de)serializer that is customizable, performant, and able to support many different data types out of the box (including ones in the standard library).

And it doesn't matter whether you're working with JSON, YAML, or whatever other data format there is. Getty is data format-agnostic, so as long as you can figure out how to map from your data format to Getty's data models, you'll be set!

## Architecture

At a high-level, Getty consists of two flows: a __serialization flow__ and a __deserialization flow__.

In the serialization flow, a Zig value is passed to Getty and, based on its type, a Serialization Block is selected and executed by Getty, serializing the passed-in value into Getty's serialization data model. The resulting Getty value is then passed to a serializer, which serializes it into an output data format.

In the deserialization flow, a Zig type is passed to Getty and, based on the type, a Deserialization Block is selected and executed by Getty, prompting a deserializer to deserialize its input data into Getty's deserialization data model. The resulting Getty value is then passed to a Visitor, where it is converted into a Zig value of the passed-in type.

<img alt="Architecture" src="/assets/images/architecture.svg" class="figure" />
