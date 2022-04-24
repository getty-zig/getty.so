---
title: Overview
category: Introduction
layout: default
permalink: /overview/
SPDX-License-Identifier: LGPL-2.1-or-later
---

## Overview

At a high-level, Getty consists of two flows: a __serialization flow__ and a
__deserialization flow__.

In the serialization flow, a Zig value is passed to Getty and, based on its
type, a Serialization Block is selected and executed by Getty, serializing the
passed-in value into Getty's serialization data model. The resulting Getty
value is then passed to a serializer, which serializes it into an output data
format.

In the deserialization flow, a Zig type is passed to Getty and, based on the
type, a Deserialization Block is selected and executed by Getty, prompting
a deserializer to deserialize its input data into Getty's deserialization data
model. The resulting Getty value is then passed to a Visitor, where it is
converted into a Zig value of the passed-in type.

<!--<img alt="Architecture" src="/assets/images/architecture.svg" width="55%" />-->
