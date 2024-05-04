---
layout: default
title: Notes
description: >-
  This is where I keep notes for future reference. Entries are sorted alphabetically.
table_of_contents: true
comments_section: true
---

This is where I keep notes for future reference. Entries are sorted alphabetically.

# CSS

## px vs rem

Generally, `rem` and `em` should be used for font size related styles and `px` for everything else, such as margins or padding.

There's no consensus on whether to use `rem` for everything or only for font size related styles (using mainly `px` otherwise).

Browsers zoom by increasing the size of `px`, so this decision should only affect users who manually configure a different browser default font size.

For those, it may be better to scale fonts only and keep spacing the same, as otherwise they could simply use the zoom feature.

# Email

When setting up email make sure to [enable SPF, DKIM, and DMARC](https://support.google.com/a/answer/10583557?sjid=7080635252494889890-EU) to properly authenticate messages. Use <https://www.dmarctester.com> to test this.

If unable to send email through a third party client for a Google Workspace account, try enabling "Allow per-user outbound gateways" in the admin panel.

# General development

## Floating point

[Key Insights On IEEE 754 Floating Point Numbers](https://marcospereira.me/2023/12/15/floating-point/)

### Error accumulation

Avoid updating decimal numbers iteratively, which can accumulate errors. Instead, prefer to calculate values from the underlying constants each time.

This is one of the main concerns of the field of [numerical analysis](https://en.wikipedia.org/wiki/Numerical_analysis#Generation_and_propagation_of_errors).

## Git

### Commit without a message

`git add -A && git commit --allow-empty-message -m '' && git push`

### Submodules

Git submodules are a nice way of setting up project dependencies.

#### Adding

You can add a dependency into a repo by running:

`git submodule add --name steamworksnt https://github.com/marcospgp/steamworksnt.git <target-folder>`

Including the `--name` prevents the destination path from being used as the name by default, which can be confusing if the module is moved with `git mv` later.

If submodules will be used in-editor as part of a Unity project, they should be placed in the `Assets` folder.

#### Cloning & updating

To update dependencies or download them after a fresh `git clone`, use:

`git submodule update --init --recursive --merge --remote`

#### Removing

To remove a submodule, use `git rm <submodule path>` (and not `git submodule deinit`) in accordance with [the docs](https://git-scm.com/docs/gitsubmodules#_forms).

However, also note that:

> the Git directory is kept around as it to make it possible to checkout past commits without requiring fetching from another repository.
> To completely remove a submodule, manually delete `$GIT_DIR/modules/<name>/`.

`$GIT_DIR` will usually be the `.git` folder.

## Makefile

### MacOS

MacOS ships with an outdated version of make that does not support some functionality such as `.ONESHELL`.

### `.ONESHELL` and `.SHELLFLAGS`

Context on using `.ONESHELL` and `.SHELLFLAGS`:

```makefile
# Including the ".ONESHELL" target makes all commands within a target run in the
# same shell, instead of isolating each command into its own subshell.
# This allows us to make use of python virtual environments in a more readable
# way, and may also speed up execution.
# https://www.gnu.org/software/make/manual/html_node/One-Shell.html
.ONESHELL:

# ".ONESHELL" causes make to no longer fail immediately. We restore this
# behavior with the "-e" argument.
# We also set "-o pipefail" and "-u" for added strictness.
# Note that "-c" (the default argument when ".SHELLFLAGS" is not specified) must
# be included, otherwise make will error.
# https://www.gnu.org/software/make/manual/html_node/Choosing-the-Shell.html
.SHELLFLAGS := -c -e -o pipefail -u
```

## NASA's 10 rules for safe code

<https://en.wikipedia.org/wiki/The_Power_of_10:_Rules_for_Developing_Safety-Critical_Code>

## Shell

My shell setup:

- [Oh My Zsh](https://ohmyz.sh/)
  - Switched to get case-insensitive path autocompletion, but has many more benefits over vanilla Z shell.
- [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) for history-based command autocompletion.
  - Has more GitHub stars than [`zsh-autocomplete`](https://github.com/marlonrichert/zsh-autocomplete) so picked it, but both seem nice.

`~/.zshrc` configuration:

- Disabled `share_history`, which is a better workflow when managing multiple open shells across different projects:

  ```shell
  # Disable sharing command history across shells.
  unsetopt share_history
  ```

# Hardware

## Monitors

### VA vs IPS vs OLED

IPS is better. VA has issues with ghosting/black smearing. OLED has issues with pixel burn-in.

# Unity game dev

## Analyzers

Unity has [a guide on enabling analyzers](https://docs.unity3d.com/2022.3/Documentation/Manual/roslyn-analyzers.html). It works, as the `.dll`s are added as analyzers to the `.csproj` file generated by Unity:

```xml
<ItemGroup>
  <Analyzer Include="/.../Assets/ErrorProne.Net.CoreAnalyzers.dll" />
  <!-- ... -->
</ItemGroup>
```

However, while the warnings do show up in VSCode (with the C# dev kit extension), they do not appear in the Unity editor's console.

Also note that the Unity analyzers are added by default, with the path varying based on the code editor selected under `Unity -> preferences -> external tools`.

I tried setting up a separate C# project to include valuable analyzers as dependencies and make updating all of them at once easier, but the analyzer `.dll`s aren't included in the results of `dotnet publish` and there's no simple way to change that.

## Animations

### Importing

- "bake into pose" root transform changes that shouldn't be applied to the gameobject on each animation.

### Mixamo

Downloading animations "without skin" prevents wasting memory with unnecessary models.
However, the avatar generated by Unity for these won't work properly.
That can be fixed by downloading the default Mixamo character (Y Bot) in T-pose and generating an avatar from it, which can then be used with "without skin" Mixamo animations.

### Movement without foot sliding

See {% post_link 2023-12-02-unity-foot-sliding %}.

## Blender

### Settings

- Disable saving `.blend1` files

### Unity interop

- Store `.blend` files directly inside the Unity project's "Assets" folder
- There doesn't seem to be a way to store textures in `.blend` file, so keep them in "Assets" folder and use them in both Blender and Unity

## Frame rate independence

Everything that runs in `Update()` (as opposed to `FixedUpdate()`) should be carefully designed to ensure independence from variations in frame rate.

For example, there is a specific formula for a frame rate independent version of calling `lerp` (linear interpolation) iteratively.

There is an extensive post about this [here](https://marcospereira.me/2023/11/15/frame-rate-independent-lerp/).

Ready to use code should be available in the [Unity utilities repo](https://github.com/marcospgp/unity-utilities).

## General optimization

The points below have more importance in the context of frequently run code, such as that in `Update()`.

- [Avoid generating garbage](https://x.com/ID_AA_Carmack/status/1390195077209808898) (allocating heap memory for short-lived objects). One way to do this is to reuse objects, by storing them in class fields instead of instantiating locally. Object pooling is a similar and popular strategy.
- Use fixed size over dynamically sized collections (such as arrays over lists) whenever possible, for the reduced overhead.
- Use static lambda expressions (introduced in C# 9) over non-static to avoid [capturing scope](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/lambda-expressions#capture-of-outer-variables-and-variable-scope-in-lambda-expressions).

### Comparing distances

The expensive square root operation can be avoided by comparing squared distances.

### Exponentiation

When raising a number to an integer exponent, direct multiplication (`x * x`) is more efficient than calling a function such as `MathF.Pow()` which accepts any real number as exponent.

### Microsoft's recommendations

See Microsoft's mixed reality [performance recommendations for Unity](https://learn.microsoft.com/en-us/windows/mixed-reality/develop/unity/performance-recommendations-for-unity).

## Inspector

### Textures

It is often useful to generate textures for debugging code visually through the inspector.

To view a texture through the inspector, assign it to a public or `[SerializeField]` field.

Then generate the texture with the following logic.

```C#
var tex = new Texture2D(width, width, TextureFormat.RGBA32, mipChain: false);

for (int i = 0; i < width; i++)
{
    for (int j = 0; j < width; j++)
    {
        tex.SetPixel(
            i,
            j,
            Color.Lerp(Color.black, Color.white, VoronoiNoise.Get(i, j, 30f, 1234L))
        );
    }
}

tex.Apply();
```

Calling `Apply()` is required for the texture to appear right away, otherwise an update has to be triggered by changing something on the inspector (such as its anisotropic filtering level).

## LODs

- Only the last LOD matters
- Impostors > LOD meshes
- Advancements like Nanite can change 3D lore fast

Based on <https://medium.com/@jasonbooth_86226/when-to-make-lods-c3109c35b802>

## Mathf vs MathF

`UnityEngine.Mathf` relies on `System.Math`, which runs computations on the `double` type.

`System.MathF` does computations on the `single`/`float32` type.

The difference may be small however since CPUs generally handle 64bit math better than GPUs.

## Multithreading

### Awaitable vs Task

Unity introduced `Awaitable` [in version 2023.1](https://docs.unity3d.com/2023.1/Documentation/ScriptReference/Awaitable.html), which essentially is a modernization of the Coroutine API (which handles things like waiting for the next frame) to make it compatible with async/await in C#.

The new `Awaitable` can also handle multithreading with explicit switching between main and background threads using `await Awaitable.MainThreadAsync()` and `await Awaitable.BackgroundThreadAsync()`.

However, `BackgroundThreadAsync` appears to be [a mere wrapper](https://github.com/Unity-Technologies/UnityCsReference/blob/2d9918cf6dc3194015d75bd9845555f59a0015e4/Runtime/Export/Scripting/Awaitable.Threading.cs#L71) around `Task.Run()`, thus with no advantages when it comes to allocating `Task` objects.

In addition to this, a previously existing issue where pending tasks continue running even after exiting/entering play mode in the Unity editor remains:

> [Unity doesn’t automatically stop code running in the background when you exit Play mode.](https://docs.unity3d.com/2023.3/Documentation/Manual/overview-of-dot-net-in-unity.html)

To get around this, I had implemented a `SafeTask` wrapper as a replacement for `Task.Run()` (no other `Task` API functionality is replaced), which still makes sense to continue using:

- <https://github.com/marcospgp/unity-utilities/blob/main/Async/SafeTask.cs>
- <https://marcospereira.me/2022/05/06/safe-async-tasks-in-unity/>

Relevant links:

- [Forum thread on multithreading](https://forum.unity.com/threads/multithreading-or-similar-in-unity.1078994/#post-9563953)
- ["Overview of .NET in Unity" documentation page with "Async, tasks and Awaitable" section](https://docs.unity3d.com/2023.3/Documentation/Manual/overview-of-dot-net-in-unity.html)
- [Await support documentation page](https://docs.unity3d.com/2023.3/Documentation/Manual/AwaitSupport.html)

### General tips

- Use Tasks over manually creating Threads except for long lived tasks, to avoid hoarding a thread from .NET's thread pool.
- Always use concurrency management mechanisms when sharing data across threads. Even when there is only a single writer thread, memory caching mechanisms can interfere with synchronization.

Order of preference for concurrency management mechanisms:

1. Task model
1. Concurrent (thread safe) collections
1. Interlocked
1. lock
1. volatile ([avoid this](https://stackoverflow.com/a/11523074/2037431) for being more obscure and harder to reason about than the Interlocked class)
1. Lower level synchronization primitives (Mutex, Semaphore, ...)

Optimization tips:

- Use static lambdas (introduced in C# 9) with `Task.Run()` to avoid [capturing scope](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/lambda-expressions#capture-of-outer-variables-and-variable-scope-in-lambda-expressions), which requires heap allocations for the underlying class.
- Prefer long-running tasks to starting new tasks frequently, which avoids `Task` object allocations and context switching overhead

## NuGet dependencies

With no official NuGet support in Unity at time of writing, one can set up NuGet dependencies through a separate C# project.

There are two other options worth mentioning:

- [NuGet for Unity](https://github.com/GlitchEnzo/NuGetForUnity) (too heavy handed/complex solution that runs the risk of going unmaintained)
- Downloading packages manually and copying `.dll`s to the Unity project (troublesome not just for the extra manual work but also because one has to manually go through dependencies and download each, with no simple way of keeping track of everything over time)

These are the steps to set up dependencies through a standalone C# project:

1. `mkdir NuGetDependencies && cd NuGetDependencies`
1. Run `dot`.

   Where "NuGetDependencies" is the destination folder. Feel free to modify this, or omit to create a project in the current directory

   We target .NET Standard 2.1 according to [Unity compatibility](https://docs.unity3d.com/Manual/dotnetProfileSupport.html).

   Feel free to delete any `.cs` files generated automatically, as we won't need to write any code.

1. `dotnet new gitignore`
1. Add dependencies with `dotnet add package <package name> --version <version>` (can be copied from NuGet website directly)
1. Build with `dotnet publish` (debug configuration is the default). Note we don't use `dotnet build`, which doesn't include dependency `.dll`s in build files.
1. Copy the files in `./bin/Debug/netstandard2.1/publish/` to somewhere in the Unity project's `Assets` folder, such as `Assets/NuGetDependencies/`

## Procedural mesh generation

Call [MarkDynamic](https://docs.unity3d.com/ScriptReference/Mesh.MarkDynamic.html) on meshes that are updated frequently at runtime.

## Project set up

These are things to think about when starting a new project, which can also be worth revisiting once in a while. Generally high-leverage settings with poor defaults or quick fixes for common issues.

### Color banding

[Fix color banding](https://forum.unity.com/threads/horrible-color-banding-for-lighting-fog.912368/#post-9386285) by checking "enable dithering" in the camera inspector. I only tested this in URP.

### Editorconfig

Create a symlink from the project's root to the `.editorconfig` file in the [Unity Utilities](https://github.com/marcospgp/unity-utilities) repo, which should be installed as a git submodule in the `Assets` folder.

### Git submodules

Set up dependencies on other repos by installing them as git submodules under the `Assets` folder.

An example would be the Unity utilities repo: <https://github.com/marcospgp/unity-utilities>

### Mono vs IL2CPP

Decide between [Mono or IL2CPP](https://www.reddit.com/r/Unity3D/comments/zag4ka/mono_or_il2cpp/).

Generally, IL2CPP should be better as it can have better performance than Mono, although it may complicate [mod creation](https://www.reddit.com/r/GuidedHacking/comments/10r0t50/how_to_mod_unity_games_made_with_il2cpp/) (although hacking would also become more difficult accordingly).

> [IL2CPP can improve performance across a variety of platforms, but the need to include machine code in built applications increases both the build time and the size of the final built application.](https://docs.unity3d.com/2023.2/Documentation/Manual/IL2CPP.html)

## Shaders

### Shader Graph

#### Hiding properties from inspector

Before version 2023.3.0a11, Shader Graph properties not marked as "Exposed" simply don't work unless initialized in code. The expected behavior would be to simply hide the property from the material inspector.

There is more info about this issue in [this thread](https://forum.unity.com/threads/non-exposed-parameters-dont-work.912149).
