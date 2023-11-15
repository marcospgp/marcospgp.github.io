---
layout: post
title: How to approach a value each frame in a frame rate independent way
tag: Game Dev 👾
published: false
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

When working on games, it is common to want to move a value towards another over time.

For some instances of this, it is common to evaluate animation curves of all kinds. This requires:

1. A function that acts as the animation (aka easing) curve
1. Keeping track of start and end values
1. Keeping track of time elapsed

This allows for an animation perfectly grounded on time and independent of things like frame rate.

However, sometimes we don't want the calculation to stop. We want to keep approaching a target value forever, only relying on:

1. The last frame's result
1. How much time passed since the last frame
1. The target value (which may also change from frame to frame)

Note that the difference here is we no longer rely on:

1. The start value
1. The time elapsed

This means we also can't rely on a finite animation curve - as we no longer keep track of how much time has passed since we started.

The problem is that it's not obvious how to go about this in a way that results in the same animation curve for players rendering at different frame rates (such as 60fps vs 120fps).

---

{:footnotes}
