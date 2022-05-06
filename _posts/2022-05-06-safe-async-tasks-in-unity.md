---
layout: post
title: Safe Async Tasks in Unity
---

Is Minecraft single threaded? I think it must be, because I remember a slight stutter when flying fast across the world. Too many chunks being loaded starts eating into the main thread's render time. Apparently this stutter was short and rare enough that it could be ignored by Notch, but I was not as lucky.

![Terrain]({% link assets/terrain2.jpeg %})

I am working on infinite terrain in Unity, voxel based just like Minecraft - except it can be smoothed. The terrain is smoothed by displacing each vertex towards the average of its neighbors. This makes building a chunk slow enough that I can't do it on the fly in a single thread. I thus had to find a way to do it in the background, as the player moves.

I didn't even consider using Unity's coroutines for this - they are single threaded, so the most I could do is dedicate some miliseconds each frame towards building the chunks. I hate that idea, and I dislike how coroutines rely on IEnumerator which has nothing to do with parallelism.

I discovered C# has a cozy API for multithreading that is very high level and clean. To execute code on C#'s "thread pool", all one has to do is pass a function to `Task.Run()` and `await` it to get its result or to discover if an exception was thrown.

But it can never be that simple. Unity's documentation warns against using tasks, then brings up this `SynchronizationContext` thing, and I was off to the docs. During several days I must have read over a hundred pages of documentation and stack overflow, discussing this concept very indirectly - apparently, no one has actually ever seen a `SynchronizationContext` in the wild, they have only heard tales.

These bumps on the road for a project always get me very stressed, so I became a mess. But now at least I mostly understand what is going on.

Unity defines its own `SynchronizationContext` so that code execution returns to the main thread after an `await`. Otherwise, you would not be able to call most of Unity's APIs.

Another matter Unity brings up is that it will not terminate tasks upon exiting play mode, which can lead to much craziness. To handle this, I built a wrapper around Task.Run() that ignores the result of any running task when play mode ends.

The code is below. I hope it helps, and I hope it is quickly made obsolete by Unity.

```C#
using System;
using System.Threading;
using System.Threading.Tasks;

namespace MarcosPereira.Utility {
    public static class SafeTask {
        private static CancellationTokenSource cancellationTokenSource =
            new CancellationTokenSource();

        public static async Task<TResult> Run<TResult>(Func<Task<TResult>> f) {
            // We have to store a token and cannot simply query the source
            // after awaiting, as the token source is replaced with a new one
            // upon exiting play mode.
            CancellationToken token = SafeTask.cancellationTokenSource.Token;

            // Pass token to Task.Run() as well, otherwise upon cancelling its
            // status will change to faulted instead of cancelled.
            // https://stackoverflow.com/a/72145763/2037431
            TResult result = await Task.Run(f, token);

            SafeTask.ThrowIfCancelled(token);

            return result;
        }

        public static async Task Run(Func<Task> f) {
            CancellationToken token = SafeTask.cancellationTokenSource.Token;
            await Task.Run(f, token);
            SafeTask.ThrowIfCancelled(token);
        }

        private static void ThrowIfCancelled(CancellationToken token) {
            if (token.IsCancellationRequested) {
                throw new TaskCanceledException(
                    "An asynchronous task has been cancelled due to exiting play mode."
                );
            }
        }

#if UNITY_EDITOR
        [UnityEditor.InitializeOnLoadMethod]
        private static void OnLoad() {
            // Cancel pending tasks when exiting play mode, as Unity won't do
            // that for us.
            // See "Limitations of async and await tasks" (https://docs.unity3d.com/2022.2/Documentation/Manual/overview-of-dot-net-in-unity.html)
            UnityEditor.EditorApplication.playModeStateChanged +=
                (change) => {
                    if (change == UnityEditor.PlayModeStateChange.ExitingPlayMode) {
                        SafeTask.cancellationTokenSource.Cancel();
                        SafeTask.cancellationTokenSource.Dispose();
                        SafeTask.cancellationTokenSource = new CancellationTokenSource();
                    }
                };
        }
#endif
    }
}
```
