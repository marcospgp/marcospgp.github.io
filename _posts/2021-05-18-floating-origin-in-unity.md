---
layout: default
title: Floating origin in Unity
tag: Game Dev 👾
---

If your Unity game is large enough, you will sooner or later run into floating point precision issues when your camera is far from the origin.

![Terrain]({% link assets/2021-05-18-floating-origin-in-unity/terrain.jpeg %})

_Some large terrain._

As the coordinates become larger, there are less bits left to represent sub-unit values. This makes the effect worsen the further you are from the origin.

A popular solution for this is to reset the entire world back towards (0, 0, 0) when the player's distance to it passes a certain threshold. This is known as a floating origin, because the world's origin is no longer fixed.

Another approach is to move the world, not the player (I have read that Kerbal Space Program does this) - though I decided to stay away from such a drastic solution.

Unfortunately, there are not many publicly available implementations of the floating origin approach. The only one I found was [this one on the Unify Community Wiki](https://web.archive.org/web/20210507024450/https://wiki.unity3d.com/index.php/Floating_Origin) (archive link, as the site has since gone down). It works, but is missing some functionality if you intend to keep track of the offset your player has from the origin - which is necessary in particular for multiplayer.

I went ahead and cleaned up the script, updated some deprecated calls, and added this offset-tracking functionality.

In my project, I attach this script to a GameManager object that I use for this kind of management logic.

The code is also available as [a GitHub Gist](https://gist.github.com/marcospgp/42562d3b23b37610f29828cfef674b3a).

```C#
// Based on script found at http://wiki.unity3d.com/index.php/Floating_Origin
// on 2021-05-13, modified substantially - mostly to accomodate multiplayer,
// by introducing threshold and offset values.

using UnityEngine;

public class FloatingOrigin : MonoBehaviour {
    public static FloatingOrigin Instance;

    // Largest value allowed for the main camera's X or Z coordinate before that
    // coordinate is moved by the same amount towards 0 (which updates offset).
    // Pick a power of two for this, as floating point precision (the thing
    // we are trying to regulate) decreases with every successive power of two.
    public const float threshold = (float) Threshold._4;

    private ParticleSystem.Particle[] parts = null;
    private Transform anchor;

    // The origin is offset by offset * threshold
    public (byte x, byte y, byte z) Offset { get; private set; } = (0, 0, 0);

    public enum Threshold {
        _2 = 2,
        _4 = 4,
        _8 = 8,
        _16 = 16,
        _32 = 32,
        _64 = 64,
        _128 = 128,
        _256 = 256,
        _512 = 512,
        _1024 = 1024
    }

    public void OnEnable() {
        // Ensure singleton
        if (Instance != null) {
            Destroy(gameObject);
            throw new System.Exception(
                "More than one instance of singleton detected."
            );
        } else {
            Instance = this;
        }
    }

    public void LateUpdate() {
        if (anchor == null) {
            var camera = Camera.main;
            if (camera != null) {
                anchor = camera.transform;
            } else {
                return;
            }
        }

        // Calculate offset

        Vector3 offsetToApply;
        float value;

        if (Mathf.Abs(anchor.position.x) > threshold) {
            value = anchor.position.x;
            offsetToApply = new Vector3(1f, 0f, 0f);
        } else if (Mathf.Abs(anchor.position.y) > threshold) {
            value = anchor.position.y;
            offsetToApply = new Vector3(0f, 1f, 0f);
        } else if (Mathf.Abs(anchor.position.z) > threshold) {
            value = anchor.position.z;
            offsetToApply = new Vector3(0f, 0f, 1f);
        } else {
            return;
        }

        float times = Mathf.Floor(Mathf.Abs(value) / threshold);
        float offsetSign = Mathf.Sign(value) * -1f;

        Offset = (
            (byte) (Offset.x + (offsetToApply.x * times * offsetSign)),
            (byte) (Offset.y + (offsetToApply.y * times * offsetSign)),
            (byte) (Offset.z + (offsetToApply.z * times * offsetSign))
        );

        float delta = threshold * times * offsetSign;
        offsetToApply *= delta;

        // Offset scene root objects

        GameObject[] objects = UnityEngine.SceneManagement.SceneManager
            .GetActiveScene().GetRootGameObjects();

        foreach (var o in objects) {
            Transform t = o.GetComponent<Transform>();
            t.position += offsetToApply;
        }

        // Offset world-space particles

    	ParticleSystem[] particleSystems = FindObjectsOfType<ParticleSystem>();
        foreach (var sys in particleSystems) {
            if (sys.main.simulationSpace != ParticleSystemSimulationSpace.World)
                continue;

            int particlesNeeded = sys.main.maxParticles;

            if (particlesNeeded <= 0)
                continue;

            bool wasPaused = sys.isPaused;
            bool wasPlaying = sys.isPlaying;

            if (!wasPaused)
                sys.Pause ();

            // Ensure a sufficiently large array in which to store the particles
            if (parts == null || parts.Length < particlesNeeded) {
                parts = new ParticleSystem.Particle[particlesNeeded];
            }

            // Now get the particles
            int num = sys.GetParticles(parts);

            for (int i = 0; i < num; i++) {
                parts[i].position += offsetToApply;
            }

            sys.SetParticles(parts, num);

            if (wasPlaying)
                sys.Play ();
        }
    }
}
```
