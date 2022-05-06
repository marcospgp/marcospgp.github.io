---
layout: post
title: Safe Async Tasks in Unity
---

Is Minecraft single threaded? I think it must be, because I remember a slight stutter when flying fast across the world. Too many chunks being loaded starts eating into the main thread's render time. Apparently this stutter was short and rare enough that it could be ignored by Notch, but I was not as lucky.

![Terrain]({% link assets/terrain2.jpg %})

I am working on infinite terrain in Unity, voxel based just like Minecraft - except it can be smoothed. The terrain is smoothed by displacing each vertex towards the average of its neighbors. This makes building a chunk slow enough that I can't do it on the fly in a single thread. I thus had to find a way to do it in the background, as the player moves.

I didn't even consider using Unity's coroutines for this - they are single threaded, so the most I could do is dedicate some miliseconds each frame towards building the chunks. I hate that idea, and I dislike how coroutines rely on IEnumerator which has nothing to do with parallelism.

I discovered C# has a cozy API for multithreading that is very high level and clean. To execute code on C#'s "thread pool", all one has to do is pass a function to `Task.Run()` and `await` it to get its result or to discover if an exception was thrown.

But it can never be that simple. Unity's documentation warns against using tasks, then brings up this `SynchronizationContext` thing, and I was off to the docs. During several days I must have read over a hundred pages of documentation and stack overflow, discussing this concept very indirectly - apparently, no one has actually ever seen a `SynchronizationContext` in the wild, they have only heard tales.

These bumps on the road for a project always get me very stressed, so I became a mess. But now at least I mostly understand what is going on.

Unity defines its own `SynchronizationContext` so that code execution returns to the main thread after an `await`. Otherwise, you would not be able to call most of Unity's APIs.

Another matter Unity brings up is that it will not terminate tasks upon exiting play mode, which can lead to much craziness. To handle this, I built a wrapper around Task.Run() that ignores the result of any running task when play mode ends.

The code is below. I hope it helps, and I hope it is quickly made obsolete by Unity.

<script src="https://gist.github.com/marcospgp/291a8239f5dcb1a326fad37d624f3630.js"></script>
