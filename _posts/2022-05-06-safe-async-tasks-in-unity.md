---
title: Safe Async Tasks in Unity
tag: Game Dev 👾
---

_2024-01-05 update: [Unity has introduced `Awaitable`](https://docs.unity3d.com/2023.3/Documentation/Manual/AwaitSupport.html) in version 2023.1, which improves compatibility with async/await features in C#. However, according to [this other documentation page](https://docs.unity3d.com/2023.3/Documentation/Manual/overview-of-dot-net-in-unity.html) "Unity doesn’t automatically stop code running in the background when you exit Play mode", which means this blog post and its `SafeTask` implementation is still relevant._

Is Minecraft single threaded? I think it must be, because I remember a slight stutter when flying fast across the world. Too many chunks being loaded starts eating into the main thread's render time. Apparently this stutter was short and rare enough that it could be ignored by Notch, but I was not as lucky.

![Terrain]({% link assets/2022-05-06-safe-async-tasks-in-unity/terrain2.jpg %})

I am working on infinite terrain in Unity, voxel based just like Minecraft - except it can be smoothed. The smoothing works by displacing each vertex towards the average of its neighbors. This makes building a chunk slow enough that I can't do it on the fly in a single thread. I thus had to find a way to do it in the background, as the player moves.

I didn't even consider using Unity's coroutines for this - they are single threaded, so the most I could do is dedicate some milliseconds each frame towards building the chunks. This is an idea I dislike, as it compromises the game's framerate.

Unity's new C# jobs were my first real option. I gave them a try, but the concept of defining tasks inside a struct and not really knowing what data is accessible from there really irked me. It is not at all clear at which level of abstraction a job should be defined (a single slow operation? the entire task one wants to accomplish?). Most of all, having to use a struct and pass data around with `NativeContainer`s made it hard to convert existing single threaded code into something that can run on a background thread.

Unhappy with this solution, I set out to find an alternative, later discovering that C# has a cozy API for multithreading that is very high level and clean. To execute code on C#'s "thread pool", all one has to do is pass a function to `Task.Run()` and `await` it to get its result or to discover if an exception was thrown.

But it can never be that simple. Unity's documentation warns against using tasks, then brings up this `SynchronizationContext` thing, and I was off to the docs. During several days I must have read over a hundred pages of documentation and stack overflow, discussing this concept very indirectly - apparently, no one has actually ever seen a `SynchronizationContext` in the wild, they have only heard tales.

The simple explanation,it seems, is that Unity defines its own `SynchronizationContext` so that code execution returns to the main thread after an `await`. Otherwise, you would not be able to call most of Unity's APIs.

Another matter Unity brings up is that it will not terminate tasks upon exiting play mode, which can lead to much craziness spilling onto edit mode and getting saved alongside the scene. To handle this, I built a wrapper around `Task.Run()` that ignores the result of any running task if play mode is exited.

The code is below. I hope it helps, and that it may quickly be made obsolete by Unity.

<script src="https://gist.github.com/marcospgp/291a8239f5dcb1a326fad37d624f3630.js"></script>
