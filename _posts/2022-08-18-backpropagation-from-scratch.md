---
layout: post
title: Backpropagation From Scratch
---

In this post we summarize the math behind deep learning and implement a simple network that achieves 85% accuracy classifying digits from the MNIST dataset.

It is assumed that the reader is familiar with how neural networks are composed of layers of neurons, and how each layer is connected to the next by weights and biases.

I owe a big thanks to Michael Nielsen's [Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/), which I remember browsing on my phone during long trips (with a bit of a headache from trying to visualize so many plots and diagrams).

## Introduction

For our neural network to learn we need to adjust its weights and biases. This means calculating the gradient of the cost with respect to every weight and bias in the network.
For convenience, we will store this gradient as two separate matrices for each layer: a 2D matrix of how much the cost changes when you adjust each weight:

$$\displaystyle \frac{\partial C}{\partial w}$$

and a 1D matrix of how much the cost changes when you adjust each bias:

$$\displaystyle \frac{\partial C}{\partial b}$$

Each row of the 2D weight gradient will represent a destination neuron, and each column an input neuron. This simplifies our vector calculations (more on this here).
Once we have the gradient, we can adjust the weights & biases by subtracting from them the gradient multiplied by a learning rate (typically a very small number).

Note that we can only calculate the gradient after running a sample (or a batch of samples) through the network. We must then start by doing so, making sure to store the activations of each layer as we go - as those will be needed for our calculations.

Although this post was written with a specific neural network in mind, the entirety of the post is agnostic to the number of layers and their size, and a large part of it is also agnostic to cost or activation functions, which only show up in part 3.

## Chain rule

The overarching goal of backpropagation is to calculate the gradient for every weight and bias in the network. The chain rule tells us that:

$$
\begin{equation}
\tag{1}\label{1}
\frac{\partial C}{\partial w_{ij}^{l}} ={\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial w_{ij}^{l}} \cdot }\frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}
\end{equation}
$$

and

$$
\begin{equation}
\tag{2}\label{2}
\frac{\partial C}{\partial b_{i}^{l}} ={\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial b_{i}^{l}} \cdot }\frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}
\end{equation}
$$

Where:

* $$\displaystyle C$$ is the cost;
* $$\displaystyle w_{ij}^{l}$$ is the weight connecting neuron $$\displaystyle j$$ of layer $$\displaystyle l-1$$ to neuron $$\displaystyle i$$ of layer $$\displaystyle l$$;
* $$\displaystyle z_{i}^{l}$$ is the weighted input of neuron $$\displaystyle i$$ of layer $$\displaystyle l$$;
* $$\displaystyle a_{i}^{l}$$ is the activation of neuron $$\displaystyle i$$ of layer $$\displaystyle l$$;
* and $$\displaystyle b_{i}^{l}$$ is the bias of neuron $$\displaystyle i$$ of layer $$\displaystyle l$$.

Here we use the superfix $$\displaystyle ^{( this\ thing\ here)}$$ not for exponentiation but for indexing the layer a variable belongs to.

The last factor of these formulas ($$\displaystyle \frac{\partial C}{\partial a_{i}^{l}}$$) shows us that in order to compute the weight and bias gradients we will also need to calculate the gradient with respect to the activations.
For the last layer of the network it can be calculated directly using the derivative of the cost function, but for the other layers it is expanded as follows:

$$
\begin{equation}
\tag{3}\label{3}
\frac{\partial C}{\partial a_{i}^{l}} =\sum _{k}\frac{\partial z_{k}^{l+1}}{\partial a_{i}^{l}} \cdot \frac{\partial a_{k}^{l+1}}{\partial z_{k}^{l+1}} \cdot \frac{\partial C}{\partial a_{k}^{l+1}}
\end{equation}
$$

Where the sum is over all $$\displaystyle k$$ neurons of layer $$\displaystyle l+1$$.

This formula is very similar to $$\eqref{1}$$ and $$\eqref{2}$$, with the last two factors also being present in the others. This hints at the fact that we can reuse some of the calculations when computing these formulas later.

The last factor $$\displaystyle \frac{\partial C}{\partial a_{k}^{l}}$$ will need to be expanded again if layer $$\displaystyle l+1$$ is not yet the last layer, and so on.

This evidences how calculating the gradients involves starting with the last layer, and then backpropagating through the network: the gradients of each layer depend on how that layer's activations affect the following layers.

## Calculating the derivatives

We can now move on to calculating the derivatives present in the chain rule expressions above, so that we can turn them into something we can actually use.

The weighted input for each neuron is calculated in the following way:

$$
\begin{equation*}
{\displaystyle z_{i}^{l} =\left(\sum _{j} w_{ij}^{l} \cdot a_{j}^{l-1}\right) +b_{i}^{l}}
\end{equation*}
$$

The sum is over all $$\displaystyle j$$ neurons of the previous layer $$\displaystyle l-1$$. The first layer for which the weighted input is calculated comes after the input layer, so that we always have a layer $$\displaystyle l-1$$. We will need the partial derivatives of $$\displaystyle z$$ with respect to each of its inputs:

$$
\begin{align*}
{\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial w_{ij}^{l}} =a_{j}^{l-1}} & & {\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial b_{i}^{l}} =1} & & {\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial a_{j}^{l-1}} =w_{ij}^{l}}
\end{align*}
$$

We will also need the derivatives involving the cost function and the activation functions. Different layers can have different activation functions, which is the case for our network: our last layer has a softmax activation function, while the previous layers all have a sigmoid activation function. We will deal with these and the cost function later in this document.

We can now replace the weighted input derivatives in $$\eqref{1}$$, $$\eqref{2}$$, and $$\eqref{3}$$ with the results we just calculated:

$$
\begin{align*}
\tag{4}\label{4}
\frac{\partial C}{\partial w_{ij}^{l}} ={\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial w_{ij}^{l}} \cdot }\frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}} & & \Rightarrow & & \frac{\partial C}{\partial w_{ij}^{l}} =a{\displaystyle _{j}^{l-1} \cdot }\frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}
\end{align*}
$$

$$
\begin{align*}
\tag{5}\label{5}
\frac{\partial C}{\partial b_{i}^{l}} ={\displaystyle \frac{\textstyle \partial z_{i}^{l}}{\partial b_{i}^{l}} \cdot }\frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}} & & \Rightarrow & & \frac{\partial C}{\partial b_{i}^{l}} =1{\displaystyle \cdot }\frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}
\end{align*}
$$

$$
\begin{align*}
\tag{6}\label{6}
{\displaystyle \frac{\partial C}{\partial a_{i}^{l}} =\sum _{k}\frac{\partial z_{k}^{l+1}}{\partial a_{i}^{l}} \cdot \frac{\partial a_{k}^{l+1}}{\partial z_{k}^{l+1}} \cdot \frac{\partial C}{\partial a_{k}^{l+1}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial a_{i}^{l}} =\sum _{k} w_{ki}^{l+1} \cdot \frac{\partial a_{k}^{l+1}}{\partial z_{k}^{l+1}} \cdot \frac{\partial C}{\partial a_{k}^{l+1}}}
\end{align*}
$$

## Backpropagating the last layer

We now need to calculate the derivatives for the cost and activation functions used in our neural network. We will start by dealing with the last layer, where we are using a softmax activation followed by the cross entropy cost. This cost is calculated in the following way:

$$
\begin{equation*}
{\displaystyle \frac{1}{n}\sum _{n}\sum\limits _{i} y_{i}\ln\left(\frac{1}{a_{i}}\right)}
\end{equation*}
$$

Where the first sum is over all $$\displaystyle n$$ training samples, the second sum is over all $$\displaystyle i$$ neurons in the last layer, $$\displaystyle y_{i}$$ is the ground truth activation for neuron $$\displaystyle i$$, and $$\displaystyle a_{i}$$ is that neuron's actual activation.

However, the function we derive for the cost is the loss function, which calculates the cost for a single sample:

$$
\begin{equation*}
{\displaystyle C=\sum\limits _{i} y_{i}\ln\left(\frac{1}{a_{i}}\right)}
\end{equation*}
$$

There is a clever simplification for calculating the derivatives of the last layer. When it applies a softmax activation followed by the cross entropy loss, as described on page 3 of <https://www.ics.uci.edu/~pjsadows/notes.pdf>, we end up with the formula:

$$
\begin{equation}
\tag{7}\label{7}
\frac{\partial C}{\partial z_{i}} =a_{i} - y_{i}
\end{equation}
$$

Where $$\displaystyle y_{i}$$ is the ground truth activation for neuron $$\displaystyle i$$, and $$\displaystyle a_{i}$$ is its actual activation.
This formula replaces the last two factors of $$\eqref{1}$$, $$\eqref{2}$$, and $$\eqref{3}$$:

$$
\begin{equation*}
{\displaystyle \frac{\partial a_{i}}{\partial z_{i}} \cdot \frac{\partial C}{\partial a_{i}} =\frac{\partial C}{\partial z_{i}} =a_{i} -y_{i}}
\end{equation*}
$$

Formulas $$\eqref{4}$$ and $$\eqref{5}$$ then become:

$$
\begin{align*}
{\displaystyle \frac{\partial C}{\partial w_{ij}^{l}} =a_{j}^{l-1} \cdot \frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial w_{ij}^{l}} =a_{j}^{l-1} \cdot \left( a_{i}^{l} -y_{i}\right)}
\end{align*}
$$

$$
\begin{align*}
{\displaystyle \frac{\partial C}{\partial b_{i}^{l}} =1 \cdot \frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial b_{i}^{l}} = a_{i}^{l} -y_{i}}
\end{align*}
$$

There is no need to calculate $$\eqref{6}$$ for the last layer, as the formulas above stand on their own.
With a little analysis, we can convert them into vectorized expressions:

$$
\begin{align*}
\tag{8}\label{8}
{\displaystyle \frac{\partial C}{\partial w_{ij}^{l}} =a_{j}^{l-1} \cdot \left( a_{i}^{l} -y_{i}\right)} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial w^{l}} =\left( a^{l} -y\right) \cdot \left( a^{l-1}\right)^{T}}
\end{align*}
$$

$$
\begin{align*}
\tag{9}\label{9}
{\displaystyle \frac{\partial C}{\partial b_{i}^{l}} = a_{i}^{l} -y_{i}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial b^{l}} = a^{l} -y}
\end{align*}
$$

Note that all vectors are assumed to be column vectors, meaning the same as a matrix with just one column. Subtraction is element-wise, and $$\displaystyle \cdot$$ represents matrix multiplication.

## Backpropagating the remaining layers

The remaining layers of our neural network apply a sigmoid activation to the weighted inputs:

$$
\begin{equation*}
\sigma ( z_{i}) =\frac{1}{1+\mathrm{e}^{-z_{i}}}
\end{equation*}
$$

And thus the derivative of the activations becomes:

$$
\begin{equation*}
\frac{\partial a_{i}}{\partial z_{i}} =\sigma '( a_{i}) \ =\sigma ( a_{i}) \cdot ( 1-\sigma ( a_{i}))
\end{equation*}
$$

We will use the same expression $$\displaystyle \sigma '$$ to denote both the scalar and the vectorized version of the sigmoid's derivative. The version being used can be inferred from context: if we are passing in a vector, we are using the vectorized version:

$$
\begin{equation*}
\sigma '( a) \ =\sigma ( a) \odot ( 1-\sigma ( a))
\end{equation*}
$$

Where $$\displaystyle \sigma ( a)$$ represents the sigmoid function applied elementwise to vector $$\displaystyle a$$, $$\displaystyle \odot $$ represents the hadamard (element-wise) product, and the subtraction operation is also applied element-wise.

Formulas $$\eqref{4}$$ and $$\eqref{5}$$ then become:

$$
\begin{align*}
{\displaystyle \frac{\partial C}{\partial w_{ij}^{l}} =a_{j}^{l-1} \cdot \frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial w_{ij}^{l}} =a_{j}^{l-1} \cdot \sigma '\left( a_{i}^{l}\right) \cdot \frac{\partial C}{\partial a_{i}^{l}}}
\end{align*}
$$

$$
\begin{align*}
{\displaystyle \frac{\partial C}{\partial b_{i}^{l}} =1 \cdot \frac{\partial a_{i}^{l}}{\partial z_{i}^{l}} \cdot \frac{\partial C}{\partial a_{i}^{l}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial b_{i}^{l}} =1 \cdot \sigma '\left( a_{i}^{l}\right) \cdot \frac{\partial C}{\partial a_{i}^{l}}}
\end{align*}
$$

We can rewrite these as vectorized expressions:

$$
\begin{align*}
\tag{10}\label{10}
{\displaystyle \frac{\partial C}{\partial w_{ij}^{l}} =a_{j}^{l-1} \cdot \sigma '\left( a_{i}^{l}\right) \cdot \frac{\partial C}{\partial a_{i}^{l}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial w^{l}} =\left( \sigma '\left( a^{l}\right) \odot \frac{\partial C}{\partial a^{l}}\right) \cdot \left( a^{l-1}\right)^{T}}
\end{align*}
$$

$$
\begin{align*}
\tag{11}\label{11}
{\displaystyle \frac{\partial C}{\partial b_{i}^{l}} =1 \cdot \sigma '\left( a_{i}^{l}\right) \cdot \frac{\partial C}{\partial a_{i}^{l}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial b^{l}} =\sigma '\left( a^{l}\right) \odot \frac{\partial C}{\partial a^{l}}}
\end{align*}
$$

Where all vectors are assumed to be column vectors.
Note that we still have to specify $$\displaystyle \frac{\partial C}{\partial a_{i}^{l}}$$, which depends on the kind of layer that comes after layer $$\displaystyle l$$.

If the next layer is not yet the last, and has a sigmoid activation (as all non-final layers in our network), formula $$\eqref{6}$$ will become:

$$
\begin{align*}
{\displaystyle \frac{\partial C}{\partial a_{i}^{l}} =\sum _{k} w_{ki}^{l+1} \cdot \frac{\partial a_{k}^{l+1}}{\partial z_{k}^{l+1}} \cdot \frac{\partial C}{\partial a_{k}^{l+1}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial a_{i}^{l}} =\sum _{k} w_{ki}^{l+1} \cdot \sigma '\left( a_{k}^{l+1}\right) \cdot \frac{\partial C}{\partial a_{k}^{l+1}}}
\end{align*}
$$

Which can be vectorized into the form:

$$
\begin{equation}
\tag{12}\label{12}
{\displaystyle \frac{\partial C}{\partial a^{l}} =\left( w^{l+1}\right)^{T} \cdot \left( \sigma '\left( a^{l+1}\right) \odot \frac{\partial C}{\partial a^{l+1}}\right)}
\end{equation}
$$

If layer $$\displaystyle l+1$$ is the last layer, however, two things are different: we have a softmax activation function, and we can calculate the derivative of the cost directly. Since we already calculated an expression $$\eqref{7}$$ that combines the two missing derivatives, we just need to insert it into $$\eqref{6}$$:

$$
\begin{align*}
{\displaystyle \frac{\partial C}{\partial a_{i}^{l}} =\sum _{k} w_{ki}^{l+1} \cdot \frac{\partial a_{k}^{l+1}}{\partial z_{k}^{l+1}} \cdot \frac{\partial C}{\partial a_{k}^{l+1}}} & & {\displaystyle \Rightarrow } & & {\displaystyle \frac{\partial C}{\partial a_{i}^{l}} =\sum _{k} w_{ki}^{l+1} \cdot \left( a_{k}^{l+1} -y_{k}\right)}
\end{align*}
$$

We can also vectorize this expression:

$$
\begin{equation}
\tag{13}\label{13}
{\displaystyle \frac{\partial C}{\partial a^{l}} =\left( w^{l+1}\right)^{T} \cdot \left( a^{l+1} -y\right)}
\end{equation}
$$

Where the subtraction applies element-wise, $$\displaystyle \cdot $$ represents matrix multiplication, and vectors are 1-column matrices by default.

## Writing the code

When it comes to implementing backpropagation in code, the formulas to apply are the final vectorized expressions: $$\eqref{8}$$, $$\eqref{9}$$, $$\eqref{10}$$, $$\eqref{11}$$, $$\eqref{12}$$, and $$\eqref{13}$$.

Here is a rough overview of the steps that need to be taken:

1. Feedforward a sample through the network, storing activations of each layer along the way;
2. Calculate cost and store for reference (since we are not training in batches, we can track the accuracy of the model as we train by logging how many of the last $$x$$ samples were guessed correctly. The global accuracy can be logged every epoch);
3. Calculate gradient for weights & biases of last layer;
4. Calculate gradient for activations of the previous layer;
5. Use the activations gradient to calculate weights & biases gradient;
6. Repeat until input layer is reached;
7. Update weights & biases by subtracting the gradient multiplied by a small learning rate
8. Go back to 1.

We can now jump into a notebook and start writing some code:

<script src="https://gist.github.com/marcospgp/d4b2166ebb76a00bafe09e7e1ea0be47.js"></script>

_Note: A [Github Repository](https://github.com/marcospgp/backpropagation-from-scratch) is available containing the code and maths used in this post._
