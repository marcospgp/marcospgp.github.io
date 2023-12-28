---
layout: post
title: Key insights on IEEE 754 floating point numbers
description: Understanding floating point representation can help design systems in order to make the most out of this type.
tag: Web 💻
---

## IEEE 754

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

### Half of the representation space is between -1 and 1

```text
1_01111111_00000000000000000000000 = -1
0_01111111_00000000000000000000000 = 1
```

This means exponents `00000000` to `01111110` represent numbers in `]-1, 1[`.

Because exponent `11111111` is a special case (infinity or NaN), this is basically half of the representation space.

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

## Random sampling

Sampling a random floating point number is more complex than it seems if one cares about covering all of the representation space.

The popular technique `randomInteger / maxInteger` (casting the integers to float) fails to cover a large portion of that space (however, in a way that is biased towards extreme values).

### Sampling between 0 and 1

To generate a random 32-bit floating point in `[0, 1)`, since there are 125 possible exponents (`00000001` to `01111110`) representing successive powers of 2, one needs 125 random bits just to sample the exponent.

Exponent `01111110` (2^-1) represents half of the `[0, 1)` interval, so the first bit decides whether it is picked. If it is 0, the next bit decides whether exponent `01111101` (2^-2) is picked (which covers half of the previous interval).

Exponent `00000000` (2^-126) being a special case (same as `00000001` except significand starts with 0 instead of 1) means we need one extra bit just for it (even though it is microscopic) making the total requirement 125 + 1 = 126 bits. This last bit will decide which of `00000000` or `00000001` to pick.

I've tried to think of a way to sample this with less bits, but found none. In the end, we need one possible state to represent each of `00000000` and `00000001`. Each successive exponent covering double the space requires double the probability, thus double the possible states - quickly arriving at 2^125 values for the largest exponent `01111110`.

This is surprising because the underlying floating point number only has 32 bits, with the exponent taking up a single byte.

As to the sign and fraction, 1 and 23 random bits respectively will suffice.

### Caveat

To be fair, just the 8 highest exponents cover over 99% of the `[0, 1)` interval:

```text
1 - 2^-8 = 0.99609375
```

Which means floating point numbers near 0 are highly biased towards extremely small values, in terms of representation space occupation.

Sampling with a simpler technique may be sufficient most of the time.
