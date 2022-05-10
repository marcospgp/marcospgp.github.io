---
layout: post
title: FNV 1a Hash in C#
---

I needed a hashing algorithm that is simple to implement and quick to compute, to be used as a basis
for generating perlin noise in Unity.

I couldn't rely on simple randomness since terrain generation has to be deterministic, especially for multiplayer games.

I ended up implementing the [Fowler–Noll–Vo 1a hash](http://www.isthe.com/chongo/tech/comp/fnv/index.html), which checks those boxes. Perhaps the code may help someone else, so I'm sharing it below.

<script src="https://gist.github.com/marcospgp/ed991372f1c814eb21b8b248db258187.js"></script>
