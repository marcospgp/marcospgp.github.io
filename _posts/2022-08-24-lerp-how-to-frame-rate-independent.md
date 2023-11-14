---
layout: post
title: How to Make Lerp Frame Rate Independent
description: How to smoothly move a value towards another while taking frame rate into account.
tag: Game Dev 👾
---

<div style="display: none;">
$$
\definecolor{LightBlue}{RGB}{156, 223, 237}
\newcommand{\highlight}[1]{\colorbox{Apricot}{$\displaystyle #1$}}
\newcommand{\highlightalt}[1]{\colorbox{LightBlue}{$\displaystyle #1$}}
$$
</div>

## Conclusion

To make an iterative[^1] lerp perfectly frame rate independent, all we have to do is switch $$a$$ and $$b$$ and make the factor $$d$$ an exponential of $$\Delta time$$:

[^1]: An iterative lerp means running lerp over multiple frames while reusing its result as the starting point for the next frame.

```csharp
public void Update() {
    this.value = Mathf.Lerp(
        this.target,
        this.value,
        Mathf.Pow(1f - this.delta, Time.deltaTime)
    );
}
```

`this.delta` controls how much we move `this.value` towards `this.target` per second.

## The Problem

In {% post_link 2022-08-22-lerp %}, we saw that running lerp over multiple frames while reusing its result as the starting point for the next frame results in an exponential curve. We also started calling this an iterative lerp.

In {% post_link 2022-08-23-lerp-frame-rate-independent %}, we saw that an iterative lerp is sensitive to fluctuations in frame rate, but that making the lerp factor $$d$$ a multiple of the time between frames $$\Delta time$$ almost completely resolves the issue.

In this post, we set out to discover how to make an iterative lerp perfectly independent from frame rate.

## Frame Rate Independent Lerp

To study the behavior of an iterative lerp, we started with an intuitive series and moved towards a continuous function. In the last post, we saw how lerping iteratively from $$a$$ to $$b$$, with a factor $$d \in [0, 1]$$, as a function of the frames elapsed $$k$$ can be expressed as:

$$
\text{iterative_lerp}(a, b, d, k) = b - (b - a) \cdot (1 - d)^k
$$

Now that we want to make iterative lerp independent from frame rate, we can start by declaring that it is based on time, not frames elapsed. We can make this clearer by exchanging $$k$$ with a $$t$$:

$$
\text{iterative_lerp}(a, b, d, t) = b - (b - a) \cdot (1 - d)^t
$$

This means that $$d$$ will now represent how much to move towards the target per **second**, instead of per frame.

We now need to get rid of the $$t$$ parameter before using this formula in code - otherwise, we would have to keep track of the time elapsed since the start of the interpolation. We want to instead rely on the previous frame's interpolation result, which is the idea behind an iterative lerp.

We can think of $$t$$ as the time elapsed at the last frame, and $$u$$ as the time since the last frame. This means the time at the current frame can be expressed as $$t + u$$:

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

&= b + (\highlightalt{b} - (b - a) \cdot (1 - d)^t \highlightalt{- b}) \cdot (1 - d)^u

\quad\text{(add and remove }b\text{)} \\

&= b + (\highlight{b - (b - a) \cdot (1 - d)^t} - b) \cdot (1 - d)^u \\

&= b + (\highlight{\text{iterative_lerp}(a, b, d, t)} - b) \cdot (1 - d)^u

\end{aligned}
$$

And since $$ \text{iterative_lerp}(a, b, d, t) $$ is last frame's result, which we will use as the starting value $$a$$ in the next frame, we can simplify the expression:

$$
\tag{1}\label{1}

\begin{aligned}

\text{iterative_lerp}(a, b, d, t + u) &= b + (\highlight{\text{iterative_lerp}(a, b, d, t)} - b) \cdot (1 - d)^u \\

&= b + (\highlight{a} - b) \cdot (1 - d)^u

\end{aligned}
$$

Now taking another look at lerp's definition:

$$ lerp(a, b, d) = a + (b - a) \cdot d $$

We see that $$\eqref{1}$$ is the same as lerp, only with $$a$$ and $$b$$ switched and with $$(1-d)^u$$ taking the place of the factor $$d$$:

$$
\begin{aligned}

\text{iterative_lerp}(a, b, d, t + u) &= b + (a - b) \cdot (1 - d)^u \\

&= \highlight{\text{lerp}(b, a, (1-d)^u)}

\end{aligned}
$$

Remember that $$u$$ is the time since the last frame $$\Delta time$$, which in the Unity game engine can be referenced as `Time.deltaTime`.

This means that to make an iterative lerp perfectly frame rate independent, all we have to do is switch $$a$$ and $$b$$ and make the factor $$d$$ an exponential of $$\Delta time$$:

```csharp
public void Update() {
    this.value = Mathf.Lerp(
        this.target,
        this.value,
        Mathf.Pow(1f - this.delta, Time.deltaTime)
    );
}
```

`this.delta` controls how much we move `this.value` towards `this.target` per second.

We use Unity's `Mathf.Lerp()` here but don't necessarily have to - [their implementation](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Math/Mathf.cs#L220) is plain C# code and not some lower level magically efficient concoction.

## Making it better

Now we arrived at the result above because we wanted to build something exactly like a plain iterative lerp but with a simple change: the lerp factor $$d$$

## Open Question

We made lerp in particular frame rate independent because it is so commonly used and there's a higher chance people are using it wrong. But can the same process be done for other animation curves? Does the $$f(t + u)$$ trick work for a $$sin$$ curve or a parabola?

If not, then maybe there is something special about lerp after all. Perhaps it has something to do with the derivative of $$e^x$$ being $$e^x$$.

## Acknowledgements

["Improved Lerp Smoothing" by Scott Lembcke on Game Developer](https://www.gamedeveloper.com/programming/improved-lerp-smoothing-)

["Frame Rate Independent Damping Using Lerp" by Rory Driscoll](https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/)

---

{:footnotes}
