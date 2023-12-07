---
layout: post
title: How to avoid foot sliding
tag: Game Dev 👾
---

Goal: set up player movement in the Unity engine that is script controlled (as opposed to root motion based, for better responsiveness), but sync up animations to minimize discrepancies such as foot sliding.

1. Set up blend tree
   - 2D simple directional (no idle animation)
   - 8 directional animations (minimize velocity difference when blending - for example, blending a forward with a sideways animation can result in diagonal movement that is slower than either of the other animations individually. Blending animation root motion is poorly documented.)
   - Adjust animation speeds so that each has a resulting velocity of 1m/s
     1. Compute positions -> Velocity XZ
     2. Divide animation speed by norm of velocity
   - Reset animation positions to unit circle coordinates
   - Set blend tree animation direction through X and Y parameters connected to user input
   - Adjust blend tree speed by setting a parameter to be equal to the player's speed
2. Transition to/from idle animation
   - Idle animation cannot be in blend tree as the blend tree's speed will be modified
   - Blending between idle and movement animations is unreliable anyway in terms of resulting velocity (unpredictable, non-linear)

This is what the resulting blend tree looks like:

![Blend tree]({% link assets/2023-12-02-unity-foot-sliding/unity-movement-blend-tree.jpg %})

It may be possible to still blend between movement and other animations by nesting blend trees, although copy pasting a blend tree you previously created [requires a simple workaround](https://twitter.com/voxelbased/status/1720082569260343547).

More info at <https://kybernetik.com.au/animancer/docs/manual/blending/mixers/#synchronisation>
