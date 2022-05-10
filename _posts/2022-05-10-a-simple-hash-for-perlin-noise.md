---
layout: post
title: A Simple Hash for Perlin Noise
---

I needed a hashing algorithm that is simple to implement and quick to compute, to be used as a basis
for generating perlin noise in Unity.

I couldn't rely on simple randomness since terrain generation has to be deterministic, especially for multiplayer games.

I ended up implementing the [Fowler–Noll–Vo 1a hash](http://www.isthe.com/chongo/tech/comp/fnv/index.html), which checks those boxes. Perhaps the code may help someone else, so I'm sharing it below.

You can use the `DebugTexture()` method to get a sample of what it looks like. This hashes the coordinates of each pixel and maps the hash to a color between black and white:

![Hash with tricks]({% link assets/2022-05-10-a-simple-hash-for-perlin-noise/hash-with-tricks.jpg %})

I used a couple tricks to get the hash to look as close as possible to white noise when passing in sequential numbers starting from 0 or near 0. This the case for the debug texture, for example.

The first trick is to multiply each coordinate by one of the algorithm's parameters (the prime number), which gets the bits away from being almost all 0s when hashing low values.

The second trick is to hash the bytes in a random sequence. This sequence is hardcoded for simplicity.

Without these two tricks, the hash looks much less like pure white noise. This is the result if we hash the coordinates as floating point numbers:

![Hash without tricks from floats]({% link assets/2022-05-10-a-simple-hash-for-perlin-noise/hash-without-tricks.jpg %})

And this if we hash coordinates as integers:

![Hash without tricks from integers]({% link assets/2022-05-10-a-simple-hash-for-perlin-noise/hash-without-tricks-int.jpg %})

<script src="https://gist.github.com/marcospgp/ed991372f1c814eb21b8b248db258187.js"></script>
