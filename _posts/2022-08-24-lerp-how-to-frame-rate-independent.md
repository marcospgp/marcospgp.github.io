---
layout: post
title: a
published: false
---

* Why use lerp instead of the formula directly?
source for lerp: https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Math/Mathf.cs#L220
* Give Unity source code for the frame rate independent lerp

## The Problem

We want to find out if interpolate a value towards another over multiple frames without letting frame rate fluctuations affect the underlying animation curve.

For example, if we are changing the player's speed in a game, we want players running the game at different frame rates to see the same change in movement - to experience the same underlying animation curve.
