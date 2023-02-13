---
layout: post
title: Hand sway in Unity
tag: Game Dev 👾
---

While setting up a first person controller in Unity, I decided to add some sway to the player's hands.

It took a surprisingly large number of iterations to get right. There is no standard way to go about it, and every solution I tried seemed to run into one or other issue.

I couldn't bring myself to give up and go back to the static hands, however - not now that I had a glimpse into how much a little inertia added to the game feel. So I persisted.

I managed to settle on a solution I'm satisfied with, which I'll describe below.

<br>

<!-- markdownlint-disable no-inline-html -->
<div style="position: relative; padding-bottom: 78.18627450980392%; height: 0;"><iframe src="https://www.loom.com/embed/adbb51721e5f4e40a7d905452b714ab1" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>
<!-- markdownlint-enable no-inline-html -->

<br>

_Forgive the poor video quality, I will figure out how to record things properly soon._

## Project

The entire Unity project is [available on Github](https://github.com/marcospgp/hand-sway) (editor version 2020.3.7f1).

The code responsible for the hand sway can be found entirely in the [`UpdatePositionAndRotation` method](https://github.com/marcospgp/Hand-Sway/blob/main/Assets/Components/Player/Hands/PlayerHands.cs#L120) of the `PlayerHands` component.

## Explanation

![Hierarchy]({% link assets/2021-05-10-hand-sway-in-unity/1.png %})

First of all, the `Player Hands` are kept separate from the `Player` object in the hierarchy, so they can rotate independently.

The `Player` object has a camera and some simple movement and look-around functionality.

The `Player Hands` object is solely responsible for the hand sway. It holds a reference to the `Player`'s camera and follows it around by applying three different forces:

![Forces]({% link assets/2021-05-10-hand-sway-in-unity/2.png %})

1. Camera follow strength: pulls the hands along when the camera rotates;
2. Spring force: constantly pulls the hands towards the center of the view;
3. Sway drag: a drag force that acts against the previous two.

And that's it. The actual implementation of each of these forces can be found in [the code](https://github.com/marcospgp/Hand-Sway/blob/main/Assets/Components/Player/Hands/PlayerHands.cs#L120), so feel free to check it out! And please let me know if you have any questions - I'd be happy to help!

**Update**: Revisiting this, I suspect it might be a better idea to rely on translation rather than rotation to achieve a realistic sway effect. Something to try in the future, perhaps.
