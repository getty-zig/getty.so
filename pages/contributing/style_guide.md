---
title: Style Guide
category: Contributing
layout: default
permalink: /style-guide/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Style Guide

This document describes the coding style that all new code for Getty should try to conform to.

## Formatting

- All code should be formatted by `zig fmt`. If your code isn't properly formatted, the CI will fail.

- When writing a comment, use `///` for public API descriptions and `//` for everything else.

- Try to limit lines to 100 characters. It's okay to go over though, so long as things are readable.

## Naming

- Follow the naming conventions listed [here](https://ziglang.org/documentation/master/#Names).
