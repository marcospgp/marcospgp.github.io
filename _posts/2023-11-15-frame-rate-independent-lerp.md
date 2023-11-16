---
layout: post
title: On Frame Rate Independence
description: Diving into how we can determine whether some way of iteratively updating a value will be affected by variations in time step.
tag: Game Dev 👾
---

## The Problem

When working on iterative simulations - such as games - we frequently want to animate a value over time.

There are two ways to go about this:

1. Calculate the current value given a starting value and time elapsed (an animation curve)
2. Update the value given the time since the last step (such as moving forward at a given speed)

Option 2 does not require keeping track of starting value nor time elapsed. It is especially attractive when we don't have an end in sight - meaning no fixed duration.

It allows us to build an iterative process that does something indefinitely.

A common use case is applying lerp (linear interpolation) every frame to move a value `a` towards a value `b` over time:

```text
lerp(a, b, d) = a + (b - a) * d
```

Where the factor `d` is a value between 0 and 1 representing the fraction of distance to cover.

We can run lerp iteratively like so:

```text
a = lerp(a, b, d)
```

This means using the last frame's result as the starting value for the next frame.

An issue becomes apparent - this process is entirely dependent on frame rate. Running this at 30fps will cause a slower change in real time than running it at 120fps.

A common workaround is to multiply the factor `d` by the time elapsed since the last frame `delta_time`:

```text
a = lerp(a, b, d * delta_time)
```

While this helps, it is not a real solution - as we will see below.

The problem we are interested in is: how can we know whether an iterative process is independent from frame rate?

We can begin by thinking about lerp specifically - and how we can make it independent from variations in `delta_time` (the time between simulation steps).

## Iterative lerp is an exponential curve

When running lerp iteratively, we reduce the distance to the target value by a factor `d` each frame. The fraction of remaining distance is thus `1 - d`. After `n` iterations, the fraction of remaining distance is `(1 - d)^n`.

For example, with `d = 0.1`, after 3 iterations we will have `0.9 * 0.9 * 0.9 = 0.729` of the remaining distance.

This means we can express the resulting value at frame `n` with:

`f(n) = b - (b - a) * (1 - d)^n`

Which shows the underlying curve is exponential.

## Making lerp frame rate independent

We can relate the number of iterations to the elapsed time `t`, given a constant `delta_time` representing the time between iterations:

`n = t / delta_time`

This means we can update the `f(n)` expression we saw above to `f(t)` by replacing `n` with `t / delta_time`:

`f(t) = b - (b - a) * (1 - d)^(t / delta_time)`

If you plot this function with varying values for `delta_time`, you will see that an iterative lerp with a constant factor `d` is dependent on frame rate (which is kind of obvious).

The previously mentioned common solution of multiplying the factor `d` by `delta_time` will not entirely solve this issue:

`f(t) = b - (b - a) * (1 - (d * delta_time))^(t / delta_time)`

If you plot this function, you will see that varying `delta_time` still has an effect, albeit smaller.

To negate the effect of variations in `delta_time`, we have to cancel it out of the equation. We can do this by turning the factor `d` into `1 - d^delta_time`:

```text
f(t) = b - (b - a) * (1 - (1 - d^delta_time))^(t / delta_time)
     = b - (b - a) * (d^delta_time)^(t / delta_time)
     = b - (b - a) * d^t
```

Our frame rate independent iterative lerp should then look like:

```text
a = lerp(a, b, (1 - d^delta_time))
```

We can also reason that `d` now means "fraction of distance remaining after 1 second", because at `t = 1`, `b - (b - a) * dˆt` becomes `b - (b - a) * d`.

Note that `d` should be a value between 0 and 1.

## Caveats

The reasoning so far assumed everything remained constant throughout the simulation.

However, the target value `b` and the time between iterations `delta_time` may change dynamically, perhaps even on every iteration.

This may have an effect that is dependent on frame rate.

## Generalizing

### Formalizing

The reasoning we used above can be formalized, so we can hopefully apply it to any iterative process.

The main idea is to start with a recursive sequence:

```text
S(0) = a
S(n) = f(S(n-1))
```

Where `a` is a constant representing the starting value, and function `f` can be anything you do in code (as long as you can express it mathematically).

We will use lerp as an example from here on out. It can be expressed as the following function (with constants `b` and `d`):

```text
f(x) = x + (b - x) * d
```

Once you have a function `f`, you can expand it in the sequence:

```text
S(0) = a
S(n) = S(n-1) + (b - S(n-1)) * d
```

### Removing recursion

The next step is to somehow make the sequence non-recursive. This is not straightforward and there is no clear path, but a good general approach is to expand `S(n-1)` backwards a few steps (into `S(n-2)`, `S(n-3)`), and noting patterns - such as a series that can be replaced by a formula for the sum of its first `n` terms.

```text
S(0) = a
S(n) = S(n-1) + (b - S(n-1)) * d
     = S(n-1) * (1 - d) + db
     = (S(n-2) * (1 - d) + db) * (1 - d) + db
     = ([S(n-3) * (1 - d) + db] * (1 - d) + db) * (1 - d) + db
```

Now that we have quite a long expression, we can reorganize it a bit:

```text
S(n) = ([S(n-3) * (1 - d) + db] * (1 - d) + db) * (1 - d) + db

     (start by reversing it to make it easier to read left-to-right)
     = db + (1 - d) * (db + (1 - d) * [db + (1 - d) * S(n-3)])

     = db + (1 - d) * db + (1 - d)^2 * db + (1 - d)^3 * S(n-3)
```

We can see two patterns above:

```text
db + (1 - d) * db + (1 - d)^2 * db
```

and

```text
(1 - d)^3 * S(n-3)
```

The first pattern is a geometric series - which has the following formula for the sum of the first `n` terms:

```text
a + ar + ar^2 + ... + ar^(n-1) = a * (1 - r^n) / (1 - r)
```

So with `a = db` and `r = (1 - d)` we can change it into the following:

```text
db + (1 - d) * db + (1 - d)^2 * db

  = db * (1 - (1 - d)^n) / (1 - (1 - d))
  = db * (1 - (1 - d)^n) / d
  = b * (1 - (1 - d)^n)
```

The second pattern can be dealt with through a simple replacement:

```text
(1 - d)^3 * S(n-3) = (1 - d)^n * a
```

Note that eventually the remaining `S(n-3)` term will become `a`, which is the starting value of the sequence.

So by adding back together the the two patterns, `S(n)` becomes:

```text
S(n) = b * (1 - (1 - d)^n) + (1 - d)^n * a
     = b - (b * (1 - d)^n) + (1 - d)^n * a
     = b + (1 - d)^n * (a - b)
```

And now `S(n)` is no longer a recursive expression:

```text
S(n) = b + (1 - d)^n * (a - b)
```

### Turning frames to time

The next step is to evaluate the expression as a function of time, not iterations (or frames elapsed).

We can use the following expression to convert frames `n` to time `t`, given a constant time between frames `delta_time`:

`n = t / delta_time`

We can now change the expression to:

```text
S(t) = b + (1 - d)^(t / delta_time) * (a - b)
```

The effect of variations in `delta_time` should now become clear. In this case, we can compensate for it by adjusting the `d` constant in order to cancel `delta_time` out of the expression:

```text
d = (1 - u^delta_time)

S(t) = b + (1 - (1 - u^delta_time))^(t / delta_time) * (a - b)
     = b + (u^delta_time)^(t / delta_time) * (a - b)
     = b + u^t * (a - b)
```

Which as we saw before, is equivalent to running lerp iteratively as follows:

```text
a = lerp(a, b, (1 - u^delta_time))
```

## Questions at this point

1. Is the geometric series/exponential curve special in this scenario? Or can other curves be made independent from frame rate?
2. Is there a way to guarantee that an iterative process will be independent of frame rate even when `b` and `delta_time` change between iterations?
3. When the factor `d` for lerp becomes `(1 - u^delta_time)` above, does `u` now have a human understandable meaning? Experimentally, it appears to mean "fraction of distance remaining after 1 second".

Regarding question 2, we know that keeping track of starting value and time elapsed allows us to make something 100% frame rate independent. It basically allows us to skip the whole recursive sequence reasoning and jump into evaluating a function based on time. Maybe that is a clue on arriving at an answer.
