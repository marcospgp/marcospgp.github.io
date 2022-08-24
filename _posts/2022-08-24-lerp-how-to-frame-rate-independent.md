---
layout: post
title: How To Make Lerp Frame Rate Independent
---

* Why use lerp instead of the formula directly?
source for lerp: https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Math/Mathf.cs#L220
* Give Unity source code for the frame rate independent lerp

## The Problem

In {% post_link 2022-08-22-lerp %}, we saw that running lerp over multiple frames while reusing its result as the starting point for the next frame results in an exponential curve. We also started calling this an iterative lerp.

In {% post_link 2022-08-23-lerp-frame-rate-independent %}, we saw that an iterative lerp is sensitive to fluctuations in frame rate, but that making the lerp factor $$d$$ a multiple of the time between frames $$\Delta time$$ almost completely resolves the issue.

In this post, we set out to discover how to make an iterative lerp perfectly independent from frame rate.

## Frame Rate Independent Lerp

To study the behavior of an iterative lerp, we started with an intuitive series and moved towards a continuous function. In the last post, we saw how lerping iteratively from $$a$$ to $$b$$, with a factor $$d \in [0, 1]$$, as a function of the frames elapsed $$k$$ can be expressed as:

$$
\text{iterative_lerp}(a, b, d, k) = b - (b - a) \cdot (1 - d)^k
$$

Now that we want to make iterative lerp independent from frame rate, we can simply declare that it is now based on time by exchanging $$k$$ with a $$t$$:

$$
\text{iterative_lerp}(a, b, d, t) = b - (b - a) \cdot (1 - d)^t
$$

But obviously, this is not enough. We now need to work backwards from this expression and end up with something that we can implement in code.

We need to think in a series mindset once again, by seeing time as $$ t + u $$: $$t$$ being the time at the previous frame, and $$u$$ being the time since the last frame:

$$
\begin{aligned}

\text{iterative_lerp}(a, b, d, t + u) &= b - (b - a) \cdot (1 - d)^{t + u} \\

&= b - (b - a) \cdot (1 - d)^t \cdot (1 - d)^u

\end{aligned}
$$

And with a little magic, we can replace our dependence on $$t$$ with $$\text{iterative_lerp}(a, b, d, t)$$:

$$
\begin{aligned}

\text{iterative_lerp}(a, b, d, t + u) &= b - (b - a) \cdot (1 - d)^t \cdot (1 - d)^u \\

&= b + (b - (b - a) \cdot (1 - d)^t - b) \cdot (1 - d)^u \\

&= b + (\text{iterative_lerp}(a, b, d, t) - b) \cdot (1 - d)^u

\end{aligned}
$$

This means that we don't have to keep track of how much time has passed - we can simply reuse lerp's result from frame to frame, which is the whole point of an iterative lerp!
