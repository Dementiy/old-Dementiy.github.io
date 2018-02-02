---
layout: post
title: Заметки по нейронным сетям
categories: python datascience
---

Эта заметка является вольным переводом статьи [Deep Neural Network from scratch](https://matrices.io/deep-neural-network-from-scratch/) и является пререквизитом к выполнению работы [Нейронная сеть для распознования рукописных цифр]().

<script type="text/javascript" async
src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>

### Подготовка данных

Первым шагом является нормализация данных (feature scaling). Мы имеем следующие признаки:

- Пробег автомобиля: количественный признак, число в промежутке от 0 до 350 тысяч км.;
- Тип топлива: бинарный признак, который принимает значения дизель/бензин;
- Возраст машины: количественный признак, число в промежутке от 0 до 40;
- Цена: количественный признак, число в промежутке от 0 до 40 тысяч.

Пробег автомобиля и возраст будут нормализированны с использованием среднго и стандартного отклонения. Целью является привести все данные к единой шкале, в общем в промежутке от [-6;6]. Else the number of kilometers will have a value up to 350k and the age up to 40 years, and a change in a weight value will not impact the age or number of kilometers in the same way. The formula for the normalization is:

$$x' = \frac{x-x}{\sigma}$$

Where x is the original feature dataset (all the cars), x¯ is the mean of that feature dataset, and σ is the standard deviation of that feature dataset. We will do it in python later.

The type of fuel (binary) will be encoded with −1 for one value and 1 for the other. There is no categorical data here in order to keep the number of features light because each categorical feature would become a sparse matrix of the size of the number of classes. If you have categorical data in your features (i.e: red, green, pink and blue for a feature) you must use effect encoding or dummy encoding. Our number of features will not change, only the values after the encoding.

We will normalize the price so that all the values are between [0,1]. This is necessary because our neural network will produce results between [0,1]. If the neural network guesses a price of 0.45 for a car whereas our initial price is 17k, the error between the guess and the real price will be high, 16 999.55€. As the guess will be at most 1, the error will be at best 16 999€ and will never improve. We will normalize the price using the formula:

$$\frac{x_i - min(x)}{max(x) - min(x)}$$

$$x_i$$ is one car price whereas $$x$$ is the whole price dataset. It means that each car price will be processed using the maximum available price and the minimum available price.

Our 17K€ price will become something like 0.43 and if our network predict 0.45 it will be a good prediction. We will do the exact opposite from the above formula to find the price back from 0.45.

### Forward propagation

So we have three inputs (features), one binary, two quantitatives and one quantitative output. As we will predict a quantitative variable and we will use past data to train our network, it is called a supervised regression problem.

![](/assets/images/notes-on-nn/DNN-S1-1.png)

One input is a car.

| Пробег автомобиля | Тип топлива | Возраст | Цена   |
|-------------------|-------------|---------|--------|
|  38000            | Gasoline    | 3       | 17 000 |

Once the data has been normalized and encoded as previously described, we will have.

| Пробег автомобиля | Тип топлива | Возраст | Цена   |
|-------------------|-------------|---------|--------|
| 1.4               | -1          | 0.4     | 0.45   |

As we will have more than one car, our array will have more lines.

| Пробег автомобиля | Тип топлива | Возраст | Цена   |
|-------------------|-------------|---------|--------|
| 1.4               | -1          | 0.4     | 0.45   |
| 0.4               | -1          | 0.1     | 0.52   |
| 5.4               | -1          | 4       | 0.25   |
| 1.5               | -1          | 1       | 0.31   |
| ...               | ...         | ...     | ...    |

We can see this array as matrix.

$$
X = \begin{bmatrix}
	1.4 & -1 & 0.4 & 0.45 \\
	0.4 & -1 & 0.1 & 0.52 \\
	5.4 & -1 & 4 & 0.25 \\
	1.5 & -1 & 1 & 0.31 \\
	... & ... & ... & ...
\end{bmatrix}
$$

The price is not a feature and will not be available for a new car. We separate inputs (features) and outputs (prediction).

$$
X = \begin{bmatrix}
	1.4 & -1 & 0.4 \\
	0.4 & -1 & 0.1 \\
	5.4 & -1 & 4   \\
	1.5 & -1 & 1   \\
	... & ... & ...
\end{bmatrix}

y = \begin{bmatrix}
0.45 \\
0.52 \\
0.25 \\
0.31 \\
...
\end{bmatrix}
$$

For now we have two matrices $$X$$ and $$y$$, it's time to complete our network. We choose to have two hidden layers between our inputs and our output, the first layer will have three neurons and the second one two. The number of hidden layers and the number of neurons by layer is up to you. These are two hyper parameters that you have to define before running your neural network.

![](/assets/images/notes-on-nn/DNN-S2-1.png)

Each of our input neuron will reach all the neurons in the next layer because we are using a fully connected network. Each link from one neuron to another is called a synapse and comes with a weight. A weight on a synapse is of the form Wjkl where l denotes the number of the layer, j the number of the neuron from the lth layer and k the number of the neuron from the (l+1)th layer.


![](/assets/images/notes-on-nn/DNN-S3-1.png)

We can view the weights as a matrix.

$$
W^1 = \begin{bmatrix}
	W^1_{11} & W^1_{12} & W^1_{13} \\
	W^1_{21} & W^1_{22} & W^1_{23} \\
	W^1_{31} & W^1_{32} & W^1_{33}
\end{bmatrix}
$$

The number of rows equals the number of features (inputs) and the number of columns equals the number of neurons in the layer number 2. Here we have three features and the first layer has three neurons so our W1 matrix is of the size 3×3. For now I don't talk about the bias unit to keep things simple.

Now we compute the values of the neurons of the first hidden layer (the first column of green circles). For each car defined by three features, we will have three neurons computed for the first hidden layer. We do that using matrix calculus.

Let's say that we have only one car in our dataset. We don't need $$y$$ for now.

$$X = [1.4\quad -1\quad 0.4]$$

Our W1 matrix is randomly initialized the first time so we can use random values for the weights.

$$
W^1 = \begin{bmatrix}
	0.01 & 0.05 & 0.07 \\
	0.20 & 0.041 & 0.11 \\
	0.04 & 0.56 & 0.13
\end{bmatrix}
$$

The values of the neurons of the first hidden layer are called the activities of the first hidden layer. They will be saved into a matrix called a(2). We begin by computing Z(2) using the formula:

$$Z^{(2)} = X.W^1$$

$$
Z^{(2)} = [1.4\quad -1\quad 0.4].\begin{bmatrix}
	0.01 & 0.05 & 0.07 \\
	0.20 & 0.041 & 0.11 \\
	0.04 & 0.56 & 0.13
\end{bmatrix}
$$

$$Z^{(2)} = [-0.17\quad 0.253\quad 0.04]$$

We can view it on our network.

![](/assets/images/notes-on-nn/DNN-S4-1.png)

We are almost done with the first hidden layer, we just have to apply an activation function on Z(2). We can view it like that.

![](/assets/images/notes-on-nn/DNN-S5.png)

Once we apply an activation function element wise to Z(2) we obtain a(2), the activities of our second layer.

$$a^{(2)}=\sigma(Z^{(2)})$$

Where $$\sigma(x)$$ is our activation function. The activation function is applied element wise and is non linear, allowing the network to compute complicated problems using only a small number of nodes. The common ones are Sigmoid, Tanh, ReLU, Leaky ReLU, Maxout. The list is actually bigger than that. Which one to choose? Andrej Karpathy says the following:

> TLDR: “What neuron type should I use?” Use the ReLU non-linearity, be careful with your learning rates and possibly monitor the fraction of “dead” units in a network. If this concerns you, give Leaky ReLU or Maxout a try. Never use sigmoid. Try tanh, but expect it to work worse than ReLU/Maxout.

So we should use ReLU as an activation function, it is short for rectified linear unit and is actually quite simple. If x is greater than 0 we take it, else we take 0.

$$\sigma(x) = max(0, x)$$

Nonetheless we have very little neurons and one or two dying neuron will undermine the results of our network (when the value of the neuron becomes zero). Instead we will use the Tanh as an activation function.

$$\sigma(x) = tanh(x) = \frac{e^x - e^{-x}}{e^x + e^{-x}}$$

So the first neuron of our first hidden layer will become:

$$\sigma(-0.17) = tanh(-0.17) = \frac{e^{-0.17} - e^{0.17}}{e^{-0.17} + e^{0.17}} = -0.168$$

The second one:

$$\sigma(0.253) = tanh(0.253) = \frac{e^{0.253} - e^{-0.253}}{e^{0.253} + e^{-0.253}} = 0.248$$

So our first hidden layer with only one car looks like:

![](/assets/images/notes-on-nn/DNN-S6.png)

Thanks to the matrix calculus property, each neuron of the first hidden layer will receive a weighted sum of the inputs. We have:

$$
Z^{(2)} = [1.4\quad -1\quad 0.4].\begin{bmatrix}
	0.01 & 0.05 & 0.07 \\
	0.20 & 0.041 & 0.11 \\
	0.04 & 0.56 & 0.13
\end{bmatrix}
$$

$$Z^{(2)} = [-0.17\quad 0.253\quad 0.04]$$

$$Z^{(2)}$$ the first neuron of the layer two, for which we found −0.17 is the result of $$1.4 \times 0.01 + −1 \times 0.2 + 0.4 \times 0.04$$ (cf Matrix Multiplication). If you compare this to the neural network drawing, you see that in fact the first neuron of the layer two is the input 1 (number of kms) times the weight on the synapse plus the input 2 (type of fuel) times the weight on the synapse plus the input 3 (age) times the weight on the synapse. It is exactly what matrix calculus does for us.

For our example we assumed that only one car was in our dataset, that's why $$X=[1.4\quad −1\quad 0.4]$$. In reality we will have several cars, let's say five. So our inputs are:

$$
X = \begin{bmatrix}
	1.4 & -1 & 0.4 \\
	0.4 & -1 & 0.1 \\
	5.4 & -1 & 4   \\
	1.5 & -1 & 1   \\
	1.8 & 1 & 1
\end{bmatrix}
$$

And our Z(2) calculation will be:

$$
Z^{(2)} = \begin{bmatrix}
	1.4 & -1 & 0.4 \\
	0.4 & -1 & 0.1 \\
	5.4 & -1 & 4   \\
	1.5 & -1 & 1   \\
	1.8 & 1 & 1
\end{bmatrix} . \begin{bmatrix}
	0.01 & 0.05 & 0.07 \\
	0.20 & 0.041 & 0.11 \\
	0.04 & 0.56 & 0.13
\end{bmatrix}
$$

$$
Z^{(2)} = \begin{bmatrix}
	-0.17  & 0.253 & 0.04 \\
	-0.192 & 0.035 & -0.069 \\
	0.014  & 2.469 & 0.788   \\
	-0.145 & 0.594 & 0.125   \\
	0.258  & 0.691 & 0.366
\end{bmatrix}
$$

With the tanh applied element wise:

$$
a^{(2)} = \sigma(Z^{(2)}) = tanh(Z^{(2)}) = \begin{bmatrix}
	tanh(-0.17)  & tanh(0.253) & tanh(0.04) \\
	tanh(-0.192) & tanh(0.035) & tanh(-0.069) \\
	tanh(0.014)  & tanh(2.469) & tanh(0.788)   \\
	tanh(-0.145) & tanh(0.594) & tanh(0.125)   \\
	tanh(0.258)  & tanh(0.691) & tanh(0.366)
\end{bmatrix}
$$

$$
a^{(2)} = \begin{bmatrix}
	-0.16838105 & 0.24773663 & 0.03997868 \\
	-0.18967498 & 0.03498572 & -0.06889071 \\
	0.01399909 & 0.98576421 & 0.65727455 \\
	-0.14399227 & 0.53276635 & 0.124353 \\
	0.25242392 & 0.59862403 & 0.35048801
\end{bmatrix}
$$

Z(2) and a(2) are of size 5×3, one row for each car and one column for each hidden unit (neuron) of the layer 2.

To summarise, for now we have three matrices, our input X, our weights W1 between the layer 1 and 2 and our first hidden layer a(2)=tanh(X.W1) (Z(2) is an intermediary matrix that holds the value of X.W1).

![](/assets/images/notes-on-nn/DNN-S7-1.png)


We will repeat the exact same steps but instead of using our matrix X as inputs, we will now use a(2). We add synapses from the layer 2 to the layer 3.

![](/assets/images/notes-on-nn/DNN-S8-1.png)

We also view the weights as a matrix.

$$
W^2 = \begin{bmatrix}
	W^2_{11} & W^2_{12} \\
	W^2_{21} & W^2_{22} \\
	W^2_{31} & W^2_{32}
\end{bmatrix}
$$

The number of rows equals the number of neurons in the layer 2 and the number of columns equals the number of neurons in the layer 3. We will compute the values of our second hidden layer into the matrix Z(3) as we did previously. For a given layer, the input is always the output of the previous layer. For the layer 2, the output of the previous layer are the data from the layer 1, meaning X, for the layer 3 the output of the previous layer are the data from the layer 2, meaning a(2).

$$Z^{(3)} = a^{(2)}.W^2$$

And then we apply the activation function, we are keeping tanh(x) as activation function because it is unusual to use different activation functions for each layer.

$$a^{(3)} = tanh(Z^{(3)})$$

Previously we found that:

$$
a^{(2)} = \begin{bmatrix}
	-0.16838105 & 0.24773663 & 0.03997868 \\
	-0.18967498 & 0.03498572 & -0.06889071 \\
	0.01399909 & 0.98576421 & 0.65727455 \\
	-0.14399227 & 0.53276635 & 0.124353 \\
	0.25242392 & 0.59862403 & 0.35048801
\end{bmatrix}
$$

Our W2 matrix is randomly initialized the first time so we can use random values for the weights.

$$
W^2 = \begin{bmatrix}
	0.04 & 0.78 \\
	0.40 & 0.45 \\
	0.65 & 0.23
\end{bmatrix}
$$

We calculate Z(3):

$$Z^{(3)}=a^{(2)}.W2$$

$$
Z^{(3)} = \begin{bmatrix}
	-0.16838105 & 0.24773663 & 0.03997868 \\
	-0.18967498 & 0.03498572 & -0.06889071 \\
	0.01399909 & 0.98576421 & 0.65727455 \\
	-0.14399227 & 0.53276635 & 0.124353 \\
	0.25242392 & 0.59862403 & 0.35048801
\end{bmatrix} . \begin{bmatrix}
	0.04 & 0.78 \\
	0.40 & 0.45 \\
	0.65 & 0.23
\end{bmatrix}
$$

$$
Z^{(3)} = \begin{bmatrix}
	0.11834555 & -0.01066064 \\
	-0.03837167 & -0.14804778 \\
	0.8220941 & 0.60568633 \\
	0.2881763 & 0.15603208 \\
	0.47736378 & 0.54688371
\end{bmatrix}
$$

We then apply our activation function:

$$a^{(3)} = tanh(Z^{(3)})$$

$$
a^{(3)} = \begin{bmatrix}
	tanh(0.11834555) & tanh(-0.01066064) \\
	tanh(-0.03837167) & tanh(-0.14804778) \\
	tanh(0.8220941) & tanh(0.60568633) \\
	tanh(0.2881763) & tanh(0.15603208) \\
	tanh(0.47736378) & tanh(0.54688371)
\end{bmatrix}
$$

$$
a^{(3)} = \begin{bmatrix}
	0.11779613 & -0.01066023 \\
	-0.03835285 & -0.14697553 \\
	0.67620804 & 0.54108347 \\
	0.28045542 & 0.15477804 \\
	0.44412987 & 0.49818098
\end{bmatrix}
$$

Z(3) and a(3) are of size 5×2, one row for each car and one column for each hidden unit (neuron) of the layer 3.

Our network looks like:

![](/assets/images/notes-on-nn/DNN-S9.png)

We will now connect the last layer, using the same technique as previously seen.

![](/assets/images/notes-on-nn/DNN-S10-1.png)

As for the two previous layers, we have:

$$Z^{(4)} = a^{(3)}.W^3$$

$$a^{(4)} = tanh(Z^{(4)})$$

Where:

$$
W^3 = \begin{bmatrix}
	W^3_{11} \\
	W^3_{21}
\end{bmatrix}
$$

The number of rows equals the number of neurons in the layer 3 and the number of columns equals the number of neurons in the layer 4.

Our W3 matrix is randomly initialized the first time so we can use random values for the weights. For instance:

$$W^3= \begin{bmatrix}
	0.04 \\
	0.41
\end{bmatrix}
$$

We then calculate Z(4) using a(3) which is the result of the previous layer.

$$Z^{(4)} = a^{(3)}.W^3$$

$$
Z^{(4)} = \begin{bmatrix}
	0.11779613 & -0.01066023 \\
	-0.03835285 & -0.14697553 \\
	0.67620804 & 0.54108347 \\
	0.28045542 & 0.15477804 \\
	0.44412987 & 0.49818098
\end{bmatrix}.\begin{bmatrix}
	0.04 \\
	0.41
\end{bmatrix}
$$

$$
Z^{(4)} = \begin{bmatrix}
	0.00034115 \\
	-0.06179408 \\
	0.24889254 \\
	0.07467721 \\
 	0.22201939
\end{bmatrix}
$$

We then apply the activation function:

$$
a^{(4)} = tanh(Z^{(4)}) = \begin{bmatrix}
	tanh(0.00034115) \\
	tanh(-0.06179408) \\
	tanh(0.24889254) \\
	tanh(0.07467721) \\
 	tanh(0.22201939)
\end{bmatrix}
$$

$$
a^{(4)} = \begin{bmatrix}
	0.000341156 \\
	−0.0617156 \\
	0.243877 \\
	0.0745387 \\
 	0.218442
\end{bmatrix}
$$

Finally our network looks like the following:

![](/assets/images/notes-on-nn/DNN-S11.png)

What we did is called the forward propagation, we have an input and we propagate it through the network. Each time we have an hidden layer, we compute the values of its neurons using:

$$a(l) = \sigma(a(l−1) \times W(l−1))$$

If l=1, a(1)=X (our inputs), $$\sigma(x)$$ in our case is tanh(x). Each time you see the above formula, you should think "neural network layer".

### Bias

We didn't used a bias unit to keep things simple, we will add it now. Why do we need a bias? On the above picture we saw that Z1(2)=X1×W111+X2×W211+X3×W311 where X1, X2 and X3 are the attributes of our car. This calculation will produce a number an then our activation function tanh(Z1(2)) will be applied. We have a 3D input (X1, X2, X3), to explain the bias usefulness, we will keep only one feature, for instance the number of kilometers and assume that only the number of kilometers of a car describes its price. We now have a1(2)=X1×W111 where X1 is the car's number of kilometers. And once the activation function is applied, we have a1(2)=tanh(Z1(2))=tanh(X1×W111).

After the training part described later, our W111 will be a learned value. For instance 1.8. Our X1 is unknown and will be different for each car, a1(2) will be the result of tanh(1.8×X1). We can draw this function:

![](/assets/images/notes-on-nn/DNN-FUNC1.png)

As you can see this function is centered in zero, as our W111 is a learned value, our network will be able to tweak it. We assumed that our network learned 1.8 but let's draw the graph when W111 is larger, let's say 7.

![](/assets/images/notes-on-nn/DNN-FUNC2.png)

And when W111=0.4:

![](/assets/images/notes-on-nn/DNN-FUNC3.png)

As we can see, changing W111 changes the stiffness of the graph, as our network can only tweak the weights, it will only be able to change the stiffness but will stay centered in zero. Is this a problem ?

Firstly the number of kilometers of a car will always be positive, so all the left part of the graph will be useless, a1(2) will never be negative, is that a good thing ? We don't really know, but even if it was a good thing, we would have no choice.

Secondly, let's say that we have two cars, one with 30k kilometers and one with 170k kilometers, once normalized, we will have 0.5 and 2.5. Let's say that the impact of the number of kilometers is clearly determined, like if the car is less than 50k kilometers the price is high and if the car is more than 50k kilometers the price is low, the limit is clear. Once normalized 50k will be around 0.7, so we need a steep graph that produce -1 when x < 0.7 and produce 1 when x > 0.7. Like this one:

![](/assets/images/notes-on-nn/DNN-FUNC4.png)

That would be perfect but unfortunately we can't move the graph to the right, so we are stuck with a graph centered in zero (the first image). We can only make the graph steep using a high value for W111. The above picture would be a good solution for us, it is the graph of the function:

$$tanh(10x−8)$$

Where 10 is the value for our W111 and 8 is a constant that comes handy, the bias. Instead of a1(2)=tanh(X1×W111) we will have a1(2)=tanh(X1×W111+b) and this little b will greatly improve our network performances because it will move the graph of our activation function to the left or the right and the result produced will be more representative of our problem. In our example (the above picture) b=−8.

We used only one feature to easily draw graphs and display the impact of the bias but it is the same thing with more dimensions, our original example with a bias would be $$a1^{(2)} = tanh(X1×W111+X2×W211+X3×W311+b)$$.

This value b also needs to be learned, because regarding the problem, the bias will be different. The same bias must be added to each car. We saw previously the origin of the weights and their matrix representation, how can we add a bias?

We will have a bias for each neuron. For instance for the first neuron of the first hidden layer we have:

$$a_1^{(2)} = tanh(X1×W111+X2×W211+X3×W311+b)$$

As we have three neurons in the first hidden layer, we will need three biases, we could use a bias matrix.

![](/assets/images/notes-on-nn/BIAS-WITHOUT-TRICK.png)

Nonetheless managing the biases and the weights in separate matrices can be cumbersome. As the biases are learned, there are not different from the weights nonetheless they should not depend of a car attributes because all the car will have different attributes whereas the biases should be the same for all the cars. The solution is to add an additional feature to each car with a value 1. So that this feature when multiplied with the bias will not change its value.

![](/assets/images/notes-on-nn/BIAS-TRICK.png)

Note that X4 is equal to 1 so the calculations of the two previous pictures are exactly the same but using the bias trick we only have one weights matrix.

Adding a bias means adding a 1 feature to all our inputs. We add biases to our input layer and each one of our hidden layers. Now our network looks like.

![](/assets/images/notes-on-nn/DNN-S12.png)

The link between the bias and the neurons are dotted to keep the network readable but they are normal weights. Our cars have a new feature with the value 1. Each hidden layer has also a new neuron 1 because the problem that the bias solve appears each time we use the activation function (so each layer). There is no link between the bias and the previous layer because the bias is added after the calculations, it is not the result of a matrix multiplication.

We will do again all the calculus with the biases. We began by adding the bias unit to our input data, this means adding a new column of 1.


### Backpropagation


### Gradient checking


### Regularization

### Python code
