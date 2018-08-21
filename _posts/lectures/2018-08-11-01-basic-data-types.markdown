---
layout: post
title: Лекция 01. Основные типы данных
categories: python лекции
comments: true
---

Эта лекция посвящена рассмотрению основных типов данных, таких как: числа, строки, списки, кортежи, множества и словари. Рассматривается внтуреннее представление некоторых типов, а также «родителя» всех объектов - структуры `PyObject`. На вопрос «Зачем?», можно ответить, что во-первых, Python скрывает «стоимость» выполнения большинства операций, например, «Сколько памяти требуется для создания новой переменной?». Так, массив из тысячи небольших целых чисел на 4 килобайта «тяжелее» чем аналогичный массив вещественных чисел; массив нулей требует меньше памяти, чем аналогичный по длине массив любых других целых чисел и т.д. Во-вторых, когда Python кажется нам недостаточно производительным, то мы используем сторонние библиотеки, такие как numpy, или пишем Си-расширения, а чтобы иметь возможность писать последние - необходимо понимать [Python/C API](https://docs.python.org/3/c-api/index.html).

<script type="text/javascript" async
    src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>

### «Everything is an Object»

В Python все является объектом: числа, последовательности, функции, классы, модули и т.д. Каждый объект обладает уникальным идентификатором, который никогда не изменяется после создания объекта (в CPython идентификатором объекта является его адрес в памяти, который можно получить с помощью встроенной функции `id()`), типом, который определяет «чем является объект» (числом, строкой, списком и т.д.) и какие действия над ним можно выполнять, а также значением.

Каждый объект «наследуется» от Си-структуры [`PyObject`](https://github.com/python/cpython/blob/master/Include/object.h#L106) или `PyVarObject` для объектов переменной (variable) длинны (строки, списки и т.д.):

```c
typedef struct _object {
    _PyObject_HEAD_EXTRA
    Py_ssize_t ob_refcnt;
    struct _typeobject *ob_type;
} PyObject;
```

Где:

 - `_PyObject_HEAD_EXTRA` - макрос, который определяет два поля `_ob_next` и `_ob_prev` - указатели на следующий и предыдущий объекты, соответственно. Будут ли эти поля включены в структуру `PyObject` или нет - зависит от флага `Py_TRACE_REFS`, который по умолчанию не установлен;
 - `ob_refcnt` - счетчик ссылок на объект, который увеличивается или уменьшается, при копировании или удалении указателя на объект; когда счетчик ссылок достигает нуля, то объект удаляется. Про подсчет ссылок и «сборку мусора» мы будем говорить в одной из следующих лекций;
 - `ob_type` - указатель на структуру [`_typeobject`](https://docs.python.org/3/c-api/typeobj.html), которая задает тип объекта (более подробно об этой структуре мы будем говорить в лекции «Си-расширения»).

Структура `PyVarObject` включает одно дополнительное поле `ob_size` - количество элементов в объекте (например, для списка из пяти элементов `ob_size` будет равен 5):

```c
typedef struct {
    PyObject ob_base;
    Py_ssize_t ob_size; /* Number of items in variable part */
} PyVarObject;
```

Итак, если вы решили ввести свой тип, то он должен «наследоваться» от `PyObject` или `PyVarObject` с помощью макросов `PyObject_HEAD` и `PyObject_VAR_HEAD`:

```c
#define PyObject_HEAD          PyObject ob_base;
...
#define PyObject_VAR_HEAD      PyVarObject ob_base;
```

Например:

```c
typedef struct _myobject {
       PyObject_HEAD
       ...
} PyMyObject;
```

Таким образом, `PyMyObject` будет содержать все поля, которые есть в `PyObject`.

Следует помнить, что макрос `PyObject_HEAD` должнен идти первым в структуре. Это связано с «наследованием», о котором говорилось ранее. Как утверждается в [`object.h`](https://github.com/python/cpython/blob/master/Include/object.h#L40):

> Objects are always accessed through pointers of the type `PyObject *`

и означает, что должна быть возможность приведения (casting) указателя на `PyMyObject` к указателю на `PyObject`, то есть:

```c
PyObject *obj = (PyObject*)my_py_type_variable;
```

Мы вкратце рассмотрели наиболее общие структуры для представления объектов в CPython, но пока не говорили о том как создаются новые объекты. В одной из последующих лекций мы вернемся к этому вопросу. Далее мы рассмотрим основные типы данных и внутреннее представление некоторых из них.

### Целочисленный тип данных и числа с плавающей точкой

Без использования стандартной библиотеки языка нам доступны целые числа (int), вещественные числа (float) и комплексные числа (complex).

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Процесс создания новой переменной называется name binding, то есть связывание имени с некоторым объектом, в данном случае именем выступает <code>year</code>, а объектом целое число <code>2018</code>.</p>
</div>

```python
>>> year = 2018
>>> year
2018
>>> type(year)
int
>>> type(2018)
int
```

У каждого типа обычно есть «конструктор»:

```python
>>> zero = int()
>>> zero
0
>>> zero = float()
>>> zero
0.0
```

Основные арифметические операции:

```python
>>> year + 1
2019
>>> year - 1
2017
>>> year * 12
24216
>>> year * 365.25
737074.5
>>> year / 100
20.18
```

Взятие целой части и остатка от деления:
```python
>>> year // 100
20
>>> year % 100
18
```

Для записи очень больших или очень маленьких чисел удобно использовать экспоненциальную форму записи чисел. Сравните:

```python
>>> 2.018 * 10**3
2017.9999999999998
>>> 2.018E3
2018.0
```

И не стоит забывать про [ошибки округления](https://floating-point-gui.de/errors/rounding/) при работе с вещественными числами:

```python
>>> 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1
0.9999999999999999
```

### Длинная арифметика в Python

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Значительная часть материала про представление целых чисел взята из статьи Артема Голубина: <a href="https://rushter.com/blog/python-integer-implementation/">Python Integer Implementation</a>.</p>
</div>

Может ли произойти переполнение при работе с целыми числами в Python? Нет, если мы **не** говорим о таких пакетах как Numpy и Pandas, так как при работе с целыми числами в Python используется [длинная арифметика](https://ru.wikipedia.org/wiki/%D0%94%D0%BB%D0%B8%D0%BD%D0%BD%D0%B0%D1%8F_%D0%B0%D1%80%D0%B8%D1%84%D0%BC%D0%B5%D1%82%D0%B8%D0%BA%D0%B0).

Следующая структура отвечает за представление целых чисел:

```c
struct _longobject {
    PyObject_VAR_HEAD
    digit ob_digit[1];
} PyLongObject;
```

Если «раскрыть» макрос `PyObject_VAR_HEAD`, то стурктура будет выглядеть следующим образом:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Вы должны были заметить, что <code>PyLongObject</code> «наследуется» от <code>PyVarObject</code>, то есть является объектом переменной длины, и, таким образом, включает поле <code>ob_size</code>, которое в данном случае содержит размер массива <code>ob_digit</code>.</p>
</div>

```c
struct _longobject {
    ssize_t ob_refcnt;
    struct _typeobject *ob_type;
    ssize_t ob_size; 
    uint32_t ob_digit[1];
} PyLongObject;
```

Все поля вам уже должны быть знакомы, `PyLongObject` добавляет лишь одно новое поле `ob_digit` - массив беззнаковых целых чисел по основанию $$2^{30}$$. Давайте разберемся с назначением этого поля.

### Представление произвольно больших целых чисел

Как хранить произвольно большое целое число? Одним из решений является представление целого числа в виде массива отдельных цифр. Для наиболее эффективного использования памяти мы можем конвертировать наше число из десятичной системы счисления в систему счисления по основанию $$2^{30}$$, в таком случае каждый элемент представлен «цифрой» в диапазоне от $$0$$ до $$2^{30} - 1$$. В зависимости от платформы Python использует или 32-битные беззнаковые массивы с 30-битными цифрами или 16-битные беззнаковые массивы с 15-битными цифрами. Такой подход представления больших целых чисел связан с [дополнительными ограничениями](https://github.com/python/cpython/blob/865e4b4f630e2ae91e61239258abb58b488f1d65/Include/longintrepr.h#L9), которые и не позволяют использовать все биты. Поле `ob_digit` структуры показанной выше, содержит такие массивы цифр. 

Для избежания лишних вычислений в CPython есть эффективный способ представления целых чисел в диапазоне от $$-2^{30}$$ до $$2^{30}$$. Такие целые числа хранятся как массивы с одним элементом, то есть, состоящие из одной цифры.

Также следует отметить, что в отличие от классического представления знака числа (т.е. использования знакового бита), знак целого числа хранится в поле `ob_size`, которое также содержит размер массива `ob_digit`. Например, если мы хотим изменить знак целого с размером `ob_size=2` (две цифры), то `ob_size` станет равным `-2`.

Комментарий из исходных текстов по представлению целых чисел:

```c
/* Long integer representation.
   The absolute value of a number is equal to
   SUM(for i=0 through abs(ob_size)-1) ob_digit[i] * 2**(SHIFT*i)
   Negative numbers are represented with ob_size < 0;
   zero is represented by ob_size == 0.
   In a normalized number, ob_digit[abs(ob_size)-1] (the most significant
   digit) is never zero.  Also, in all cases, for all valid i,
   0 <= ob_digit[i] <= MASK.
   The allocation function takes care of allocating extra memory
   so that ob_digit[0] ... ob_digit[abs(ob_size)-1] are actually available.

   CAUTION:  Generic code manipulating subtypes of PyVarObject has to aware that integers abuse  ob_size's sign bit.
*/
```

Давайте рассмотрим конкретный пример преобразования длинного целого в массив и обратно. Пусть у нас имеется следующее число: $$123456789101112131415$$. Переведем его в систему счисления по основанию $$2^{30}$$, путем последовательного деления и записи остатка от деления:

**<span style="color: red">TODO: Вставить картинку с процессом деления и структурой PyLongObject</span>**

Конвертировать число обратно также достаточно просто:

$$(437976919 ∗ 2^{30 ∗ 0}) + (87719511 ∗ 2^{30 ∗ 1}) + (107 ∗ 2^{30 ∗ 2}) = 123456789101112131415$$

### Преобразования длинного целого в массив

Ниже приведен упрощенный вариант алгоритма представления произвольно больших чисел:

```python
SHIFT = 30  # Число бит под каждую «цифру»
MASK = (2 ** SHIFT)

def split_number(bignum):
    t = abs(bignum)

    num_list = []
    while t != 0:
        # Взятие остатка от деления
        small_int = t % MASK  # Побитовый аналог: (t & (MASK-1))
        num_list.append(small_int)

        # Взятие целой части от деления
        t = t // MASK  # Побитовый аналог: t >>= SHIFT

    return num_list

def restore_number(num_list):
    bignum = 0
    for i, n in enumerate(num_list):
        bignum += n * (2 ** (SHIFT * i))
    return bignum
```

```python
>>> bignum = 123456789101112131415
>>> num_list = split_number(bignum)
>>> num_list
[437976919, 87719511, 107]
>>> bignum == restore_number(num_list)
True
```

Если мы хотим убедиться, что нигде не ошиблись, то можем посмотреть на внутреннее представление целого числа с помощью модуля [ctypes](https://docs.python.org/3/library/ctypes.html), который позволяет взаимодействовать с Си-кодом из Python:

```python
import ctypes

class PyLongObject(ctypes.Structure):
    _fields_ = [("ob_refcnt", ctypes.c_ssize_t),
                ("ob_type", ctypes.c_void_p),
                ("ob_size", ctypes.c_ssize_t),
                ("ob_digit", ctypes.c_uint * 3)]
```
```python
>>> bignum = 123456789101112131415
>>> for i,d in enumerate(PyLongObject.from_address(id(bignum)).ob_digit):
...    print(f"ob_digit[{i}] = {d}")
ob_digit[0] = 437976919
ob_digit[1] = 87719511
ob_digit[2] = 107
>>> print("ob_size:", PyLongObject.from_address(id(bignum)).ob_size)
ob_size: 3
```

### Оптимизации

Небольшие целые числа в диапазоне от `-5` до `256` преаллоцируются в процессе инициализации интерпретатора. Так как целые числа являются неизменяемыми, то мы можем воспринимать их как [синглтоны](https://en.wikipedia.org/wiki/Singleton_pattern). Каждый раз, когда нам необходимо создать небольшое целое число (например, как результат некоторой арифметической операции), то вместо создания нового объекта, Python просто возвращает указатель на уже преаллоцированный объект. Это позволяет сократить количество потребляемой памяти и время затрачиваемое на вычисления при работе с небольшими целыми числами.

Давайте рассмотрим простой пример:

```python
>>> a = 2
>>> id(a)
94220163919104
```

```python
>>> a = a + 1
>>> id(a)
94220163919136
```

```python
>>> b = 2
>>> id(b)
94220163919104
```

Следует иметь ввиду, что структура `PyLongObject` занимает не менее 28 байт для каждого целого числа, то есть в три раза больше чем требуется под 64-битное целое в языке C.


```python
>>> import sys
>>> sys.getsizeof(1)
28
```

Из чего складывается такой размер? Указатель на структуру `_typeobject` занимает восемь байт, также по восемь байт занимают поля `ob_refcnt` и `ob_size`, что уже в сумме дает нам 24 байта. Каждый элемент массива `ob_digit` это еще четыре байта. Итого для небольших целых чисел требуется 28 байт. Но есть одно исключение - [ноль](https://stackoverflow.com/a/10365639/1724257):

```python
>>> import sys
>>> sys.getsizeof(0)
24
```

### Выполнение арифметических операций

Базовые арифметические операции выполняются аналогично тому, как мы это делали когда-то в школе, с одним исключением: каждый элемент массива считается «цифрой».

Давайте рассмотрим вариант алгоритма сложения с [переносом]( https://en.wikipedia.org/wiki/Carry_(arithmetic)):

```python
def add_bignum(a, b):
    z = []

    if len(a) < len(b):
        # Убедимся, что в «a» наибольшее из двух значений
        a, b = b, a

    carry = 0

    for i in range(0, len(b)):
        carry += a[i] + b[i]
        z.append(carry % MASK)
        carry = carry // MASK

    for i in range(i + 1, len(a)):
        carry += a[i]
        z.append(carry % MASK)
        carry = carry // MASK

    z.append(carry)

    # Удалим завершающие нули
    i = len(z)
    while i > 0 and z[i-1] == 0:
        i -= 1
    z = z[0:i]

    return z
```

```python
>>> a = 8223372036854775807
>>> b = 100037203685477
>>> restore_number(add_bignum(split_number(a), split_number(b))) == a + b
True
```

### Замечание про Numpy и Pandas

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">См. <a href="http://mortada.net/can-integer-operations-overflow-in-python.html">«Can integer operations overflow in Python»</a>.</p>
</div>

В тех случаях, когда мы пользуемся библиотеками numpy/scipy/pandas и т.д., может произойти переполнение при работе с целыми числами, так как структуры, лежащие в основе этих библиотек, для более эффективного использования памяти, полагаются на соответствующие С-типы ограниченной точности:

```python
>>> import numpy as np
>>> ar = np.array([2**63 - 1, 2**63 - 1])
>>> ar
array([9223372036854775807, 9223372036854775807])
>>> ar.dtype
dtype('int64')
```

Элементами `ndarray` являются 64-битные знаковые целые, таким обрзаом, $$2^{63}-1$$ наибольшее положительное значение, которое мы можем хранить в `ndarray`. Добавление 1 приведет к  переполнению (overflow):

```python
>>> ar + 1
array([-9223372036854775808, -9223372036854775808])
>>> np.sum(ar)
-2
```

При вычислении среднего элементы массива сначала приводятся к типу `float` и переполнения не возникает:

```python
>>> np.mean(ar)
9.2233720368547758e+18
```

### Числа с плавающей точкой и стандарт IEEE-754

Вещественные числа в CPython представлены следующей структурой:
    
```c
typedef struct {
    PyObject_HEAD
    double ob_fval;
} PyFloatObject;
```

Легко заметить, что поле `ob_fval` это обычное вещественное число двойной точности. Все арифметические операции над вещественными числами в Python являются простыми обертками над соответствующими арифметическими операциями в Си, например, операция [сложения](https://github.com/python/cpython/blob/master/Objects/floatobject.c#L534) определена следующим образом:

```c
static PyObject *
float_add(PyObject *v, PyObject *w)
{
    double a,b;
    CONVERT_TO_DOUBLE(v, a);
    CONVERT_TO_DOUBLE(w, b);
    PyFPE_START_PROTECT("add", return 0)
    a = a + b;
    PyFPE_END_PROTECT(a)
    return PyFloat_FromDouble(a);
}
```

Следует помнить, что все вычисления в вещественных числах делаются компьютером с некоторой ограниченной точностью (см. стандарт [IEEE-754](http://www.softelectro.ru/ieee754.html)), поэтому зачастую вместо «честных» ответов получаются приближенные (к этому надо быть готовым), например:

```python
>>> 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1
0.9999999999999999
```

Если вы не понимаете почему мы не получили единицу, то попробуйте перевести число $$0.1$$ в двоичную систему счисления:

$$0.1 = \frac{1}{10} = 0*2^{-1} + 0*2^{-2} + 0*2^{-3} + 1*2^{-4} + 1*2^{-5} + ... = 00011(0011)$$

В некоторых случаях на помощь может придти модуль `fmath`:

```python
>>> from math import fsum
>>> sum([0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1])
0.9999999999999999
>>> fsum([0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1])
1.0
```

### Булевый тип


```python
>>> to_be = True
>>> to_be or not to_be
True
```

```python
>>> is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
>>> is_leap
False
```

```python
>>> True or abrakadabra_or_lazy_evaluation
True
```

```python
>>> isinstance(True, bool) and isinstance(True, int)
True
```

### Строки

```python
>>> first_name = 'Dmitrii'
>>> last_name = 'Sorokin'
>>> email = 'Dementiy@yandex.ru'
```

```python
>>> full_name = first_name + ' ' + last_name
>>> full_name
```

```python
>>> full_name = ' '.join([first_name, last_name])
>>> full_name
```

Еще раз вспомним, что в Python все является объектом. Каждый объект предоставляет интерфейс (методы) взаимодействия с ним, а также хранит внутреннее состояние посредством переменных. Обращение к методам и переменным объекта (атрибутам) происходит через точку, например: `объект.метод(список аргументов)`. Чтобы посмотреть список доступных методов можно воспользоваться функцией `help` и передать в нее интересующий нас объект, например: `help(объект)`.

```python
>>> len(full_name) # --> full_name.__len__()
15
```

```python
>>> username, domain = email.split('@')
>>> username
'Dementiy'
>>> domain
'yandex.ru'
```

```python
>>> email.endswith('yandex.ru')
True
```

```python
>>> first_name[0]
'D'
```

```python
>>> first_name[-1]
'i'
```

```python
>>> first_name[-1] = 'y'
...
TypeError: 'str' object does not support item assignment
```

```python
>>> email[:email.index('@')]
'Dementiy'
```

Замечание про срезы
- `sequence[start:stop:step]`, где:
- `sequence` - объект, который реализует Sequence протокол;
- `start` - левая граница среза, может быть опущена, тогда принимается равной $$0$$;
- `stop` - правая граница среза минус $$1$$, таким образом, правая граница не включается; может быть опущена, тогда принимается равной `len(sequence)`;
- `step` - шаг, с которым перемещаемся по `sequence`, если не указан, то считается равным $$1$$.


```c
/* ASCII-only strings created through PyUnicode_New use the PyASCIIObject
   structure. state.ascii and state.compact are set, and the data
   immediately follow the structure. utf8_length and wstr_length can be found
   in the length field; the utf8 pointer is equal to the data pointer. */
typedef struct {
    PyObject_HEAD
    Py_ssize_t length;          /* Number of code points in the string */
    Py_hash_t hash;             /* Hash value; -1 if not set */
    struct {
        unsigned int interned:2;
        unsigned int kind:3;
        unsigned int compact:1;
        unsigned int ascii:1;
        unsigned int ready:1;
        unsigned int :24;
    } state;
    wchar_t *wstr;              /* wchar_t representation (null-terminated) */
} PyASCIIObject;
```

### Интернирование строк


```python
s1 = "foo!"
s2 = "foo!"
s1 is s2
```

```python
s1 = "a"
s2 = "a"
s1 is s2
```

https://github.com/python/cpython/blob/master/Objects/unicodeobject.c#L15171

```python
interned = None

def intern(string):
    global interned
    
    if string is None or not type(string) is str:
        raise TypeError

    if interned is None:
        interned = {}

    t = interned.get(string)
    if t is not None:
        return t

    interned[string] = string
    return string
```

```python
import sys
s1 = sys.intern("foo!")
s2 = sys.intern("foo!")
s1 is s2
```

Использование интернирования строк гарантирует, что не будет создано двух одинаковых строковых объектов. Когда вы создаете второй объект с тем же значением, что и у существующего объекта, то вы получаете ссылку на уже существующий объект. Таким образом, интернирование строк позволяет экономить память и повышает скорость сравнения строк, путем сравнения их адресов (хешей), а не содержимого.

1. [Python String Interning](http://guilload.com/python-string-interning/)

### Списки

```python
>>> scores = []
>>> scores
[]
```

```python
>>> scores = [90.4, 83, 85, 72.3, 65, 84.5, 76, 80, 64.9, 61]
>>> scores
[90.4, 83, 85, 72.3, 65, 84.5, 76, 80, 64.9, 61]
```

```python
>>> scores[0]
90.4
```

```python
>>> len(scores)
10
```

```python
>>> mean_score = sum(scores) / len(scores)
>>> mean_score
```

```python
>>> scores.append(90)
>>> scores
[90.4, 83, 85, 72.3, 65, 84.5, 76, 80, 64.9, 61, 90]
```

```python
>>> scores.extend([58, 91.5, 79])
>>> scores
[90.4, 83, 85, 72.3, 65, 84.5, 76, 80, 64.9, 61, 90, 58, 91.5, 79]
```

```python
>>> scores_copy = scores.copy() # == scores[:] == list(scores)
>>> scores_copy
[90.4, 83, 85, 72.3, 65, 84.5, 76, 80, 64.9, 61, 90, 58, 91.5, 79]
```

```python
>>> sorted(scores, reverse=True)
```

### Списки как динамические массивы

Списки в Python являются обычными [динамическими массивами](https://en.wikipedia.org/wiki/Dynamic_array) (вектор в C++) и обладают всеми их свойствами с точки зрения производительности: в частности, обращение к элементу по его индексу имеет сложность $$O(1)$$, а поиск элемента имеет сложность $$O(N)$$.

Списки в CPython определены с помощью следующей [структуры](https://github.com/python/cpython/blob/master/Include/listobject.h#L23):

```c
typedef struct {
    PyObject_VAR_HEAD
    /* Vector of pointers to list elements.  list[0] is ob_item[0], etc. */
    PyObject **ob_item;

    /* ob_item contains space for 'allocated' elements.  The number
     * currently in use is ob_size.
     * Invariants:
     *     0 <= ob_size <= allocated
     *     len(list) == ob_size
     *     ob_item == NULL implies ob_size == allocated == 0
     * list.sort() temporarily sets allocated to -1 to detect mutations.
     *
     * Items must normally not be NULL, except during construction when
     * the list is not yet visible outside the function that builds it.
     */
    Py_ssize_t allocated;
} PyListObject;
```

Где:
- `ob_item` - массив указателей на `PyObject`;
- `allocated` - емкость списка (размер буффера), то есть сколько элементов можно поместить в массив `ob_item` до его увеличения, в то время как `ob_size` - текущее количество элементов в массиве.

![](/assets/images/lectures/lecture01-03.jpg)

```c
/* This over-allocates proportional to the list size, making room
 * for additional growth.  The over-allocation is mild, but is
 * enough to give linear-time amortized behavior over a long
 * sequence of appends() in the presence of a poorly-performing
 * system realloc().
 * The growth pattern is:  0, 4, 8, 16, 25, 35, 46, 58, 72, 88, ...
 * Note: new_allocated won't overflow because the largest possible value
 *       is PY_SSIZE_T_MAX * (9 / 8) + 6 which always fits in a size_t.
 */
new_allocated = (size_t)newsize + (newsize >> 3) + (newsize < 9 ? 3 : 6);
```

Давайте посмотрим на процесс перераспределения памяти в действии с помощью модуля ctypes.

```python
class ListStruct(ctypes.Structure):
    _fields_ = [("ob_refcnt", ctypes.c_ssize_t),
                ("ob_type", ctypes.c_void_p),
                ("ob_size", ctypes.c_ssize_t),
                ("ob_item", ctypes.c_long),  # PyObject** pointer cast to long
                ("allocated", ctypes.c_ssize_t)]
    
    def __repr__(self):
        return f"ListStruct(ob_size={self.ob_size}, allocated={self.allocated})"
```

Создадим пустой список:

```python
>>> L = []
>>> ls = ListStruct.from_address(id(L))
>>> ls
ListStruct(ob_size=0, allocated=0)
```

Пустой список имеет размер ноль и емкость ноль. Добавим один элемент:

```python
>>> L.append(1)
>>> ls
ListStruct(ob_size=1, allocated=4)
```

Как мы видим и размер и емкость списка изменились в соответствии с правилом роста.

```python
>>> L.extend([2,3,4])
>>> ls
ListStruct(ob_size=4, allocated=4)
>>> L.append(5)
>>> ls
ListStruct(ob_size=5, allocated=8)
```

![](/assets/images/lectures/lecture01-04.jpg)

### Кортежи

```python
point = (1, 2, 3)
point
```

```python
point[0] = 4
...
TypeError: 'tuple' object does not support item assignment
```

Кортежи vs списков:
- С точки зрения внутреннего представления, кортежи также являются динамическими массивами.
- Кортежи занимают меньше места в памяти, так как имеют фиксированную длину.
- Кортежи неизменяемые (immutable) и могут быть выступать в качестве ключей словарей или элементов множеств.
- Кортежи обычно представляют абстрактные объекты, обладающие некоторой структурой.


```c
typedef struct {
    PyObject_VAR_HEAD
    PyObject *ob_item[1];

    /* ob_item contains space for 'ob_size' elements.
     * Items must normally not be NULL, except during construction when
     * the tuple is not yet visible outside the function that builds it.
     */
} PyTupleObject;
```


Вопрос:
 - Размер в байтах([1,1,1,1,1]) = Размер в байтах((1,1,1,1,1))?
 - Размер в байтах([1,1,1,1,1]) > Размер в байтах((1,1,1,1,1))?
 - Размер в байтах([1,1,1,1,1]) < Размер в байтах((1,1,1,1,1))?

### Словари

Словари являются одной из самых важных и сложных структур в Python и мы с ними будем постоянно встречаться. В отличие от списков, которые являются упорядоченными последовательностями элементов произвольного типа, элементы словаря это неупорядоченные(?) последовательности пар *ключ:значение*.

Иногда словари называют [ассоциативными массивами](https://ru.wikipedia.org/wiki/%D0%90%D1%81%D1%81%D0%BE%D1%86%D0%B8%D0%B0%D1%82%D0%B8%D0%B2%D0%BD%D1%8B%D0%B9_%D0%BC%D0%B0%D1%81%D1%81%D0%B8%D0%B2), иногда отображениями (имеется ввиду отображение множества ключей словаря в множество его значений).

Как и списки, словари имеют переменную длину, произвольную вложенность и могут хранить значения произвольных типов.

Создадим словарь с данными о населении ряда стран (ключами в таком словаре будут страны, а значениями - размер населения):

```python
>>> population_by_countries = {
    'India': 1326801576,
    'Brazil': 209567920,
    'China': 1382323332,
    'Nigeria': 186987563,
    'Bangladesh': 162910864,
    'U.S.': 324118787,
    'Russia': 143439832,
    'Pakistan': 192826502,
    'Mexico': 128632004
}
```

Иногда у нас есть отдельно списки ключей и значений, из которых мы хотим создать словарь:

```python
>>> countries = ['India', 'Brazil', 'China', 'Nigeria', 'Bangladesh', 'U.S.', 'Russia', 'Pakistan', 'Mexico']
>>> populations = [1326801576, 209567920, 1382323332, 186987563, 162910864, 324118787, 143439832, 192826502, 128632004]
>>> dict(zip(countries, populations))
{'Bangladesh': 162910864,
 'Brazil': 209567920,
 'China': 1382323332,
 'India': 1326801576,
 'Mexico': 128632004,
 'Nigeria': 186987563,
 'Pakistan': 192826502,
 'Russia': 143439832,
 'U.S.': 324118787}
```

Обращение к элементам словаря похоже на обращение к элементам последовательностей, только вместо индекса используется ключ:

```python
>>> population_by_countries['Russia']
143439832
>>> population_by_countries['Russia'] = 143439832 + 1
>>> population_by_countries['Russia']
143439833
```

Добавим новую пару:

```python
>>> population_by_countries['Japan'] = 126323715
>>> population_by_countries
{'Bangladesh': 162910864,
 'Brazil': 209567920,
 'China': 1382323332,
 'India': 1326801576,
 'Japan': 126323715,
 'Mexico': 128632004,
 'Nigeria': 186987563,
 'Pakistan': 192826502,
 'Russia': 143439833,
 'U.S.': 324118787}
```

При попытке извлечь значение с несуществующим ключом, генерируется
исключение «Ключа не существует»:

```python
>>> population_by_countries['Poland']
...
KeyError: 'Poland'
```

С помощью оператора `in` можно проверить существует ли ключ в словаре. Оператор `in` работает со всеми контейнерами (строки, списки, кортежи, словари, множества), но для последовательностей (строки, списки, кортежи) эта операция является медленной:

```python
>>> "Russia" in population_by_countries
True
>>> "Poland" in population_by_countries
False
```

Можно воспользоваться методом `get`, опционально указав значение, которое будет возвращено, если ключ не был найден:

```python
>>> population_by_countries.get('Poland') # None
>>> population_by_countries.get('Poland', 'NA')
'NA'
```

Иногда нужно получить отдельно «список» ключей, значенией или кортежей (ключ, значение):

```python
>>> population_by_countries.keys()
dict_keys(['India', ..., 'Japan'])
>>> population_by_countries.values()
dict_values([1326801576, ..., 126323715])
>>> population_by_countries.items()
dict_items([('India', 1326801576), ..., ('Japan', 126323715)])
```

Вы не можете упорядочить словарь по ключам или значениям, но можете получить список кортежей и упорядочить его:

```python
>>> from operator import itemgetter
>>> sorted(population_by_countries.items(), key=itemgetter(1), reverse=True)
[('China', 1382323332),
 ('India', 1326801576),
 ('U.S.', 324118787),
 ('Brazil', 209567920),
 ('Pakistan', 192826502),
 ('Nigeria', 186987563),
 ('Bangladesh', 162910864),
 ('Russia', 143439833),
 ('Mexico', 128632004),
 ('Japan', 126323715)]
```

Зачастую словари используются для представления куда более сложных структур, например:

```python
>>> import requests
>>> response = requests.get('https://api.openweathermap.org/data/2.5/weather?q=Saint Petersburg&units=metric&APPID=a46b3bb83f9e16e2ee203e9ecfca99f8')
>>> response.json()
{'base': 'stations',
 'clouds': {'all': 75},
 'cod': 200,
 'coord': {'lat': 59.94, 'lon': 30.32},
 'dt': 1519380000,
 'id': 498817,
 'main': {'humidity': 85,
          'pressure': 1027,
          'temp': -11,
          'temp_max': -11,
          'temp_min': -11},
 'name': 'Saint Petersburg',
 'sys': {'country': 'RU',
         'id': 7267,
         'message': 0.0041,
         'sunrise': 1519362815,
         'sunset': 1519398694,
         'type': 1},
 'visibility': 9000,
 'weather': [{'description': 'light snow',
              'icon': '13d',
              'id': 600,
              'main': 'Snow'}],
 'wind': {'deg': 280, 'speed': 3}}
```

### Хеширование

Мы не будем рассматривать внутреннее представление словарей, так как они устроены значительно сложнее чем объекты, которые мы рассматривали ранее. Для интересующихся можно посмотреть выступления [Raymond Hettinger](https://www.youtube.com/watch?v=p33CVV29OG8) и [Brandon Rhodes](https://www.youtube.com/watch?v=66P5FMkWoVU) о работе словарей, или почитать исчерпывающую презентацию [Дмитрия Алимова](https://www.slideshare.net/delimitry/python-dict-66233023) об эволюции словарей, начиная с Python 2.x.

Тем не менее следует знать, что ключами словарей могут быть только хешируемые объекты, то есть те объекты, для которых определена хеш-функция (обычно это числа, строки и кортежи).

Существует множество видов хеш-функций и для того, чтобы дать вам интуицию того, что из себя представляет хеш-функция, рассмотрим пример слабой хеш-функции и ее использования:

<iframe width="800" height="500" frameborder="0" src="https://pythontutor.com/iframe-embed.html#code=def%20my_hash%28astring%29%3A%0A%20%20%20%20h%20%3D%200%0A%20%20%20%20for%20pos%20in%20range%28len%28astring%29%29%3A%0A%20%20%20%20%20%20%20%20h%20%2B%3D%20pos%20*%20ord%28astring%5Bpos%5D%29%0A%20%20%20%20return%20h%0A%20%20%20%20%0AL%20%3D%20%5BNone,%20None,%20None,%20None,%20None%5D%0A%0Aindex%20%3D%20my_hash%28%22cat%22%29%20%25%20len%28L%29%20-%201%0AL%5Bindex%5D%20%3D%20%22cat%22%0A%0Aindex%20%3D%20my_hash%28%22dog%22%29%20%25%20len%28L%29%20-%201%0AL%5Bindex%5D%20%3D%20%22dog%22&codeDivHeight=400&codeDivWidth=350&cumulative=false&curInstr=0&heapPrimitives=false&origin=opt-frontend.js&py=3&rawInputLstJSON=%5B%5D&textReferences=false"> </iframe>

Фактически мы получили очень наивную реализацию [хеш-таблицы](https://en.wikipedia.org/wiki/Hash_table) (словаря).

### Множества

```python
>>> a_set = {1, 2, 1, 3, 3, 4, 2, 5}
>>> a_set
{1, 2, 1, 3, 3, 4, 2, 5}
```

```python
>>> {1, 2, 1, 3, 3, 4, 2, 5} == {1, 2, 3, 4, 5}
True
```

```python
>>> 1 in a_set
True
>>> 6 in a_set
False
```

```python
>>> {1, 2, 3} | {1, 4, 5}
{1, 2, 3, 4, 5}
>>> {1, 2, 3} & {1, 4, 5}
{1}
>>> {1, 2, 3} - {1, 4, 5}
{2, 3}
```