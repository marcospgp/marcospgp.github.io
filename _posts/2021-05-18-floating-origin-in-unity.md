---
layout: post
title: Floating origin in Unity
---

If your Unity game is large enough, you will sooner or later run into floating point precision issues when your camera is far from the origin.

![Terrain]({% link assets/2021-05-18-floating-origin-in-unity/terrain.jpeg %})

_Some large terrain._

As the coordinates become larger, there are less bits left to represent sub-unit values. This makes the effect worsen the further you are from the origin.

A popular solution for this is to reset the entire world back towards (0, 0, 0) when the player's distance to it passes a certain threshold. This is known as a floating origin, because the world's origin is no longer fixed.

Another approach is to move the world, not the player (I have read that Kerbal Space Program does this) - though I decided to stay away from such a drastic solution.

Unfortunately, there are not many publicly available implementations of the floating origin approach. The only one I found was [this one on the Unify Community Wiki](https://web.archive.org/web/20210507024450/https://wiki.unity3d.com/index.php/Floating_Origin) (archive link, as the site has since gone down). It works, but is missing some functionality if you intend to keep track of the offset your player has from the origin - which is necessary in particular for multiplayer.

I went ahead and cleaned up the script, updated some deprecated calls, and added this offset-tracking functionality.

You can find the source code here: <https://gist.github.com/marcospgp/42562d3b23b37610f29828cfef674b3a>

In my project, I attach this script to a GameManager object that I use for this kind of management logic.
