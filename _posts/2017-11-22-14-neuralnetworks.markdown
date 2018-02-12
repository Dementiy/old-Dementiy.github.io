---
layout: post
title: Нейронная сеть для распознования рукописных цифр
categories: python datascience практики
---

В этой работе вы напишите простую нейронную сеть, решающую задачу классификации рукописных цифр из набора данных MNIST. От вас требуется описать формулы для обновления весов, выполнить решение задачи на Python с использованием библиотеки numpy, затем рассмотреть решение задачи с использованием библиотеки Keras. Пререквизитом к этой работе являются «Заметки по нейронным сетям», где рассматривается задача регрессии.

### Описание набора данных MNIST

![](/assets/images/14-neuralnetworks/mnist.png)

Смешанный набор данных Национального института стандартов и технологий (mixed National Institute of Standards and Technology, MNIST) был создан исследователями IR (Image Recognition) в качестве эталона для сравнения различных алгоритмов IR. Основная идея в том, что, если у вас есть какой-то алгоритм или программная система IR, которую надо протестировать, вы можете запустить свой алгоритм или систему с использованием набора данных MNIST и сравнить результаты с ранее опубликованными для других систем.

Набор данных состоит всего из 70 000 изображений: 60 000 обучающих (используемых для создания модели IR) и 10 000 тестовых (применяемых для оценки точности модели). Каждое изображение MNIST — это оцифрованная картинка одной цифры, написанной от руки. Каждое изображение имеет размер 28 × 28 пикселей. Каждое значение пикселя лежит в диапазоне от 0 (представляет белый цвет) до 255 (представляет черный цвет). Промежуточные значения отражают оттенки серого. На рис. 2 показаны первые восемь изображений в обучающем наборе. Сама цифра, которая соответствует каждому изображению, очевидна человеку, но для компьютеров идентификация цифр — очень сложная задача.

Любопытно, что и обучающие, и тестовые данные хранятся в двух файлах, а не в одном. Один файл содержит значения пикселей для изображений, а другой — метки изображений (0–9). Каждый из четырех файлов также содержит заголовочную информацию, и все они хранятся в двоичном формате, сжатом в формате gzip.

Обратите внимание на рис. 1, что демонстрационная программа использует только обучающий набор из 60 000 элементов. Формат тестового набора идентичен таковому для обучающего набора. Основной репозитарий для файлов MNIST в настоящее время находится на yann.lecun.com/exdb/mnist. Обучающие пиксельные данные хранятся в файле train-images-idx3-ubyte.gz, а обучающие маркерные данные — в файле train-labels-idx1-ubyte.gz. Чтобы запустить демонстрационную программу, вам понадобится перейти на сайт репозитария MNIST, скачать и разархивировать эти два файла обучающих данных. Чтобы разархивировать файлы, я использовал бесплатную программу 7-Zip с открытым исходным кодом.

### Архитектура сети


### Реализация с использованием numpy


### Реализация с использованием keras

```python
import numpy
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense
from keras.utils import np_utils

import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt


numpy.random.seed(42)

(X_train, y_train), (X_test, y_test) = mnist.load_data()

X_train = X_train.reshape(60000, 784)
X_test = X_test.reshape(10000, 784)

X_train = X_train.astype('float32')
X_test = X_test.astype('float32')
X_train /= 255
X_test /= 255

Y_train = np_utils.to_categorical(y_train, 10)
Y_test = np_utils.to_categorical(y_test, 10)

model = Sequential()

model.add(Dense(800, input_dim=784, activation="relu", kernel_initializer="normal"))
model.add(Dense(10, activation="softmax", kernel_initializer="normal"))

model.compile(loss="categorical_crossentropy", optimizer="adam", metrics=["accuracy"])

print(model.summary())

history = model.fit(X_train, Y_train,
    batch_size=200, epochs=30, validation_split=0.2, verbose=2)

scores = model.evaluate(X_test, Y_test, verbose=0)
print("Accuracy on test set: {}".format(scores[1] * 100))


# Visualize training history
plt.figure(1)
plt.subplot(211)
plt.plot(history.history['acc'])
plt.plot(history.history['val_acc'])
#plt.title('Model accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['train', 'test'], loc='lower right')

plt.subplot(212)
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
#plt.title('Model loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['train', 'test'], loc='upper right')
plt.show()
```


### Вычисления в облаке с FloydHub

