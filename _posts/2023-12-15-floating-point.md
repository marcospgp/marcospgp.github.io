---
layout: default
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

```plaintext
(-1)^sign * 2^(exponent - 127) * 1.fraction
```

Here, `1.fraction` becomes the significand, informally known as mantissa.

There are also two special cases for the exponent:

1. Exponent with all zeros (`00000000`). This changes the exponent offset to -126 (the same as `00000001`), but the significand now starts with 0. This changes the formula into:

   ```plaintext
   (-1)^sign * 2^(-126) * 0.fraction
   ```

2. Exponent with all ones (`11111111`) is either infinity (if fraction is all zeros) or NaN (otherwise), the latter signaling an error.

Also note that it's possible to represent both +0 and -0:

```plaintext
0_00000000_00000000000000000000000 = +0
1_00000000_00000000000000000000000 = -0
```

## Key insights

Being aware of the internal design of a floating point number allows us to derive some key insights, which can be useful when deciding how to use this type in order to make the most use of its representational space.

### Half of the representation space is between -1 and 1

```plaintext
1_01111111_00000000000000000000000 = -1
0_01111111_00000000000000000000000 = 1
```

This means exponents `00000000` to `01111110` represent numbers in `]-1, 1[`.

Because exponent `11111111` is a special case (infinity or NaN), this is basically half of the representation space.

### There are the same number of representable numbers between each power of 2

Because the fraction is fixed to 23 bits, we can represent `2^23` numbers between each possible exponent.

This means the distance between floating point numbers is fixed for each exponent, and grows as the exponent grows.

The space between consecutive floating point numbers is determined by two things: the exponent `X` and the number of bits in the significand `B`. The formula is:

```plaintext
2^(X - 127) * 2^(-B)
```

Which means for a 32-bit float (23-bit significand) and exponent 128 (`01111111`) the error is:

```plaintext
2^1 * 2^(-23) = 2 * 1/(2^23) = 1/(2^22)
```

And each successive exponent increases the spacing between adjacent floating point numbers by a factor of 2.

With an exponent of 150, the error is exactly 1:

```plaintext
2^23 * 2^(-23) = 1
```

Which means there are no 32-bit floating point numbers between 8388608 and 8388609, for example.

## Random sampling

Sampling a random floating point number is more complex than it seems if one cares about covering all of the representation space.

The popular technique `randomInteger / maxInteger` (casting the integers to float) fails to cover a large portion of that space (however, in a way that is biased towards extreme values).

### Sampling between 0 and 1

To generate a random 32-bit floating point in `[0, 1)`, since there are 127 possible exponents (`00000000` to `01111110`) one needs 126 random bits to sample among these.

Exponents `00000001` (`2^-126`) through `01111110` (`2^-1`) represent successive powers of two. The highest exponent `01111110` represents half of the `[0, 1)` interval, and each successive lower exponent will cover half of the one before it.

This means we can go through exponents in descending order, with each successive random bit deciding whether we pick the current one or continue descending.

This is because each bit has a 50% chance of being 1, which coincides with each successive exponent covering 50% of the remaining space.

Exponent `00000000` (`2^-126`) being a special case (the same as `00000001` except significand starts with 0 instead of 1) means the two lowest exponents cover the same space. This saves us from requiring a special case for the last bit, where we decide between two exponents with a 50% chance for each.

I've tried to think of a way to sample an exponent with less bits, but didn't find one. In the end, because we need at least one bit to sample between `00000000` and `00000001` (one possible value for each), and each successive exponent covers double the space, we quickly arrive at requiring `2^125` values for the highest exponent `01111110`.

This is surprising because the underlying floating point number only has 32 bits, with the exponent taking up a single byte.

As to the sign and fraction, 1 and 23 random bits respectively will suffice, as there is no non-linearity to handle.

### Caveat

To be fair, just the 8 highest exponents cover over 99% of the `[0, 1)` interval.

The 8th highest exponent in `[0, 1)`, `01110111`, represents `2^8` - which means that number is also exactly the smallest we can express with that exponent.

Since `1 - 2^-8 = 0.99609375`, the 8th highest exponents in `[0, 1)` cover over 99.6% of that interval.

We can thus see that floating point numbers near 0 are highly biased towards extremely small values, in terms of representation space occupation.

From this we can conclude that sampling with a simpler technique may be sufficient most of the time.
