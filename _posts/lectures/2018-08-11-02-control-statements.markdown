---
layout: post
title: Лекция 02. Управляющие конструкции
categories: python лекции
---

Во второй лекции мы рассмотрим основные управляющие конструкции языка, такие как условия, циклы и исключения. Также в этой лекции будет наше первое знакомство с виртуальной машиной Python.

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

Давайте рассмотрим пример тела (содержимого) простой функции, используемой в качестве функции активации в нейронных сетях - [ReLU](https://en.wikipedia.org/wiki/Rectifier_(neural_networks)) (Rectified Linear Units), которая возвращает положительное или нулевое значение аргумента:

```python
x = 0.4    # 1
if x <= 0: # 2
    x = 0  # 3
else:
    x = x  # 5
print(x)   # 6
```

Условная конструкция получилась достаточно простой и очевидной, поэтому мы вкратце разберем то, как Python будет «интерпретировать» эти 6 строк кода.

Интерпретация, в простом понимании, означает чтение файла с исходным кодом вашей программы и поэтапное ее выполнение. В Python этапу интерпретации предшествует этап компиляции, то есть, исходный код ваших программ компилируется в [байт-код](https://ru.wikipedia.org/wiki/%D0%91%D0%B0%D0%B9%D1%82-%D0%BA%D0%BE%D0%B4) или другими словами в набор простых инструкций, чем-то напоминающих инструкции CPU, которые и будут выполняться (интерпретироваться) виртуальной машиной Python (в одной из следующих лекций мы будем говорить о том откуда берутся эти инструкции). Давайте посмотрим как выглядит байт-код для приведенного выше примера с помощью модуля [dis](https://docs.python.org/3/library/dis.html) из стандартной библиотеки:


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

Дизассемблированный вывод состоит из нескольких столбцов, краткое описание которых показано на следующем рисунке:

![](/assets/images/lectures/bytecode.svg)

Итак, 6 строк кода были скомпилированы в 17 инструкций (описание инструкций можно найти [тут](https://docs.python.org/3/library/dis.html#python-bytecode-instructions)). Первые две инструкции соответствуют связыванию имени `x` со значением `0.4`. Следующие четыре инструкции посвящены сравнению `x` с нулем. Если результат сравнения оказался ложью, то мы переходим (`POP_JUMP_IF_FALSE`) к выполнению инструкции со смещением 18, в противном случае, переменная `x` связывается со значением `0` и мы переходим (`JUMP_FORWARD`) к выполнению инструкции со смещением 22. Последние шесть инструкций предназначены для вывода содержимого `x`.

Виртуальная машина Python имеет стековую архитектуру, то есть все данные необходимые для выполнения инструкций помещаются (push) на стек или снимаются (pop) с него, такой стек называется стеком данных (data stack или evaluation stack). Для наглядности ниже проиллюстрировано состояние стека при выполнении нескольких первых инструкций:

![](/assets/images/lectures/stack.svg)

Как же выполняются интсрукции? Выполнение инструкций происходит в [бесконечном цикле](https://github.com/python/cpython/blob/master/Python/ceval.c#L926) с условием в несколько тысяч строк кода, в качестве примера ниже представлен соответствующий Си-код для инструкции [`COMPARE_OP`](https://github.com/python/cpython/blob/master/Python/ceval.c#L2677):

```c
TARGET(COMPARE_OP) {
    PyObject *right = POP();
    PyObject *left = TOP();
    PyObject *res = cmp_outcome(oparg, left, right);
    Py_DECREF(left);
    Py_DECREF(right);
    SET_TOP(res);
    if (res == NULL)
        goto error;
    PREDICT(POP_JUMP_IF_FALSE);
    PREDICT(POP_JUMP_IF_TRUE);
    DISPATCH();
}
```

Инструкция достаточно простая, если кратко, то выполняются следующие шаги:

- с вершины стека снимаем значение и сохраняем его в переменной `right`;
- в переменную `left` сохраняем значение, которое находится на вершине стека;
- вызываем функцию сравнения для `left` и `right` и затем результат сохраняем в переменной `res`;
- уменьшаем счетчик ссылок на `left` и `right`;
- результат сравнения помещаем на вершину стека «затерев» старое значение;
- проверяем, что не возникло ошибок при сравнении;
- пытаемся «предсказать» следующую инструкцию и, если возможно, то переходим к ней;
- переходим к следующей инструкции на выполнение не по предсказанию.

Итак, это наше первое знакомство с виртуальной машиной Python и байт-кодом, на протяжении следующих лекций мы будем постепенно детализировать наше понимание работы виртуальной машины Python, тем не менее мы уже можем пожинать плоды первого знакомства, например, мы можем отвечать на вопросы почему одна форма записи некоторого выражения работает быстрее чем другая (попрбуйте сравнить два способа создания словаря [`dict()` и `{}`](https://medium.com/@jodylecompte/dict-vs-in-python-whats-the-big-deal-anyway-73e251df8398)).

#### Продолжая говорить об условиях

В Python есть условные выражения, которые соответствуют тернарному оператору в других языках программирования:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Тернарный оператор в Си: <code>x = x <= 0 ? 0 : x</code>.</p>
</div>

```python
>>> x = 0.4
>>> x = 0 if x <= 0 else x
>>> print(x)
```

```python
>>> dis.dis("x = 0.4; x = 0 if x <= 0 else x; print(x)")
  1           0 LOAD_CONST               0 (0.4)
              2 STORE_NAME               0 (x)
              4 LOAD_NAME                0 (x)
              6 LOAD_CONST               1 (0)
              8 COMPARE_OP               1 (<=)
             10 POP_JUMP_IF_FALSE       16
             12 LOAD_CONST               1 (0)
             14 JUMP_FORWARD             2 (to 18)
        >>   16 LOAD_NAME                0 (x)
        >>   18 STORE_NAME               0 (x)
             20 LOAD_NAME                1 (print)
             22 LOAD_NAME                0 (x)
             24 CALL_FUNCTION            1
             26 POP_TOP
             28 LOAD_CONST               2 (None)
             30 RETURN_VALUE
```

Как и в других языках программирования в условиях мы можем использовать несколько логических выражений объединив их с помощью операторов `and` и `or` (также можно использовать логическое отрицание с помощью оператора `not`):

```python
email = "Dementiy@yandex.ru"
domains = ["yandex.ru", "mail.ru", "gmail.com"]
if "@" in email and email.split('@')[-1] in domains:
    print("Email указан верно")
else:
    print("Email указан не верно")
```

```python
>>> dis.dis("""...""")
..
  3          14 LOAD_CONST               4 ('@')
             16 LOAD_NAME                0 (email)
             18 COMPARE_OP               6 (in)
             20 POP_JUMP_IF_FALSE       50
             22 LOAD_NAME                0 (email)
             24 LOAD_ATTR                2 (split)
             26 LOAD_CONST               4 ('@')
             28 CALL_FUNCTION            1
             30 LOAD_CONST               9 (-1)
             32 BINARY_SUBSCR
             34 LOAD_NAME                1 (domains)
             36 COMPARE_OP               6 (in)
             38 POP_JUMP_IF_FALSE       50
...
  6     >>   50 LOAD_NAME                3 (print)
             52 LOAD_CONST               7 ('Email указан не верно')
             54 CALL_FUNCTION            1
             56 POP_TOP
...
```

Обратите внимание на то, как происходит «объединение» условных выражений в байт-коде с помощью оператора `and`: если символ «собаки» не присутствует в строке с адресом электронной почты, то мы переходим к инструкции по смещению 50 и оставшаяся часть логического выражение не проверяется. Попробуйте заменить логический оператор `and` на `or` и посмотреть как изменится байт-код.

Мы можем вкладывать условные конструкции одна в другую, указывая вложенность отступами:

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

А можем использовать более короткую форму записи с помощью `elif`:

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

Если вы сравните байт-код для приведенных примеров, то он окажется полностью идентичным. Поэтому разница между двумя формами записи `if-else-if` и `if-elif` только стилистическая.

### Циклы

«Цикл со счётчиком» — цикл, в котором некоторая переменная изменяет своё значение от заданного начального значения до конечного значения с некоторым шагом, и для каждого значения этой переменной тело цикла выполняется один раз.

Общая форма записи циклов со счётчиком следующая:

```python
for counter in range(start, stop, step):
    expression
```

Например:

```python
for i in range(1,10,2):
    print(i)
```

Ниже представлены различные варианты использования функции `range`:

<table>
    <thead><tr><td><b>Шаблон</b></td><td><b>Пример</b></td><td><b>Результат</b></td></tr></thead>
    <tr><td>range(end)</td><td>range(5)</td><td>[0, 1, 2, 3, 4]</td></tr>
    <tr><td>range(start, end)</td><td>range(1, 5)</td><td>[1, 2, 3, 4]</td></tr>
    <tr><td>range(start, end, step)</td><td>range(1, 10, 2)</td><td>[1, 3, 5, 7, 9]</td></tr>
</table>

Давайте посмотрим на список инструкций, которые будут выполнены для цикла приведенного выше: 

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

Мы пока не будем говорить про инструкции `SETUP_LOOP` и `POP_BLOCK`. Инструкция `GET_ITER` [получает](https://github.com/python/cpython/blob/master/Python/ceval.c#L2859) итератор для объекта, который находится на вершине стека (в нашем примере это `range(1,10,2)`). `FOR_ITER`	[получает](https://github.com/python/cpython/blob/master/Python/ceval.c#L2902) следующее значение из итератора (в нашем примере это 1,3,5,7,9) и помещает его на вершину стека. Инструкция `STORE_NAME` снимает значение с вершины стека и связывает его с именем `i`. Затем выполняется тело цикла (печать переменной `i`) и все повторяется снова до тех пор пока итератор не будет исчерпан:

![](/assets/images/lectures/foriter.svg)

Рассмотрим чуть более живой пример использования цикла со счетчиком, например, посчитаем средний балл по некоторой дисциплине для группы студентов из 10 человек:

```python
>>> import random
>>> random.seed(1234)
>>> scores = [random.randint(0, 100) for _ in range(10)]
>>> print(f'Scores: {scores}')
Scores: [12, 98, 45, 30, 2, 3, 100, 2, 44, 82]

>>> mean_score = 0
>>> for i in range(len(scores)):
...    mean_score += scores[i]
>>> mean_score = mean_score / len(scores)
>>> print(f'Mean score: {mean_score}')
Mean score: 41.8
```

Еще один вид циклов со счетчиками – «совместные циклы». Такие циклы задают выполнение некоторой операции для объектов из заданного множества, без явного указания порядка перечисления этих объектов. Такие циклы называются совместными (а также циклами по коллекции, циклами просмотра) и представляют собой формальную запись инструкции вида: «Выполнить операцию `X` для всех элементов, входящих во множество `M`».

Общая форма записи таких циклов следующая:

```python
for item in iterable:
    expression
```

Где `iterable` – итерируемый объект (объект, который реализует протокол итератор). В роли такого объекта могут выступать строки (`str`), списки (`list`), кортежи (`tuple`), словари (`dict`), а также любой класс, объявленный с методом `__iter__()` (об этом в других лекциях).

Если переписать предыдущий пример с использованием совместного цикла, то получим:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Если при итерировании нам одновременно необходимо получать «индексы» элементов, то можно воспользоваться функцией <code>enumerate()</code>.</p>
</div>

```python
>>> mean_score = 0
>>> for score in scores:
...    mean_score += score
>>> mean_score = mean_score / len(scores)
>>> print(f'Mean score: {mean_score}')
Mean score: 41.8
```

Разделение на циклы со счетчкиом и совместные циклы является условным. С точки зрения байт-кода они эквивалентны: мы получаем итератор у итерируемого объекта и на каждой итерации у итератора запрашиваем следующий элемент. Более подробно про итераторы мы будем говорить в одной из следующих лекций.

Последний вид циклов это цикл с предусловием — цикл, который выполняется, пока истинно некоторое условие, указанное перед его началом. Это условие проверяется до выполнения тела цикла, поэтому тело может быть не выполнено ни разу (если условие с самого начала ложно).

Общая форма записи циклов с предусловием следующая:

```python
while condition:
    loop_body
```

Рассмотрим пример вычисления факториала числа n:

```python
>>> fact = 1
>>> n = 5
>>> while n:
...    fact = fact * n
...    n -= 1
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

#### Досрочный выход из цикла

Команда досрочного выхода применяется, когда необходимо прервать выполнение цикла, в котором условие выхода ещё не достигнуто. Такое бывает, например, когда при выполнении тела цикла обнаруживается ошибка, после которой дальнейшая работа цикла не имеет смысла. Её действие аналогично действию команды безусловного перехода (goto) на команду, непосредственно следующую за циклом, внутри которого эта команда находится. Но так как использовать оператор goto – все равно, что поклоняться темным силам, в Python есть более элегантные способы выхода из цикла:

```python
>>> n = 9
>>> guess = n
>>> epsilon = 1E-9
>>> while True:
...    last = guess
...    guess = (guess + n / guess) * 0.5
...    if abs(guess - last) < epsilon:
...        break
>>> print(guess)
3.0
```

Давайте посмотрим на байт-код:

```python
...
  4          12 SETUP_LOOP              42 (to 56)

  5     >>   14 LOAD_NAME                1 (guess)
             16 STORE_NAME               3 (last)
...
  7          34 LOAD_NAME                4 (abs)
             36 LOAD_NAME                1 (guess)
             38 LOAD_NAME                3 (last)
             40 BINARY_SUBTRACT
             42 CALL_FUNCTION            1
             44 LOAD_NAME                2 (epsilon)
             46 COMPARE_OP               0 (<)
             48 POP_JUMP_IF_FALSE       14

  8          50 BREAK_LOOP
             52 JUMP_ABSOLUTE           14
             54 POP_BLOCK

  9     >>   56 LOAD_NAME                5 (print)
             58 LOAD_NAME                1 (guess)
             60 CALL_FUNCTION            1
             62 POP_TOP
             64 LOAD_CONST               3 (None)
             66 RETURN_VALUE
```

Настало время поговорить об инструкцях `SETUP_LOOP` и `POP_BLOCK`. Кроме стека данных, о котором мы говорили ранее, есть еще стек блоков (block stack) ограниченного размера, который используется для «открутки» стека данных на момент входа в `for`, `while` или `try`. Таким образом, инструкция `SETUP_LOOP` помещает в стек блоков адрес первой(?) инструкции после цикла, а также текующий размер стека, а `POP_BLOCK` осуществляет непосредственно саму «открутку» стека.

> This is used by Python to keep track of certain types of control structures: loops, try/except blocks, and with blocks all cause entries to be pushed onto the block stack, and the block stack gets popped whenever you exit one of those structures. This helps Python know which blocks are active at any given moment so that, for example, a continue or break statement can affect the correct block.

Обратите внимание, что инструкции со смещениями 52 и 54 никогда не будут выполнены, так как цикл является бесконечным. Выход из цикла осуществляется с помощью оператора `break` и соотвествующей инструкции `BREAK_LOOP`, которая выполняется при условии, что мы достигли необходимой точности при вычислении квадратного корня. Инструкция `BREAK_LOOP`, аналогично инструкции `POP_BLOCK`, осуществляет «открутку» стека и переход к первой инструкции следующей за телом цикла.

Мы не будем уделять особое внимание стеку блоков, так как в Python с версии 3.8 все [немного изменится]( https://docs.python.org/3.8/whatsnew/3.8.html#cpython-bytecode-changes).


#### Пропуск итерации

Данный оператор применяется, когда в текущей итерации цикла необходимо пропустить все команды до конца тела цикла. При этом сам цикл прерываться не должен, условия продолжения или выхода должны вычисляться обычным образом. Рассмотрим простой пример, допустим мы хотим посчитать средний балл, но в данных могут присутствовать пропуски, которые мы не должны учитывать:

```python
>>> scores = [random.randint(0, 100) for _ in range(10)]
>>> scores.extend([None] * 3)
>>> random.shuffle(scores)
>>> print(f'Scores: {scores}')
Scores: [78, None, 1, 11, 23, 19, 79, None, None, 61, 59, 91, 14]

>>> mean_score = 0
>>> n = 0
>>> for score in scores:
...    if score is None:
...        continue
...    mean_score += score
...    n += 1
>>> mean_score = mean_score / n
>>> print(f'Mean score is {mean_score} for {n} scores')
Mean score is 43.6 for 10 scores
```

### Исключения

Если запустить этот код:

```python
>>> 1 / 0
...
ZeroDivisionError: division by zero
```

то мы получим ошибку `ZeroDivisionError` (ошибка деления на ноль). Более корректно называть это исключением.

Существует (как минимум) два различимых вида ошибок:

 - синтаксические ошибки (syntax errors)
 - и исключения (exceptions).

Синтаксические ошибки, появляются во время разбора кода интерпретатором. С точки зрения синтаксиса в коде выше ошибки нет, интерпретатор «видит» деление одного целого числа на другое. Однако в процессе выполнения возникает исключение. Интерпретатор разобрал код, но провести операцию не смог. Таким образом, ошибки, обнаруженные при исполнении, называются исключениями (exceptions).

Исключения бывают разных типов и тип исключения выводится в сообщении об ошибке, например `ZeroDivisionError`, `IndexError`, `KeyError`, `ValueError` и т.д. Для работы с исключениями используется конструкция `try...except`: 

```python
>>> try:
...    result = 1 / 0
... except ZeroDivisionError as e:
...    print(str(e))
division by zero
```