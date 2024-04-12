---
layout: default
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

```C#
using System;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

namespace UnityUtilities
{
    /// <summary>
    /// A replacement for `Task.Run()` that cancels tasks when entering or
    /// exiting play mode in the Unity editor (which doesn't happen by default).
    ///
    /// Also registers an UnobservedTaskException handler to prevent exceptions
    /// from being swallowed in all Tasks (including SafeTasks), which would
    /// happen when these are not awaited or are chained with `.ContinueWith()`.
    ///
    /// Unity 2023.1 introduced `Awaitable` and its `BackgroundThreadAsync()`
    /// method that is essentially a wrapper around `Task.Run()`, but the issues
    /// addressed by this class remain - so it remains relevant.
    /// </summary>
    public static class SafeTask
    {
        private static CancellationTokenSource cancellationTokenSource = new();

        public static Task<TResult> Run<TResult>(Func<Task<TResult>> f) =>
            SafeTask.Run<TResult>((object)f);

        public static Task<TResult> Run<TResult>(Func<TResult> f) =>
            SafeTask.Run<TResult>((object)f);

        public static Task Run(Func<Task> f) => SafeTask.Run<object>((object)f);

        public static Task Run(Action f) => SafeTask.Run<object>((object)f);

        private static async Task<TResult> Run<TResult>(object f)
        {
            // We use tokens and not the cancellation source directly as it is
            // replaced with a new one upon exiting play or edit mode.
            CancellationToken token = CancellationToken.None;
            TResult result = default;

            // Pending tasks when entering/exiting play mode are only a problem
            // in the editor.
            if (Application.isEditor)
            {
                SafeTask.cancellationTokenSource ??= new();
                token = SafeTask.cancellationTokenSource.Token;
            }

            try
            {
                // Pass token to Task.Run() as well, otherwise upon cancelling
                // its status will change to faulted instead of cancelled.
                // https://stackoverflow.com/a/72145763/2037431

                if (f is Func<Task<TResult>> g)
                {
                    result = await Task.Run(() => g(), token);
                }
                else if (f is Func<TResult> h)
                {
                    result = await Task.Run(() => h(), token);
                }
                else if (f is Func<Task> i)
                {
                    await Task.Run(() => i(), token);
                }
                else if (f is Action j)
                {
                    await Task.Run(() => j(), token);
                }
            }
            catch (Exception e)
            {
                // We log unobserved exceptions with an UnobservedTaskException
                // handler, but those are only handled when garbage collection happens.
                // We thus force exceptions to be logged here - at least for SafeTasks.
                // If a failing SafeTask is awaited, the exception will be logged twice, but that's
                // ok.
                UnityEngine.Debug.LogException(e);
                throw;
            }

            if (token.IsCancellationRequested)
            {
                throw new OperationCanceledException(
                    "An asynchronous task has been canceled due to entering or exiting play mode.",
                    token
                );
            }

            return result;
        }

#if UNITY_EDITOR
        [UnityEditor.InitializeOnLoadMethod]
        private static void OnLoadCallback()
        {
            // Prevent unobserved task exceptions from being swallowed.
            // This happens when:
            //  * A Task that isn't awaited fails;
            //  * A Task chained with `.ContinueWith()` fails and exceptions are
            //    not explicitly handled in the function passed to it.
            //
            // This event handler works for both Tasks and SafeTasks.
            //
            // Note this only seems to run when garbage collection happens (such
            // as after script reloading in the Unity editor).
            // Calling `System.GC.Collect()` after the exception caused
            // exceptions to be logged right away.
            TaskScheduler.UnobservedTaskException += (_, e) =>
                UnityEngine.Debug.LogException(e.Exception);

            // Cancel pending `SafeTask.Run()` calls when exiting play or edit
            // mode.
            UnityEditor.EditorApplication.playModeStateChanged += (change) =>
            {
                if (
                    change == UnityEditor.PlayModeStateChange.ExitingPlayMode
                    || change == UnityEditor.PlayModeStateChange.ExitingEditMode
                )
                {
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
