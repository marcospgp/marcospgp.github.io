---
layout: post
title: On Frame Rate Independence
description: Diving into how we can determine whether some way of iteratively updating a value will be affected by variations in time step.
tag: Game Dev 👾
---

## The Problem

Computer simulations - such as games - involve calculating the state of a system repeatedly, over time.

The time interval between these simulation steps can be variable - which is why the "frame rate" in games (number of simulation steps per second) can vary over time.

This iterative process of calculating successive simulation states, often with variable time steps, is commonly known as the "render loop".

Physics are commonly calculated in a separate loop running on a fixed time interval - the physics loop - that is run parallel to the render loop. Given enough complexity, it can be impossible to obtain exactly the same progression over time for simulations running at different time steps, so the time step is fixed.

For many kinds of computations, however, the render loop is fine - and a lot of game logic ends up being placed there.

Intuitively, we know how to make things in the render loop independent of fluctuations in time step, by making use of `delta_time` - the time elapsed since the last step.

For example, updating a position with a given velocity can be done with:

```text
position = position + (velocity * delta_time)
```

This feels intuitive, and we think of this as something like explaining the update in terms of "change per second".

But intuition is not enough. For example, if we introduce acceleration - a change to velocity over time - it is no longer obvious what the resulting frame rate independent formula should be.

A first guess could be:

```text
velocity = velocity + (acceleration * delta_time)
position = position + (velocity * delta_time)
```

But this is not frame rate independent. A player running this at 60fps will see a different result from a player running it at 30fps.

The actual frame rate independent formulation is:

```text
position = position + (velocity * delta_time) + (1/2 * acceleration * delta_time)
velocity = velocity + (acceleration * delta_time)
```

Which amounts to updating the position with the average velocity over the time step.

But how could we have arrived at this solution? And more importantly, how can we calculate a frame rate independent formula for any kind of computation that we may want to run with a variable time step?

## An aside: using absolute time

A simple way of obtaining frame rate independence is to make use of total time elapsed, instead of updating a value iteratively using delta time.

This is common for animations with fixed durations, and fits with the concept of easing curves. These are functions with `f(0) = 0` and `f(1) = 1`, representing a curve that can be multiplied by a value one wants to animate over the duration of the animation.

For example, with an easing curve `f(t) = t^2` one can animate a value with:

```text
t = time_elapsed / total_duration
value = start_value + (target_value * f(t))
```

Evaluating a function using absolute time will always be independent from frame rate, because the number of iterations does not affect how much time has elapsed. After `x` seconds, `x` seconds will have elapsed, regardless of how many frames we rendered along the way. And thus the result will look the same.

## Using delta time

We can't always rely on total time elapsed. Sometimes we want to formulate a computation based on updating a value iteratively, only taking `delta_time` into account.

To think about this, we can start by looking for a deeper underlying meaning of "frame rate independence".

It may be put this way: any step with `delta_time` of `x` should be equivalent to any number of steps whose `delta_time` adds up to `x`.

We can simplify this into:

Any step with `delta_time` of `x` should be divisible into two steps with `delta_time`s `y` and `z` where `x = y + z`.

Because if a step is divisible into two, we can keep dividing arbitrarily into any number of steps.

This can be expressed mathematically as:

```text
f(a, t1 + t2) = f(f(a, t1), t2)
```

Given a function `f(a, d)` that updates a state `a` given a `delta_time` `d`.

I found out by asking on the game development [stack exchange](https://gamedev.stackexchange.com/a/207937/43966) that this is equivalent to [flow](<https://en.wikipedia.org/wiki/Flow_(mathematics)>) in mathematics.

## Flow

I was amazed at how closely the concept of flow lines up with frame rate independence. It is basically the exact same thing.

What we know about flows is that given a differential equation

```text
dx/dt = F(x(t))
```

The solution `x(t)` is a flow - which means it is frame rate independent.

In other words, anything we can specify in terms of a change over time (differential equation), then solve, results in an expression we can use iteratively with variable time steps.

We can also use flow directly to check whether a given function is frame rate independent, by simply expanding its expression and checking if the two sides are indeed equal.

## Example: motion with constant acceleration

Let's use motion with constant acceleration as an example.

We know that

```text
dv/dt = a
```

and

```text
dx/dt = v
```

Solving the first equation, we obtain:

```text
v(t) = v0 + at
```

Updating the second equation:

```text
dx/dt = v0 + at
```

And solving it:

```text
x(t) = x0 + (v0 * t) + (1/2 * a * t^2)
```

To run this iteratively, we can translate it into the following code:

```text
x = x + (v * delta_time) + (1/2 * a * delta_time^2)
v = v + (a * delta_time)
```

Note we update `x` first because at that point `v = v0`.

## Why does physics run in a fixed-time-step loop?

You may be wondering why then does physics have to run in a fixed time step if we could solve the underlying differential equations and use the resulting "flow" in a frame rate independent way.

The problem is there isn't always a solution to the differential equations. And even if there is one, we do not necessarily know how to get to it. And if we do, it may be too complex, inefficient, or in some other way non-ideal for the intended simulation use-case.

This is why physics engines rely on "integrators", which are ways of solving differential equations without a closed form solution. Some commonly used ones are Euler, Verlet, and Runge-Kutta - each offering varying trade-offs.

## Example 2: iterative lerp

A common use case is to use lerp (linear interpolation) iteratively to make a value approach another over time, forever.

This can be used to, for example, constantly update the player speed towards a
target speed, which changes when player inputs change.

The lerp function is defined as:

```text
lerp(a, b, d) = a + (b - a) * d
```

And what it does is move a value `a` towards a value `b` by a factor `d` with a value between 0 and 1.

An often used yet frame rate dependent (basically, incorrect) way of running it iteratively is:

```text
a = lerp(a, b, d * delta_time)
```

To make lerp properly frame rate independent, we can observe that what it does is reduce a distance by a given factor. Naturally, we will want to make it reduce a distance by a given factor **per second**.

This is equivalent to exponential decay - which is a popular differential equation:

```text
da/dt = -ka
```

It reflects a scenario where the amount of something decreases at a rate proportional to the amount left.

To make our frame rate independent lerp, we can start by formulating a similar differential equation:

```text
da/dt = (b - a) * d
```

Which has the following solution:

```text
a(t) = b + C * e^(-dt)
```

Where C is an arbitrary constant.

Remember that because that because `a(t)` is a solution to a differential equation, we know it is frame rate independent.

To make `a(t)` start at a constant `a` and move towards a constant `b`, we can say that:

```text
C = a - b

a(t) = b + (a - b) * e^(-dt)
```

Let's also recall that:

```text
lerp(a, b, d) = a + (b - a) * d
```

We can try to modify `a(t)` in order to try to match lerp's format:

```text
a(t) = b + (a - b) * e^(-dt)
     (add and remove a)
     = a + (a - b) * e^(-dt) + (b - a)
     = a + (b - a) * (1 - e^[-dt])
```

Now `a(t)` looks very much like lerp. There is only one thing left - we would like to specify a factor `d` that would represent the amount of time until there's half of the original value remaining, which is equivalent to the concept of "half life" in exponential decay.

To do so, we need to find `k(d)` such that:

```text
1 - e^(-k(d) * t) = 0.5
```

When `t = d`.

Solving for `k(d)`:

```text
1 - e^(-k(d) * d) = 0.5
  <=> e^(-k(d) * d) = 0.5
  <=> ln(0.5) = -k(d) * d
  <=> k(d) = -ln(0.5) / d
```

Replacing `d` with `k(d)` in `a(t)`:

```text
a(t) = a + (b - a) * (1 - e^[-dt])
     (replace d with k(d))
     = a + (b - a) * (1 - e^[-(-ln(0.5) / d) * t])
     = a + (b - a) * (1 - e^[(ln(0.5) / d) * t])
     = a + (b - a) * (1 - 0.5^[t / d])
```

Now we can see that to call lerp iteratively in a frame rate independent way, with a factor `d` representing "time until half of original distance remains", we can use:

```text
a = lerp(a, b, 1 - 0.5^(delta_time / d))
```

To minimize the effect of floating point imprecision, because `delta_time` will tend to be very small, we can rearrange the order of operations:

```text
a = lerp(a, b, 1 - (0.5^delta_time)^(1 / d))
```

## The way here

It has been a long time thinking about frame rate independence before arriving at this point. Trying to use lerp in a frame rate independent way is what prompted me down this path initially.

My initial approach began by formulating an iterative lerp:

```text
a = lerp(a, b, d)
```

As a recursive series:

```text
S(0) = a
S(n) = S(n-1) + (b - S(n-1)) * d
```

Then obtaining a closed form expression - a function `f(n)` that returns the value of `a` after `n` frames have elapsed:

```text
f(n) = b + (a - b) * (1 - d)^n
```

Knowing that frames elapsed relate to time in the following manner:

```text
n = t / delta_time
```

Where `t` is total time elapsed, and `delta_time` is the interval between frames (assumed constant), we can replace `n` to obtain the following expression:

```text
f(t) = b + (a - b) * (1 - d)^(t / delta_time)
```

We now can try to find out how to change the factor `d` such that variations in `delta_time` will not affect the resulting value - in essence, cancelling it out of the equation.

This can be done with:

```text
d -> (1 - d^delta_time)
```

As we can see by making this replacement in the expression above:

```text
f(t) = b + (a - b) * (1 - (1 - d^delta_time))^(t / delta_time)
     = b + (d^delta_time)^(t / delta_time) * (a - b)
     = b + d^t * (a - b)
```

`delta_time` is successfully cancelled out.

This is equivalent to calling lerp with:

```text
lerp(a, b, 1 - d^delta_time)
```

The difference here is that we lost the meaning of the factor `d`, but we could still restore it by calculating a function `k(d)` such that half of the original distance would remain after `d` seconds, similar to what we did above.

Also, sums of series are closely related to integrals (and thus differential equations), so I'm not very surprised that this approach sort of worked.

### Obtaining the closed form expression

We skipped over this step before, but if you're curious about how we can turn the recursive series:

```text
S(0) = a
S(n) = S(n-1) + (b - S(n-1)) * d
```

Into a closed form expression, which is the one we already saw above:

```text
f(n) = b + (a - b) * (1 - d)^n
```

A good general approach is to expand `S(n-1)` backwards a few steps (into `S(n-2)`, `S(n-3)`), and to look for patterns that can be replaced with sum formulas.

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
     = b + (a - b) * (1 - d)^n
```

And now `S(n)` is no longer a recursive expression:

```text
S(n) = b + (a - b) * (1 - d)^n
```

## Caveats

### Floating point

Floating point imprecision trumps mathematical perfection, so be wary of issues arising from that.

### Constants which aren't constant in reality

We assumed that most things remain constant in our frame rate independent formulations, but in practice things will change at run time in many scenarios.

Frame rate independence is not perfect in this case because values will change at slightly different wall times for players running a game at different frame rates. This effect should be very small in practice, however.

The only solution for that that I can think of is to fix the timestep, just like one typically does for physics, and should always do for competitive multiplayer games.
