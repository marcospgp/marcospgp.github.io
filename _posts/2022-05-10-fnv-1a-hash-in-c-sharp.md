---
layout: post
title: FNV 1a Hash in C#
---

I needed a hashing algorithm that is simple to implement and quick to compute, to be used as a basis
for generating perlin noise in Unity.

I couldn't rely on simple randomness since terrain generation has to be deterministic, especially for multiplayer games.

I ended up implementing the [Fowler–Noll–Vo 1a hash](http://www.isthe.com/chongo/tech/comp/fnv/index.html), which checks those boxes. Perhaps the code may help someone else, so I'm sharing it below.

You can use the `DebugTexture` method to get a sample of what it looks like:

![Hash with tricks]({% link assets/2022-05-10-fnv-1a-hash-in-c-sharp/hash-with-tricks.jpg %})

I used a couple tricks to get the hash to look as close as possible to white noise when passing in the coordinates as floats.

The first one is to multiply each coordinate by one of the algorithm's parameters (the prime number), which gets the bits away from being almost all 0s when hashing low values.

The second is to hash the bytes in a random sequence. This randomization is hardcoded for simplicity, so it is always the same.

Without these two tricks, the hash looks like this (much farther from white noise):

![Hash without tricks]({% link assets/2022-05-10-fnv-1a-hash-in-c-sharp/hash-with-tricks.jpg %})

<script src="https://gist.github.com/marcospgp/ed991372f1c814eb21b8b248db258187.js"></script>
