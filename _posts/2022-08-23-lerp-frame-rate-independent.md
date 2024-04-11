---
title: "Is Lerp Frame Rate Independent?"
tag: Game Dev 👾
published: false
---

{% comment %}
This post has been unpublished because it was not accurate.
There is a new post with correct information.
{% endcomment %}

In this post, we find out that interpolating a value towards another over multiple frames is affected by fluctuations in frame rate, but that this is almost entirely fixed by a very popular solution - taking the time between frames (commonly referenced as delta time) into account.

## The Problem

We want to find out if interpolating a value towards another over multiple frames is affected by fluctuations in frame rate, and if so, how much.

## Iterative Lerp

The lerp (linear interpolation) function is commonly used in games to make a variable $$a$$ smoothly approach a target value $$b$$ over multiple frames, moving a fraction $$d \in [0, 1]$$ of the remaining distance each frame:

$$ lerp(a, b, d) = a + (b - a) \cdot d $$

In this context, running an iterative lerp means to use its result as the starting point $$a$$ for the following frame.

In {% post_link 2022-08-22-lerp %}, we saw that an iterative lerp from 0 to 1 with a factor $$d \in [0, 1]$$ given a frame number $$k$$ can be written as:

$$ \text{iterative_lerp}(0, 1, d, k) = 1 - (1 - d)^k $$

Which represents an exponential curve:

<iframe src="https://www.desmos.com/calculator/boqlzhkqzg" width="800" height="450" style="border: 1px solid #ccc" frameborder=0></iframe>

We can generalize this expression for any start and end values $$a$$ and $$b$$ by scaling the function vertically:

$$
\tag{1}\label{1}

\begin{aligned}

\text{iterative_lerp}(a, b, d, k) &= a + (b - a) \cdot (1 - (1 - d)^k) \\

&= a + b - a - (b - a) \cdot (1 - d)^k \\

&= b - (b - a) \cdot (1 - d)^k

\end{aligned}
$$

## Turning Frames to Time

We are currently defining lerp as a function of frames elapsed, which is good enough when we assume a steady frame rate. This is, however, almost never the case in real world applications.

We can translate frames to time given a time between frames $$\Delta time$$:

$$
\begin{aligned}

t &= k \cdot \Delta time \\

k &= \frac{t}{\Delta time}

\end{aligned}
$$

We can thus replace $$k$$ in $$\eqref{1}$$:

$$
\begin{aligned}

\text{iterative_lerp}(a, b, d, k) &= b - (b - a) \cdot (1 - d)^k \\

\text{iterative_lerp}(a, b, d, t) &= b - (b - a) \cdot (1 - d)^{\frac{t}{\Delta time}}

\end{aligned}
$$

And now we can visualize an iterative lerp as a function of time:

<iframe src="https://www.desmos.com/calculator/wysqvzgvpt" width="800" height="450" style="border: 1px solid #ccc" frameborder=0></iframe>

By dragging the slider for the $$\Delta time$$ (represented as $$D$$), we can see how variations in the frame rate affect the curve. A frame rate of 30 frames per second is $$D = \frac{1}{30} = 0.0333...$$, and a frame rate of 120 frames per second is $$D = \frac{1}{120} = 0.008333...$$.

The factor $$d$$ still determines how much $$a$$ moves towards $$b$$ **per frame**, even though the horizontal axis now represents time.

## An Imperfect Solution

A common solution for iterative lerp's frame rate dependence is to multiply the factor $$d$$ by $$\Delta time$$:

$$
\text{iterative_lerp}(a, b, d, t) = b - (b - a) \cdot (1 - (d \cdot \Delta time))^{\frac{t}{\Delta time}}
$$

And we can see it on a graph:

<iframe src="https://www.desmos.com/calculator/wustamboeu" width="800" height="450" style="border: 1px solid #ccc" frameborder=0></iframe>

And indeed this makes a big difference, but as we can see by again dragging the slider for $$D$$, the curve is still slightly affected by changes in frame rate.

I was actually surprised to see how little of a difference it makes! Is it even worth it to worry about making lerp perfectly frame rate independent for non competitive games? And even for competitive games, since the game logic will likely be running at a fixed framerate on the server side?

Perhaps multiplying $$d$$ by $$\Delta time$$ is good enough. But good enough is not good enough for us, so we shall battle on!

Check out part 3, {% post_link 2022-08-24-lerp-how-to-frame-rate-independent %}, where we finally find out how to make an iterative lerp perfectly independent from fluctuations in frame rate.

## Acknowledgements

["Improved Lerp Smoothing" by Scott Lembcke on Game Developer](https://www.gamedeveloper.com/programming/improved-lerp-smoothing-)

["Frame Rate Independent Damping Using Lerp" by Rory Driscoll](https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/)
