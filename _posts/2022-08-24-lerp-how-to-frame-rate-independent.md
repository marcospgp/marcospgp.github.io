---
layout: post
title: How To Make Lerp Frame Rate Independent
description: How to smoothly move a value towards another while taking frame rate into account.
---

<div style="display: none;">
$$
\definecolor{LightBlue}{RGB}{156, 223, 237}
\newcommand{\highlight}[1]{\colorbox{Apricot}{$\displaystyle #1$}}
\newcommand{\highlightalt}[1]{\colorbox{LightBlue}{$\displaystyle #1$}}
$$
</div>

## Conclusion

To make an iterative lerp perfectly frame rate independent, all we have to do is switch $$a$$ and $$b$$ and make the factor $$d$$ an exponential of $$\Delta time$$:

{% highlight csharp %}
public void Update() {
    this.value = Mathf.Lerp(
        this.target,
        this.value,
        Mathf.Pow(1f - this.delta, Time.deltaTime)
    );
}
{% endhighlight %}

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

Instead of representing how much to move $$a$$ towards the target value $$b$$ each **frame**, $$d$$ will now represent how much to move towards the target per **second**.

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

&= b + (\highlight{b} - (b - a) \cdot (1 - d)^t \highlight{- b}) \cdot (1 - d)^u

\quad\text{(add and remove }b\text{)} \\

&= b + (\highlightalt{b - (b - a) \cdot (1 - d)^t} - b) \cdot (1 - d)^u \\

&= b + (\highlightalt{\text{iterative_lerp}(a, b, d, t)} - b) \cdot (1 - d)^u

\end{aligned}
$$

This means that we don't have to keep track of how much time has passed - we can simply reuse lerp's result from frame to frame, which is the whole point of an iterative lerp!

And since $$ \text{iterative_lerp}(a, b, d, t) $$ is last frame's result, which we will use as $$a$$ in the next frame, we can simplify the expression:

$$
\tag{1}\label{1}

\begin{aligned}

\text{iterative_lerp}(a, b, d, t + u) &= b + (\highlightalt{\text{iterative_lerp}(a, b, d, t)} - b) \cdot (1 - d)^u \\

&= b + (\highlightalt{a} - b) \cdot (1 - d)^u

\end{aligned}
$$

Now taking another look at lerp's definition:

$$ lerp(a, b, d) = a + (b - a) \cdot d $$

We see that $$\eqref{1}$$ is the same as lerp, only with $$a$$ and $$b$$ switched and with $$(1-d)^u$$ taking the place of the factor $$d$$:

$$
\begin{aligned}

\text{iterative_lerp}(a, b, d, t + u) &= b + (a - b) \cdot (1 - d)^u \\

&= \text{lerp}(b, a, (1-d)^u)

\end{aligned}
$$

Remember that $$u$$ is the time since the last frame $$\Delta time$$, which in the Unity game engine can be referenced as `Time.deltaTime` from anywhere in the code.

This means that to make an iterative lerp perfectly frame rate independent, all we have to do is switch $$a$$ and $$b$$ and make the factor $$d$$ an exponential of $$\Delta time$$:

{% highlight csharp %}
public void Update() {
    this.value = Mathf.Lerp(
        this.target,
        this.value,
        Mathf.Pow(1f - this.delta, Time.deltaTime)
    );
}
{% endhighlight %}

`this.delta` controls how much we move `this.value` towards `this.target` per second.

## Why Use Lerp()

Is there a reason to use Unity's `Mathf.Lerp()` over defining the formula yourself? Not really, as [their implementation](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Math/Mathf.cs#L220) is plain C# code and nothing particularly optimized.

## Acknowledgements

["Improved Lerp Smoothing" by Scott Lembcke on Game Developer](https://www.gamedeveloper.com/programming/improved-lerp-smoothing-)

["Frame Rate Independent Damping Using Lerp" by Rory Driscoll](https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/)
