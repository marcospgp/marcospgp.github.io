---
layout: post
title: Key insights on IEEE 754 floating point numbers
tag: Web 💻
---

A 32-bit [IEEE 754 floating point](https://evanw.github.io/float-toy/) number is organized in 3 bit groups:

`0_00000000_00000000000000000000000`

1. The sign (0 or 1 representing 1 and -1 respectively)
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

2. Exponent with all ones (`11111111`) is either infinity (if fraction is all zeros) or NaN (otherwise), the latter signaling an error.

Also note that it's possible to represent both +0 and -0:

```text
0_00000000_00000000000000000000000 = +0
1_00000000_00000000000000000000000 = -0
```

## Key insights

Being aware of the internal design of a floating point number allows us to derive some key insights, which can be useful when deciding how to use this type in order to make the most use of its representational space.

### Half of the representation space is in [-1, 1]

```text
1_01111111_00000000000000000000000 = -1
0_01111111_00000000000000000000000 = 1
```

All numbers starting with the 9 bits in those two examples above will be between -1 and 1.

This means the second bit is what determines whether a number is inside or outside of [-1, 1]. Half of the representational space for each.

### There are the same number of representable numbers between each power of 2

Because the fraction is fixed to 23 bits, we can represent 2^23 numbers between each possible exponent.

This means the distance between floating point numbers is fixed for each exponent, and grows as the exponent grows.

The space between consecutive floating point numbers is determined by two things: the exponent `X` and the number of bits in the significand `B`. The formula is:

```text
2^(X - 127) * 2^(-B)
```

Which means for a 32-bit float (23-bit significand) and exponent 128 (`01111111`) the error is:

```text
2^1 * 2^(-23) = 2 * 1/(2^23) = 1/(2^22)
```

And each successive exponent increases the spacing between adjacent floating point numbers by a factor of 2.

With an exponent of 150, the error is exactly 1:

```text
2^23 * 2^(-23) = 1
```

Which means there are no 32-bit floating point numbers between 8388608 and 8388609, for example.
