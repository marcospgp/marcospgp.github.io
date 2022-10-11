---
layout: post
title: Applying Neural Cellular Automata to the ARC Challenge
---

I reached out to the ML Collective about tackling the [ARC challenge](https://github.com/fchollet/ARC), a dataset of grid-based abstraction and reasoning puzzles.

I ended up [building a model](https://drive.google.com/file/d/19DUwnEdZmpVfE7CPbdoOyfkrqKl--HhM/view?usp=sharing) based on neural cellular automata and [presenting the results](https://docs.google.com/presentation/d/132JpBFTwP3vKHPBXb60mPfS2U9jVKQleSZ-oesHJh8Y/edit?usp=sharing) to other researchers in the community.

The model solved 14 out of 262 tasks, while a baseline convolutional model with residual connections solved 12.
These models contrast in the number of parameters - while the neural cellular automata based model has 18 062, the baseline has 446 410.

In late 2022, the ARC challenge remains unsolved.
