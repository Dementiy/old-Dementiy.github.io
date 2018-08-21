---
layout: post
title: Лекция 02. Управляющие конструкции
categories: python лекции
---

Во второй лекции мы рассмотрим основные управляющие конструкции языка, такие как условия, циклы и исключения.

<script type="text/javascript" async
    src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>

### Условия

Для проверки условий и выполнения соотвествующих инструкций используется конструкция `if-elif-else` со следующим синтаксисом:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Отступы имеют значение</strong></p>
  <p class="last">В Python, в отличие от других языков программирования, тело некоторого блока (условия, цикла, функции, класса) обозначается отступами.</p>
</div>

```python
if something1:
    do1()
elif something2:
    do2()
elif something3:
    do3()
# ...
elif somethingN:
    doN()
else:
    do_something_else()
```

Давайте рассмотрим пример тела (содержимого) простой функции, используемой в качестве функции активации в нейронных сетях - [ReLU](https://en.wikipedia.org/wiki/Rectifier_(neural_networks)) (Rectified Linear Units), которая представляет собой функцию, которая возвращает положительное или нулевое значение аргумента:

```python
x = 0.4    # 1
if x <= 0: # 2
    x = 0  # 3
else:
    x = x  # 5
print(x)   # 6
```

Условная конструкция получилась достаточно простой. Давайте посмотрим на список инструкций, которые будет выполнять интерпретатор (в одной из следующих лекций мы будем говорить о том откуда берутся эти инструкции):

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Да, да, весь код ваших программ <b>компилируется</b> в байт-код или другими словами в набор инструкций, которые и будут выполняться интерпретатором CPython. Краткое описание инструкций можно найти <a href="https://docs.python.org/3/library/dis.html#python-bytecode-instructions">тут</a>.</p>
</div>

```python
>>> import dis
>>> dis.dis("""...""")
  1           0 LOAD_CONST               0 (0.4)
              2 STORE_NAME               0 (x)

  2           4 LOAD_NAME                0 (x)
              6 LOAD_CONST               1 (0)
              8 COMPARE_OP               1 (<=)
             10 POP_JUMP_IF_FALSE       18

  3          12 LOAD_CONST               1 (0)
             14 STORE_NAME               0 (x)
             16 JUMP_FORWARD             4 (to 22)

  5     >>   18 LOAD_NAME                0 (x)
             20 STORE_NAME               0 (x)

  6     >>   22 LOAD_NAME                1 (print)
             24 LOAD_NAME                0 (x)
             26 CALL_FUNCTION            1
             28 POP_TOP
             30 LOAD_CONST               2 (None)
             32 RETURN_VALUE
```

Первые две инструкции соответствуют связыванию имени `x` со значением `0.4`. Следующие четыре инструкции посвящены сравнению `x` с нулем. Если результат сравнения оказался ложью, то мы переходим (`POP_JUMP_IF_FALSE`) к выполнению инструкции под номером 18, в противном случае, переменная `x` связывается со значением `0` и мы переходим (`JUMP_FORWARD`) к выполнению инструкции под номером 22. Последние шесть инструкций предназначены для вывода содержимого `x`.

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Тернарный оператор в Си: <code>x = x <= 0 ? 0 : x</code>.</p>
</div>

```python
>>> x = 0 if x <= 0 else x
>>> print(x)
```

```python
>>> dis.dis("x = 0 if x <= 0 else x")
  1           0 LOAD_NAME                0 (x)
              2 LOAD_CONST               0 (0)
              4 COMPARE_OP               1 (<=)
              6 POP_JUMP_IF_FALSE       12
              8 LOAD_CONST               0 (0)
             10 JUMP_FORWARD             2 (to 14)
        >>   12 LOAD_NAME                0 (x)
        >>   14 STORE_NAME               0 (x)
             16 LOAD_CONST               1 (None)
             18 RETURN_VALUE
```

### Примеры

```python
email = "Dementiy@yandex.ru"
domains = ["yandex.ru", "mail.ru", "gmail.com"]

if "@" in email and email.split('@')[-1] in domains:
    print("Email указан верно")
else:
    print("Email указан не верно")
```

```python
mark = 71

if mark >= 91:
    grade = 'A'
else:
    if mark >= 85:
        grade = 'B'
    else:
        if mark >= 75:
            grade = 'C'
        else:
            if mark >= 67:
                grade = 'D'
            else:
                if mark >= 60:
                    grade = 'E'
                else:
                    grade = 'F'

print(grade)
```

```python
mark = 71

if mark >= 91:
    grade = 'A'
elif mark >= 85:
    grade = 'B'
elif mark >= 75:
    grade = 'C'
elif mark >= 67:
    grade = 'D'
elif mark >= 60:
    grade = 'E'
else:
    grade = 'F'

print(grade)
```

### Циклы

«Цикл со счётчиком» — цикл, в котором некоторая переменная изменяет своё значение от заданного начального значения до конечного значения с некоторым шагом, и для каждого значения этой переменной тело цикла выполняется один раз.

Синтаксис:

```python
for counter in range(start, stop, step):
    expression
```

```python
for i in range(1,10,2):
    print(i)
```

<table>
    <thead><tr><td><b>Шаблон</b></td><td><b>Пример</b></td><td><b>Результат</b></td></tr></thead>
    <tr><td>range(end)</td><td>range(5)</td><td>[0, 1, 2, 3, 4]</td></tr>
    <tr><td>range(start, end)</td><td>range(1, 5)</td><td>[1, 2, 3, 4]</td></tr>
    <tr><td>range(start, end, step)</td><td>range(1, 10, 2)</td><td>[1, 3, 5, 7, 9]</td></tr>
</table>

```python
>>> dis.dis("for i in range(1, 10, 2): print(i)")
  1           0 SETUP_LOOP              28 (to 30)
              2 LOAD_NAME                0 (range)
              4 LOAD_CONST               0 (1)
              6 LOAD_CONST               1 (10)
              8 LOAD_CONST               2 (2)
             10 CALL_FUNCTION            3
             12 GET_ITER
        >>   14 FOR_ITER                12 (to 28)
             16 STORE_NAME               1 (i)
             18 LOAD_NAME                2 (print)
             20 LOAD_NAME                1 (i)
             22 CALL_FUNCTION            1
             24 POP_TOP
             26 JUMP_ABSOLUTE           14
        >>   28 POP_BLOCK
        >>   30 LOAD_CONST               3 (None)
             32 RETURN_VALUE
```

```python
>>> import random
>>> random.seed(1234)
>>> scores = [random.randint(0, 100) for _ in range(10)]
>>> print(f'Scores: {scores}')
>>> mean_score = 0
>>> for i in range(len(scores)):
...    mean_score += scores[i]
>>> mean_score = mean_score / len(scores)
>>> print(f'Mean score: {mean_score}')
```

Еще один вид циклов со счетчиками – «совместные циклы». Такие циклы задают выполнение некоторой операции для объектов из заданного множества, без явного указания порядка перечисления этих объектов. Такие циклы называются совместными (а также циклами по коллекции, циклами просмотра) и представляют собой формальную запись инструкции вида: «Выполнить операцию `X` для всех элементов, входящих во множество `M`».

Синтаксис:

```python
for item in iterable:
    expression
```

Где `iterable` – итерируемый объект (объект, который реализует протокол итератор). В роли такого объекта могут выступать строки (`str`), списки (`list`), кортежи (`tuple`), словари (`dict`), а также любой класс, объявленный с методом `__iter__()` (об этом в других лекциях).

```python
>>> mean_score = 0
>>> for score in scores:
    mean_score += score
>>> mean_score = mean_score / len(scores)
>>> print(f'Mean score: {mean_score}')
```

Итерирование по списку с получением «индексов»:

```python
for index, word in enumerate(['cool', 'powerful', 'readable'], start=1):
    print('{}: Python is {}!'.format(index, word))
```

Цикл с предусловием — цикл, который выполняется, пока истинно некоторое условие, указанное перед его началом. Это условие проверяется до выполнения тела цикла, поэтому тело может быть не выполнено ни разу (если условие с самого начала ложно).

Синтаксис:

```python
while condition:
    loop_body
```

```python
>>> fact = 1
>>> n = 5
>>> while n:
    fact = fact * n
    n -= 1
>>> fact # 1 * 2 * 3 * 4 * 5
120
```

```python
>>> dis.dis("""...""")
  1           0 LOAD_CONST               0 (1)
              2 STORE_NAME               0 (fact)

  2           4 LOAD_CONST               1 (5)
              6 STORE_NAME               1 (n)

  3           8 SETUP_LOOP              24 (to 34)
        >>   10 LOAD_NAME                1 (n)
             12 POP_JUMP_IF_FALSE       32

  4          14 LOAD_NAME                0 (fact)
             16 LOAD_NAME                1 (n)
             18 BINARY_MULTIPLY
             20 STORE_NAME               0 (fact)

  5          22 LOAD_NAME                1 (n)
             24 LOAD_CONST               0 (1)
             26 INPLACE_SUBTRACT
             28 STORE_NAME               1 (n)
             30 JUMP_ABSOLUTE           10
        >>   32 POP_BLOCK

  6     >>   34 LOAD_NAME                0 (fact)
             36 POP_TOP
             38 LOAD_CONST               2 (None)
             40 RETURN_VALUE
```

### Досрочный выход из цикла

Команда досрочного выхода применяется, когда необходимо прервать выполнение цикла, в котором условие выхода ещё не достигнуто. Такое бывает, например, когда при выполнении тела цикла обнаруживается ошибка, после которой дальнейшая работа цикла не имеет смысла. Её действие аналогично действию команды безусловного перехода (goto) на команду, непосредственно следующую за циклом, внутри которого эта команда находится. Но так как использовать оператор goto – все равно, что поклоняться темным силам, в Python есть более элегантные способы выхода из цикла, которые будут рассмотрены позже.


```python
while True:
    try:
        n = int(input('x? '))
        break
    except ValueError:
        print('x может быть только целого типа')
```

### Пропуск итерации

Данный оператор применяется, когда в текущей итерации цикла необходимо пропустить все команды до конца тела цикла. При этом сам цикл прерываться не должен, условия продолжения или выхода должны вычисляться обычным образом.

```python
scores = [random.randint(0, 100) for _ in range(10)]
scores.extend([None] * 3)
random.shuffle(scores)
print(f'Scores: {scores}')
mean_score = 0
n = 0

for score in scores:
    if score is None:
        continue
    mean_score += score
    n += 1

mean_score = mean_score / n

print(f'Mean score is {mean_score} for {n} scores')
```