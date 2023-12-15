---
layout: post
title: Key insights on IEEE 754 floating point numbers
tag: Web 💻
---

A 32-bit [IEEE 754 floating point](https://evanw.github.io/float-toy/) number is organized in 3 bit groups:

`0_00000000_00000000000000000000000`

1. The sign (1 or -1)
2. The exponent
3. The fraction

Where the exponent has an offset of -127 (meaning that `01111111` is 0).

The formula to calculate the resulting number is:

```text
(-1)^sign * 2^(exponent - 127) * 1.fraction
```

Here, `1.fraction` becomes the significand, informally known as mantissa.

There are also two special cases for the exponent:

1. Exponent with all zeros (`00000000`). This changes the exponent offset to -126 (the same as `00000001`), but the significand now starts with 0. This changes the formula into:

   ```text
   (-1)^sign * 2^(-126) * 0.fraction
   ```

2. Exponent with all ones (`11111111`) is either infinity (if fraction is all zeros) or NaN, the latter signaling an error.

Aside from some

- Half of the representation space is in [-1, 1]
