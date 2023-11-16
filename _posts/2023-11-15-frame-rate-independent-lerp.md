---
layout: post
title: How to approach a value each frame in a frame rate independent way
tag: Game Dev 👾
---

<div style="display: none;">
$$
\definecolor{LightBlue}{RGB}{156, 223, 237}
\newcommand{\highlight}[1]{\colorbox{Apricot}{$\displaystyle #1$}}
\newcommand{\highlightalt}[1]{\colorbox{LightBlue}{$\displaystyle #1$}}
$$
</div>

## The Problem

When working on iterative simulations - such as games - we frequently want to move a value towards another over time.

There are two ways to go about this:

1. Evaluate an animation function with a time parameter
2. Iteratively update the value each frame (without keeping track of elapsed time)

Option 1 is best suited for scenarios where the animation is finite, but option 2 is a better choice when we want to move towards a target value indefinitely.

A common approach for option 2 is to use lerp (linear interpolation):

```text
lerp(a, b, d) = a + (b - a) * d
```

Where `d` is a value between 0 and 1 representing the fraction of distance to cover.

We can run lerp iteratively like so:

```text
a = lerp(a, b, d)
```

This means using the last frame's result as the starting value for the next frame.

An issue becomes apparent - unlike animation curves in option 1, which keep track of elapsed time, this iterative approach is not necessarily frame rate independent, and in this case, entirely dependent on frame rate.

A common workaround is to multiply the factor `d` by the time elapsed since the last frame `delta_time`:

```text
a = lerp(a, b, d * delta_time)
```

While this helps, it is not a real solution - as we will see below.

The problem is thus: how do we iteratively approach a target value in a frame rate independent way?

This means making an animation appear the same for a player running a game at 60fps and another playing at 120fps, or even for the same player when their frame rate varies during play time.

## Iterative lerp is an exponential curve

When running lerp iteratively, we reduce the distance to the target value by a factor `d` each frame. The fraction of remaining distance is thus `1 - d`. After `n` iterations, the fraction of remaining distance is `(1 - d)^n`.

For example, with `d = 0.1`, after 3 iterations we will have `0.9 * 0.9 * 0.9 = 0.729` of the remaining distance.

This means we can express the resulting value at frame `n` with:

`f(n) = b - (b - a) * (1 - d)^n`

Which shows the underlying curve is exponential.

We could also arrive at this conclusion by expressing an iterative lerp as a sequence:

```text
S(0) = a
S(n) = S(n-1) + (b - S(n-1)) * d
```

Then expanding `S(n-1)` into `S(n-2)`, then `S(n-3)`, and noting patterns such as a geometric series - and replacing it with its sum formula:

```text
a + ar + ar^2 + ... + ar^(n-1) = a * (1-r^n) / (1-r)
```

## Making lerp frame rate independent

Now we know the resulting value for `a` after `n` iterations of `a = lerp(a, b, d)` can be expressed as:

`f(n) = b - (b - a) * (1 - d)^n`

Since we know that, given elapsed time `t` and a constant `delta_time` representing the time between frames:

`n = t / delta_time`

We can replace `n` in the expression above:

`f(t) = b - (b - a) * (1 - d)^(t / delta_time)`

If you plot this function with varying values for `delta_time`, you will see the obvious - an iterative lerp with a constant factor `d` varies depending on frame rate.

However the common solution previously shown of multiplying the factor `d` by `delta_time` will not entirely solve this issue:

`f(t) = b - (b - a) * (1 - (d * delta_time))^(t / delta_time)`

If you plot this function, you will see that varying `delta_time` still has an effect, albeit smaller.

To negate the effect of variations in `delta_time`, we have to cancel it out of the equation. We can do this by turning the factor `d` into `1 - d^delta_time`:

```text
f(t) = b - (b - a) * (1 - (1 - d^delta_time))^(t / delta_time)
     = b - (b - a) * (d^delta_time)^(t / delta_time)
     = b - (b - a) * d^t
```

A caveat is that while this makes lerping iteratively perfectly frame rate independent for a constant target value, this is not so true when the target value also changes over time, as it will change at different times for simulations running at different frame rates.

This effect however should be much less noticeable than the issues covered previously.
