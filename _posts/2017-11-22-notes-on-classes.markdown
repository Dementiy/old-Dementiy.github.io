---
layout: post
title: Заметки по классам в Python
categories: python classes oop blog
---

Это краткий конспект по классам, который не является исчерпывающим руководством. Также я не даю определений таким понятиям как ООП, класс, объект и т.п. Все эти определения вы можете легко найти в сети.

### Процедурный подход

Представьте, что вы пишите веб-сервис и перед вами встала следующая задача: «*Как представить пользователя системы в программе?*». Давайте договоримся, что у каждого пользователя должны быть следующие атрибуты:

* имя \(username\)
* адрес электронной почты \(email\)
* пароль \(password\)

Можно представить пользователя в виде нескольких переменных:

```py
username = 'bob'
email = 'bob@example.com'
password = 'foobar'
```

У такого подхода есть несколько недостатков:

1. Мы пониманием, что переменные логически должны быть связаны между собой, но мы эту связь никак не показали. Другими словами, переменная `username`  может содержать имя одного пользователя, `email` относиться ко второму пользователю, а `password` к третьему.
2. Если нам необходимо одновременно взаимодействовать с несколькими пользователями, то для каждого из них нужно создавать по три таких переменных.

Как показать, что существует логическая связь между этими переменными? Мы можем использовать любую подходящую структуру: список, словарь, кортеж, именованный кортеж. Как пример будем использовать словарь \(именованный кортеж, т.е. [`namedtuple`](https://www.blog.pythonlibrary.org/2016/03/15/python-201-namedtuple/), было бы использовать нечестно\):

```py
# Представление отдельно взятого пользователя
user = {
    'username': 'bob',
    'email': 'bob@example.com',
    'password': 'foobar'
}

# А так мы теперь можем представить список пользователей
users_list = [
    {'username': 'bob', 'email': 'bob@example.com', 'password': 'foobar'},
    {'username':'joe', 'email': 'joe@example.com', 'password': 'barfoo'},
]
```

Таким образом, объединив несколько значений \(имя, адрес электронной почты и пароль\) в контейнер, мы попытались показать, что существует логическая связь между этими значениями.

Теперь напишем простую функцию, которая возвращает имя пользователя:

```py
def get_username(user):
    return user['username']


>>> get_username(user)
'bob'
```

Так как пользователь представлен словарем, то мы возвращаем значение по ключу `username`, которое соответствует имени.

Одним из недостатков такого подхода является то, что мы не показали логическую связь между данными о пользователе и той функцией, которая должна с ними работать.

В решении этой проблемы нам могут помочь классы, задача которых объединить данные и методы работы с ними.

### Создание простого класса

Начнем с создания простого класса:

```py
class User:
    pass
```

Теперь создадим новый объект класса пользователь:

```py
>>> u = User()
```

Атрибуты хранятся в специальном словаре \(подробнее про модель данных в Python можно почитать [тут](https://docs.python.org/3.6/reference/datamodel.html)\):

```py
>>> u.__dict__
{}
```

Так как мы не создали еще ни одного атрибута, то и словарь будет пустым. Давайте добавим несколько атрибутов  \(Python позволяет динамически привязывать новые атрибуты к объекту, в конце концов это просто словарь\):

```py
>>> u.username = 'bob'
>>> u.password = 'bob@example.com'
>>> u.email = 'foobar'

>>> u.__dict__
{'username': 'bob', 'password': 'bob@example.com', 'email': 'foobar'}

# Следующие два выражения в нашем примере эквиваленты
>>> u.username
'bob'
>>> u.__dict__['username']
'bob'
```

Что будет, если мы обратимся к атрибуту, которого не существует?

```py
>>> u.created_at
Traceback (most recent call last):
  File "<input>", line 1, in <module>
    u.created_at
AttributeError: 'User' object has no attribute 'created_at'
```

Работать с атрибутами можно с помощью следующих функций:

* `hasattr(obj, attr_name)` - проверить наличие атрибута `attr_name` в объекте `obj`. Если атрибут присутствует, то функция возвращает `True`, иначе `False`.
* `getattr(obj, attr_name[, default_value])` - получить значение атрибута. Можно указать значение по умолчанию `default_value`, которое будет возвращено, если атрибута не существует.
* `setattr(obj, attr_name, value)` - изменить значение атрибута `attr_name` на `value`. Если атрибут не существовал, то он будет создан.

```py
>>> hasattr(u, 'created_at')
False
>>> hasattr(u, 'username')
True

>>> getattr(u, 'created_at')
Traceback (most recent call last):
  File "<input>", line 1, in <module>
    getattr(u, 'created_at')
AttributeError: 'User' object has no attribute 'created_at'

import datetime
>>> getattr(u, 'created_at', datetime.datetime.now())
datetime.datetime(2017, 4, 11, 16, 45, 36, 757869)

>>> setattr(u, 'created_at', datetime.datetime.now())
datetime.datetime(2017, 4, 11, 16, 45, 36, 757869)
```

Функция `setattr` может оказаться полезной, когда нам необходимо добавить в объект множество атрибутов, хранящихся в каком-нибудь контейнере:

```py
u = User()
attrs = {'username': 'bob', 'email': 'bob@example.com', 'password': 'foobar'}
for k, v in attrs.items():
    setattr(u, k, v)
```

Добавим теперь функцию получения имени пользователя в ранее созданный объект:

```py
def get_username(user):
    return user.username

>>> u.get_username = get_username
>>> u.__dict__
{'username': 'bob', 'password': 'bob@example.com', 'email': 'foobar', 'get_username': <function get_username at 0x1038256a8>}
>>> u.get_username(u)
'bob'
```

Обратите внимание, что мы вызываем функцию `get_username` у объекта `u` и в качестве аргумента передаем сам объект `u`. Выглядит странно и некрасиво.

> Черная магия питона: Ради справедливости нужно сказать, что мы можем динамически привязать метод к объекту, так, чтобы не пришлось передавать объект в качестве аргумента. Пример приведен ниже.


```py
>>> from types import MethodType
>>> u.get_username = MethodType(get_username, u)
>>> u.get_username()
'bob'

>>> u.__dict__
{'username': 'bob', 'password': 'bob@example.com', 'email': 'foobar', 'get_username': <bound method get_username of <__console__.U
ser object at 0x103839d30>>}
```

Так как каждый объект класса _Пользователь_ должен содержать одинаковый набор атрибутов, но с разными значениями, то было бы логичным вынести процесс создания атрибутов в отдельный метод. В Python таким методом является `__init__`:

```py
class User:
    def __init__(self, username, email, password):
        self.username = username
        self.email = email
        self.password = password

    def get_username(self):
        return self.username

>>> u = User('bob', 'bob@example.com', 'foobar')
>>> u.email
'bob@example.com'
>>> u.get_username()
'bob'
```

Возникает вопрос "_Откуда взялся `self` в качестве первого аргумента у метода `__init__()`?_". Упрощенно процесс создания и инициализации нового объекта можно описать следующими шагами:

1. `u = User('bob', 'bob@example.com', 'foobar')`
2. Вызывается конструктор объекта [`__new__()`](https://docs.python.org/3.6/reference/datamodel.html#object.__new__), который возвращает "пустой" объект.
3. Созданный объект передается в инициализатор `__init__()` в качестве первого аргумента с именем `self` (такое имя не является обязательным, но используется по соглашению), за ним передаются все остальные аргументы указанные при вызове класса (`'bob', 'bob@example.com', 'foobar'`).
4. У объекта создаются все требуемые атрибуты, например `self.username = username`.
5. Инициализированный объект возвращается на место вызова класса, в примере переменная `u` связывается с созданным объектом.

> **Замечание**: Как было сказано это упрощенная схема создания и инициализации нового объекта. Чтобы понимать этот процесс более полно, то необходимо ввести понятие метаклассов, о которых вы можете прочитать [тут](https://blog.ionelmc.ro/2015/02/09/understanding-python-metaclasses/).

Вы заметили, что в метод `get_username()` также передается `self`? А также то, что при вызове этого метода мы не передаем никаких аргументов? Давайте рассмотрим два следующих выражения:
```py
>>> u.get_username()
'bob'
>>> User.get_username(u)
'bob'
```

В Python классы также являются объектами (_в Python все является объектом_) и методы, в отличие от атрибутов, принадлежат классу, а не объекту. Поэтому метод `get_username()` вызывается не у объекта, а у класса, а объект передается в качестве аргумента (отсюда следует, что объект должен передаваться в качестве первого аргумента во все методы класса и по соглашению его называют `self`). Таким образом, выражение `u.get_username()` является просто синтаксическим сахаром (упрощенной формой записи) по отношению к `User.get_username(u)`.

> **Замечание**:  Конечно все несколько сложнее, рассмотрим следующий пример:
```python
>>> User.get_username
< function User.get_username at 0x103a06268 >
>>> u.get_username
< bound method User.get_username of < __console__.User object at 0x1039a8eb8>>
```
В первом случае мы имеем функцию, а во втором - связный метод, другими словами есть разница в поведении в зависимости от того вызываем мы `get_username` у класса или у объекта. Такое поведение реализовано с помощью дескрипторов, о которых мы будем говорить ниже, а пока можно почитать вот [эту интересную статью](http://emmanuel-klinger.net/pythons-attribute-descriptors.html).

### Пример: создание простой ORM

Что такое ORM? Вот пояснение с сайта [Full Stack Python](https://www.fullstackpython.com/object-relational-mappers-orms.html):

> An object-relational mapper (ORM) is a code library that automates the transfer of data stored in relational databases tables into objects that are more commonly used in application code.

В этом примере (полностью основанном на [этом коде](https://codescience.wordpress.com/2011/02/06/python-mini-orm/)) мы рассмотрим пример создания примитивной ORM для SQLite базы данных, которая имеет [встроенную поддержку](https://docs.python.org/3.6/library/sqlite3.html) в Python.

Создадим БД с таблицей _Пользователи_ и добавим туда несколько записей:

```py
import sqlite3

# Создание нового соединения с БД
conn = sqlite3.connect('users_db.sqlite3')

# Курсор это объект, который позволяет выполнять запросы к БД
cursor = conn.cursor()

# Создание таблицы пользователей
cursor.execute('CREATE TABLE users (id, username, email, password)')

# Добавление новых записей
users = [
   (1, 'john', 'john@thebeatles.com', 'foobar'),
   (2, 'paul', 'paul@thebeatles.com', 'barfoo'),
   (3, 'ringo', 'ringo@thebeatles.com', 'foobaz'),
   (4, 'george', 'george@thebeatles.com', 'bazfoo')
]
cursor.executemany('INSERT INTO users VALUES (?,?,?,?)', users)
conn.commit()

# Вывод всех записей
for row in cursor.execute('SELECT * FROM users'):
   print(row)
```

В результате вы должны увидеть следующие записи:
```py
(1, 'john', 'john@thebeatles.com', 'foobar')
(2, 'paul', 'paul@thebeatles.com', 'barfoo')
(3, 'ringo', 'ringo@thebeatles.com', 'foobaz')
(4, 'george', 'george@thebeatles.com', 'bazfoo')
```

Теперь перейдем к ORM:
```py
import sqlite3


class DataBase:
    def __init__(self, db='db'):
        self.conn = sqlite3.connect(f"{db}.sqlite3")
        self.cursor = self.conn.cursor()

    def get_columns(self, tbl_name):
        self.sql_rows = f"SELECT * FROM {tbl_name}"
        columns = f"PRAGMA table_info({tbl_name})"
        self.cursor.execute(columns)
        return [row[1] for row in self.cursor.fetchall()]

    def Table(self, tbl_name):
        columns = self.get_columns(tbl_name)
        return Query(self.cursor, self.sql_rows, columns, tbl_name)


class Query:
    def __init__(self, cursor, rows, columns, tbl_name):
        self.cursor = cursor
        self.sql_rows = rows
        self.columns = columns
        self.tbl_name = tbl_name

    def filter(self, criteria):
        key_word = "AND" if "WHERE" in self.sql_rows else "WHERE"
        sql = f"{self.sql_rows} {key_word} {criteria}"
        return Query(self.cursor, sql, self.columns, self.tbl_name)

    def order_by(self, criteria):
        return Query(self.cursor, f"{self.sql_rows} ORDER BY {criteria}", self.columns, self.tbl_name)

    def group_by(self, criteria):
        return Query(self.cursor, f"{self.sql_rows} GROUP BY {criteria}", self.columns, self.tbl_name)

    @property
    def rows(self):
        print(self.sql_rows)
        self.cursor.execute(self.sql_rows)
        return [Row(zip(self.columns, fields), self.tbl_name) for fields in self.cursor.fetchall()]


class Row:
    def __init__(self, fields, table_name):
        self.__class__.__name__ = table_name + "_Row"

        for name, value in fields:
            setattr(self, name, value)

    def __repr__(self):
        attrs =  ', '.join([f"{attr}={value}" for attr, value in self.__dict__.items()])
        return f"{self.__class__.__name__}({attrs})"
```
Класс `DataBase` отвечает за создание соединения, класс `Query` за формирование запроса к БД, класс `Row` представляет одну запись в таблице.

> **Замечание**: Все строки в формате [f-strings](https://cito.github.io/blog/f-strings/), который был введен в Python 3.6.
>
> Метод `__repr__` переопределен, чтобы выводить чуть больше полезной информации об объекте, чем просто его адрес в памяти. Узнать больше про магические методы в питоне можно прочитав статью на [Хабре](https://habrahabr.ru/post/186608/).

Ниже приведен пример использования:

```py
>>> db = DataBase('users_db')

>>> db.get_columns('users')
['id', 'username', 'email', 'password']

>>> db.Table('users').rows:
SELECT * FROM users
[users_Row(id=1, username=john, email=john@thebeatles.com, password=foobar),
 users_Row(id=2, username=paul, email=paul@thebeatles.com, password=barfoo),
 users_Row(id=3, username=ringo, email=ringo@thebeatles.com, password=foobaz),
 users_Row(id=4, username=george, email=george@thebeatles.com, password=bazfoo)]

>>> db.Table('users').filter('id > 2').rows
SELECT * FROM users WHERE id > 2
[users_Row(id=3, username=ringo, email=ringo@thebeatles.com, password=foobaz),
 users_Row(id=4, username=george, email=george@thebeatles.com, password=bazfoo)]

>>> db.Table('users').order_by('username DESC').rows
SELECT * FROM users ORDER BY username DESC
[users_Row(id=3, username=ringo, email=ringo@thebeatles.com, password=foobaz),
 users_Row(id=2, username=paul, email=paul@thebeatles.com, password=barfoo),
 users_Row(id=1, username=john, email=john@thebeatles.com, password=foobar),
 users_Row(id=4, username=george, email=george@thebeatles.com, password=bazfoo)]

>>> user = db.Table('users').rows[0]
SELECT * FROM users
>>> user.id
1
>>> user.username
'john'
```

**Задания**:
- вы должны были заметить, что мы получаем объекты класса `users_Row`, а не класса `User`. Попробуйте внести изменения, чтобы мы получали объекты класса `User`:

```python
>>> user = db.Table('users').rows[0]
>>> type(user)
<class '__main__.User'>
>>> user.get_username()
'john'
```
- добавьте метод `limit(N)` в класс `DataBase`, который позволяет получить не больше N записей.
- добавьте метод `insert(obj)`, который создает в БД новую запись об объекте `obj`.

### "Приватные" поля класса

Допустим у нас имеется следующее определение класса, в котором есть методы для изменения и проверки пароля, а также адреса электронной почты:

```py
import hashlib
import random
import string
import re


class User:

    def __init__(self, username, email, password):
        self.username = username

        self.set_email(email)
        self.set_password(password)

    def set_email(self, email):
        match = re.match('^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$', email)
        if not match:
            raise ValueError("Invalid email")
        self.email = email

    # http://pythoncentral.io/hashing-strings-with-python/
    # https://docs.python.org/3.5/library/hashlib.html
    def make_salt(self):
        salt = ""
        for i in range(5):
            salt = salt + random.choice(string.ascii_letters)
        return salt

    def set_password(self, pw, salt=None):
        if salt == None:
            salt = self.make_salt()
        self.password = hashlib.sha256(pw.encode() + salt.encode()).hexdigest() + "," + salt

    def check_password(self, user_password):
        password, salt = self.password.split(',')
        return password == hashlib.sha256(user_password.encode() + salt.encode()).hexdigest()
```

Давайте посмотрим на работу с этими методами:

```py
>>> u = User('bob', 'bob@example.com', 'foobar')
>>> u.username
'bob'
>>> u.email
'bob@example.com'
>>> u.password
'fd6c85ddaccb0d13e8b4d45b6e3bcbcc18d3b737a10aef21d297c861d770da6d,PDrGK'

>>> u.set_email('bob-new-email')
Traceback (most recent call last):
  File "<input>", line 1, in <module>
    u.set_email('bob-new-eamil')
  File "<input>", line 12, in set_email
    raise ValueError("Invalid email")
ValueError: Invalid email
>>> u.set_email('bob-new-eamil@example.com')
>>> u.email
'bob-new-eamil@example.com'

>>> u.check_password('barfoo')
False
>>> u.check_password('foobar')
True
```

Допустим, что мы хотим изменить пароль (или адрес электронной почты) и делаем это напрямую обращаясь к атрибуту:
```py
>>> u.password = 'barfoo'
>>> u.check_password('barfoo')
False
```

Почему пароль не прошел проверку? Мы изменили значение атрибута напрямую, не используя функцию `set_password()`, таким образом, мы сохранили пароль в открытом виде. В свою очередь функция `check_password()` хеширует переданный ей пароль в качестве аргумента и затем сравнивает его с паролем, который хранился в атрибуте `password`.

Очевидно, что нужно менять значение пароля или адреса электронной почты с помощью методов `set_password()` и `set_email()`, чтобы избежать подобного рода ошибок. А прямое обращение к полям `password` и `email` нужно ограничить.

В языке Python сложно что-то запретить, в частности обращение к полям класса, но есть соглашения. Например, если имя атрибута начинается с одного нижнего подчеркивания, то он считается  (**считается != является**) приватным (private), другими словами, указывая нижнее подчеркивание перед именем атрибута мы "говорим" пользователям нашего класса "_Не нужно обращаться к этому полю напрямую, иначе можно нарушить логику работы_". Таким образом, в примере приведенном выше, имена всех атрибутов (пароль, адрес электронной почты и имя пользователя) следовало бы начинать с нижнего подчеркивания, а для взаимодействия с ними использовать соответствующие методы, которые обычно называют "_сеттерами_" и "_геттерами_" (от set/get, например, `set_username` и `get_username`).

> **Замечание**: Больше про нижние подчеркивания можно узнать [тут](https://shahriar.svbtle.com/underscores-in-python).

### Магические методы


### Пример: Классы «Column» и «DataTable»

```python
from statistics import mean, median, stdev


class Column:

    def __init__(self, values, dtype=None):
        self.shape = (len(values),)
        self.dtype = dtype
        if not dtype:
            types_set = set(map(lambda v: type(v), values)) - {type(None)}
            if len(types_set) == 1:
                [self.dtype] = types_set
            elif {int, float} == types_set:
                self.dtype = float
            elif bool in types_set:
                self.dtype = bool
            else:
                self.dtype = str
        self.values = [self.dtype(v) if v is not None else None for v in values]

    def _filter_na(self):
        return [v for v in self.values if v is not None]

    def dropna(self):
        return Column(self._filter_na(), dtype=self.dtype)

    def astype(self, dtype):
        return Column(self.values, dtype=dtype)

    def mean(self):
        return mean(self._filter_na())

    def median(self):
        return median(self._filter_na())

    def std(self):
        return stdev(self._filter_na())

    def min(self):
        return min(self._filter_na())

    def max(self):
        return max(self._filter_na())

    def head(self, n=5):
        return self[:n]

    def tail(self, n=5):
        return self[-n:]

    def __len__(self):
        return len(self.values)

    def __str__(self):
        return str(self.values)

    def __repr__(self):
        return repr(self.values)

    def __getitem__(self, key):
        if isinstance(key, int):
            return self.values[key]
        if isinstance(key, slice):
            return Column(self.values[key], dtype=self.dtype)
        if isinstance(key, Column) and all(isinstance(v, bool) for v in key):
            return Column([v for v, keep in zip(self.values, key) if keep], dtype=self.dtype)
        raise Exception()

    def __eq__(self, other):
        if isinstance(other, Column):
            return Column([v1 == v2 for v1, v2 in zip(self, other)], dtype=bool)
        return Column([v == other for v in self], dtype=bool)

    def __gt__(self, other):
        if isinstance(other, Column):
            return Column([v1 > v2 for v1, v2 in zip(self, other)], dtype=bool)
        return Column([v > other for v in self], dtype=bool)

    def __ge__(self, other):
        if isinstance(other, Column):
            return Column([v1 >= v2 for v1, v2 in zip(self, other)], dtype=bool)
        return Column([v >= other for v in self], dtype=bool)

    def __lt__(self, other):
        if isinstance(other, Column):
            return Column([v1 < v2 for v1, v2 in zip(self, other)], dtype=bool)
        return Column([v < other for v in self], dtype=bool)

    def __le__(self, other):
        if isinstance(other, Column):
            return Column([v1 <= v2 for v1, v2 in zip(self, other)], dtype=bool)
        return Column([v <= other for v in self], dtype=bool)

    def __and__(self, other):
        return Column([v1 and v2 for v1, v2 in zip(self, other)], dtype=bool)

    def __or__(self, other):
        return Column([v1 or v2 for v1, v2 in zip(self, other)], dtype=bool)
```

### Свойства \(property\)

Давайте рассмотрим следующий пример: пусть у нас есть класс "Профиль пользователя" и поле дата рождения,

```py
class UserProfile:

    def __init__(self, user, first_name='', sur_name='', bdate=None):
        assert isinstance(user, User), '`user` field must be a User class instance'
        self._user = user
        self.first_name = first_name
        self.sur_name = sur_name
        self.bdate = bdate

        self._age = None
        self._age_last_recalculated = None
        self._recalculate_age()

    def _recalculate_age(self):
        today = datetime.date.today()
        age = today.year - self.bdate.year

        if today < datetime.date(today.year, self.bdate.month, self.bdate.day):
            age -= 1

        self._age = age
        self._age_last_recalculated = today

    def age(self):
        if (datetime.date.today() > self._age_last_recalculated):
            self._recalculate_age()

        return self._age


class User:

    def __init__(self, username, email, password):
        ...
        self.profile = UserProfile(self)
        ...    
```

```py
class UserProfile:
    ...
    @property
    def age(self):
        if (datetime.date.today() > self._age_last_recalculated):
            self._recalculate_age()

        return self._age
```

```py
class UserProfile:
    ...
    @property
    def fullname(self):
        return '{} {}'.format(self.first_name, self.sur_name).title()

    @fullname.setter
    def fullname(self, value):
        name, surname = value.split(" ", maxsplit=1)
        self.first_name = name
        self.sur_name = surname

    @fullname.deleter
    def fullname(self):
        self.first_name = ''
        self.sur_name = ''
```

### Дескрипторы

### Методы класса \(@classmethod и @staticmethod\)

### Наследование

```py
class TimestampedModel:

    def __init__(self, created_at=None, updated_at=None):
        self.created_at = created_at or datetime.datetime.now()
        self.updated_at = updated_at or created_at

    def update(self):
        self.updated_at = datetime.datetime.now()
```

```py
class User(TimestampedModel):

    def __init__(self, username, email, password):
        self.username = username
        self.email = email
        self.password = password
```

```py
class User(TimestampedModel):

    def __init__(self, username, email, password):
        self.username = username
        self.email = email
        self.password = password
        super().__init__()

    @property
    def username(self):
        return self._username

    @username.setter
    def username(self, new_username):
        self._username = new_username
        self.update()
```

```py
import json
import attr
import enum
import datetime


class JSONSerializerMixin:

    @staticmethod
    def to_serializable(value):
        if isinstance(value, datetime.datetime):
            return value.isoformat() + "Z"
        elif isinstance(value, enum.Enum):
            return value.value
        elif attr.has(value.__class__):
            return attr.asdict(value)
        elif isinstance(value, Exception):
            return {
                "error": value.__class__.__name__,
                "args": value.args,
            }
        return str(value)

    def toJSON(self):
        return json.dumps(self.__dict__, default=JSONSerializerMixin.to_serializable)

    @classmethod
    def fromJSON(cls, data):
        def datetime_parser(json_dict):
            for k,v in json_dict.items():
                try:
                    json_dict[k] = datetime.datetime.strptime(v, "%Y-%m-%d").date()
                except:
                    pass
            return json_dict
        return cls(**json.loads(data, object_hook=datetime_parser))
```

```py
class User(TimestampedModel, JSONSerializerMixin):
    ...
```

### Множественное наследование и полиморфизм

### Метаклассы

Таким же образом, как классы контролируют создание экземпляров и позволяют задавать поведение методов, метаклассы в Python могут делать все это для классов. Понять, что такое метаклассы, можно определив их как _классы классов_.

Самый часто используемый метакласс - `type` т.к. это метакласс для всех классов по умолчанию, все остальные метаклассы должны наследоваться от него.

### *Тип type*

В Python всё является объектом и должно иметь тип. Вкратце, тип - это сущность, которая знает как создать экземпляр. Например, тип числа `1` - `Int`, а тип `Int` - `type`

```py
>>> type(1)
<class 'int'>
>>> type(int)
<class 'type'>
```

Существует модуль <a href="https://docs.python.org/3/library/types.html" target="_blank">`types`</a>, который предоставляет стандартный набор функций для работы с типами и определения типов, которые интерпретатор использует по умолчанию. Это может оказаться кстати, например, если вам нужно проверить является ли данный объект функцией или модулем.

```py
>>> import types
>>> def func():
...     pass

>>> isinstance(func, types.FunctionType)
True
>>> isinstance(func, types.ModuleType)
False
```

Теперь, когда `type` тоже является объектом, какой тогда его тип? Получается, что типом типа `type` является... `type`:

```py
>>> type(type)
<class 'type'>
```

Все создаваемые пользователем новые классы (`new-style classes`) также имеют тип `type`:

```py
>>> class A(object):
...     pass

>>> type(A)
<class 'type'>
```

Это происходит с 3 версии Python, однако в случае использования Python 2 вам необходимо помнить, что все классы следует наследовать от `object`. Иначе, они будут иметь тип `classobj`:

```py
# Python 2.x
>>> class B:
...     pass

>>> type(B)
<type 'classobj'>
```

В конце концов, если вызвать `type` с тремя аргументами, он будет вести себя как конструктор - так вы сможете создавать типы "на лету". Этими аргументами являются имя нового типа, кортеж родительских классов и словарь класса (который содержит все то, что вы обычно размещаете в теле класса)

```py
class A(object):
    pass

def f(self, x):
    return x + 1

Type = type('Type', (A,), {'x': 42, 'f': f})
instance = Type()

>>> issubclass(Type, A)
True
>>> isinstance(instance, Type)
True
>>> Type.x
42
>>> instance.f(1)
2
```

Мы вернёмся к этому позже, когда будем разбирать конструктор метаклассов.

### *Связываем метаклассы*

Так как все метаклассы наследуются от `type`, самая простая реализация метакласса выглядит следующим образом:

```
class M(type):
  pass
```

Теперь любой класс, чьим метаклассом является `M`, будет иметь тип `M` (но также являться экземпляром типа `type`, потому что `M` наследуется от `type`)

Как мы можем связать метакласс и класс? Увы, это ещё одна вещь, реализованная по-разному в Python 2 и Python 3.

В Python 2, метакласс устанавливается в специальное поле класса - `__metaclass__`

```py
# Python 2.x only
class A(object):
    __metaclass__ = M
```

В Python 3 метакласс передаётся в качестве аргумента:

```py
# Python 3.x only
class A(object, metaclass=M):
  pass
```

Одним из способов унифицировать этот процесс является использование библиотеки <a href="https://pypi.python.org/pypi/six" target="_blank">`six`</a>, предоставляющей единый способ связывания метаклассов с основным классом:

```py
# Python 2 and 3

import six

# metaclass
class M(type):
    pass

# base class
class A(object):
    pass

class B(six.with_metaclass(M, A)):
    pass

@six.add_metaclass(M)
class C(A):
    pass

assert issubclass(B, A)
assert type(B) is M

assert issubclass(C, A)
assert type(C) is M
```

### *Перехватываем конструкторы типов*

Как мы рассмотрели выше, сигнатура конструктора у `type` следующая:
```
type(name, bases, classdict)
```

Тогда определение классов с помощью ключевого слова `class` можно рассматривать как "синтаксический сахар", позволяющий не вызывать конструктор `type` напрямую.

Определим 2 класса:
```py

class A(object):
    x = 1

class B(A):
    y = 2

    @classmethod
    def f(cls, v):
        return v + 1

    def g(self, v):
        return v + 2

```

Мы можем переписать код выше с использованием `type` напрямую:

```py
clsdict_a = {
    'x': 1
}

A = type('A', (object,), clsdict_a)

def f(cls, v):
    return v + 1

def g(self, v):
    return v + 2

clsdict_b = {
    'y': 2,
    'f': classmethod(f),
    'g': g
}

B = type('B', (A,), clsdict_b)
```

Всё самое интересное происходит внутри конструктора `type`, а все определяемые пользователем метаклассы могут варьировать список аргументов, которые он получает. Другими словами, вы можете перехватить создание класса сразу после того, как интерпретатор считал определение класса, и ровно до того момента, когда произойдёт обращение к `type`. Для этого необходимо переопределить метод `__new__`.

Давайте посмотрим на пример, в котором мы хотим, чтобы во всех наследниках конкретного класса автоматически увеличивалось значение `id` в случае, если `track` установлен в `True` в теле класса; также мы хотим хранить все отслеживаемые классы в общем поле `classes`:

```py
import six

class Meta(type):
    classes = []

    def __new__(meta, name, bases, clsdict):
        clsdict['id'] = None
        track = clsdict.pop('track', False)
        clsdict['id'] = len(meta.classes) if track else None
        cls = super(Meta, meta).__new__(meta, name, bases, clsdict)
        if track:
            meta.classes.append(cls)
        return cls

@six.add_metaclass(Meta)
class Trackable(object):
    pass

assert Trackable.classes == []
assert Meta.classes == []
assert Trackable.id is None

class A(Trackable):
    track = True

assert A.id == 0
assert A.classes == Trackable.classes == [A]
assert not hasattr(A, 'track')

class B(A):
    pass

assert B.classes == A.classes == [A]
assert B.id is None

class C(Trackable):
    track = True

assert C.classes == B.classes == [A, C]
assert C.id == 1
assert Trackable.classes[C.id] is C
```

Сперва мы наследуем метакласс `Meta` от `type`, в котором переопределяем метод `__new__` и создаём переменную `classes` уровня класса, которая отражает текущее состояние.

Сигнатура метода `__new__` совпадает с сигнатурой конструктора `type` - она тоже получает имя класса, кортеж родительских типов и словарь свойств класса; она также должна вернуть полностью сформированный тип. В этом методе мы проверяем наличие поля `track` в словаре класса и его значение. Если поле есть и значение установлено в True, то мы присваиваем значение `id` классового уровня соответственно, иначе - `None`.

В завершении, мы вызываем конструктор основного метакласса для формирования типа, при желании сохраняем его в списке отслеживаемых классов и возвращаем сформированный тип. Стоит упомянуть, что мы могли использовать метод `type.__new__` вместо `super(Meta, meta).__new__`, но в целом это хорошая практика избегать жёстко закодированные основные типы, которые иногда приводят к неожиданному поведению при наследовании.

Обратите внимание, что все переменные классового уровня (такие как `classes`) в этом примере могут также быть доступны наследникам. Похожим образом экземпляры методов метаклассов доступны как методы класса одновременно для классов и их экземпляров.

### *Метакласс как реестр*

Типичный случай применения метаклассов - отслеживание созданных классов для последующего доступа к ним во время выполнения по имени или идентификатору.

```py
import six

class RegistryMeta(type):
    def __getitem__(meta, key):
        return meta._registry[key]

@six.add_metaclass(RegistryMeta)
class Registry(type):
    _registry = {}

    def __new__(meta, name, bases, clsdict):
        cls = super(Registry, meta).__new__(meta, name, bases, clsdict)
        if not clsdict.pop('__base__', False):
            meta._registry[name] = cls
            if 'alias' in clsdict:
                meta._registry[cls.alias] = cls
        return cls

class Base(six.with_metaclass(Registry)):
    __base__ = True

class A(Base):
    pass

class B(Base):
    alias = 'foo'

assert Registry['A'] is A  # lookup by class name
assert Registry['B'] is B
assert Registry['foo'] is B  # or by alias

# Base is not in registry
try:
    Registry['Base']
except Exception as e:
    assert isinstance(e, KeyError)
```

В примере выше, все наследники `Base` будут отслеживаться метаклассом `Registry`, и к ним можно будет обратиться позже по имени класса или значению поля `alias` при его наличии.

Перед тем, как зарегистрировать класс, мы проверяем наличие поля `__base__`, чтобы учитывать только прямых потомков `Base`.

Для того, чтобы сделать класс `Registry` индексируемым, мы должны связать метакласс `RegistryMeta` с ним, ведь в нем мы реализовали "магический" метод `__getitem__`. Насколько страшно звучит фраза "метакласс метакласса", настолько же мы в действительности следуем такой логике, реализуя метод для экземпляров в теле класса. Если вам нужен экземпляр для чего-либо, вы реализуете методы в его типе, дабы последний знал, как связать реализованную функциональность с объектом во время его создания.

Подытожим иерархию метакласса следующим примером:
```
a = A()
assert type(a) is A
assert type(A) is Registry
assert type(Registry) is RegistryMeta
assert type(RegistryMeta) is type
```

### *Singleton-паттерн*

Использование глобальных объектов - априори плохая затея, но если вы твердо решили идти этим путем, вам следует убедиться, что это Singleton, в котором существует один единственный экземпляр какого-либо класса в любой момент выполнения, от которого невозможно наследоваться.

Как мы уже убедились, если метакласс связан с основным классом, всякий раз, когда от основного класса происходит наследование, вызывается метод `__new__`. Это позволяет с легкостью обрабатывать неперехватываемую часть. Если по какой-либо причине вы хотите предотвратить возможность наследования от метакласса, вам следует реализовать метакласс для метаклассов.

Когда речь идёт о контролировании создаваемых экземпляров метакласса, переопределение метода `__new__` больше недостаточно: вместо него мы должны переопределить `__call__`. Легко запомнить: `__new__` срабатывает при создании нового класса, `__call__` - при создании нового экземпляра класса. Это работает точно так же и в случае реализации вышеуказанных методов в обычных классах. Таким образом экземпляры этих классов можно будет вызывать.

Чтобы разобраться, как эти методы работают в связке, взглянем на следующий фрагмент:

```py
from __future__ import print_function
import six

class M(type):
    def __new__(meta, *a, **kw):
        print('metaclass::new')
        return super(M, meta).__new__(meta, *a, **kw)

    def __call__(cls, *a, **kw):
        print('metaclass::call', a, kw)
        return super(M, cls).__call__(*a, **kw)

print('---')

class C(six.with_metaclass(M)):
    def __new__(cls, *a, **kw):
        print('class::new', a, kw)
        return super(C, cls).__new__(cls, *a, **kw)

    def __init__(self, *a, **kw):
        print('class::init', a, kw)

    def __call__(self, *a, **kw):
        print('class::call', a, kw)


print('---')
instance = C('foo', x=1)
print('---')
instance('bar', y=2)
```

Вывод будет следующим:

```
metaclass::new
---
metaclass::call ('foo',) {'x': 1}
class::new ('foo',) {'x': 1}
class::init ('foo',) {'x': 1}
---
class::call ('bar',) {'y': 2}
```

Возвращаясь к singleton-классу, мы должны переопределить `__call__` в метаклассе для перехвата конструктора экземпляров и возвращения существующих экземпляров, которые могли быть ранее сохранены прямо в классе. Если экземпляр не существует, мы можем создать его, вызвав `super`, который в свою очередь вызовет конструктор класса, если он определён.

```py
import six

class Singleton(type):
    def __new__(meta, name, bases, clsdict):
        if any(isinstance(cls, meta) for cls in bases):
            raise TypeError('Cannot inherit from singleton class')
        clsdict['_instance'] = None
        return super(Singleton, meta).__new__(meta, name, bases, clsdict)

    def __call__(cls, *args, **kwargs):
        if not isinstance(cls._instance, cls):
            cls._instance = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instance

@six.add_metaclass(Singleton)
class A(object):
    pass

a = A()
b = A()
assert a is b  # all new instances point to the same object

try:
    class B(A):
        pass
except Exception as e:
    assert isinstance(e, TypeError)  # cannot inherit from singleton
```

Реализация весьма проста и прозрачна, однако здесь ещё есть место для улучшений. К примеру, `__call__` обрабатывает полученные аргументы только в первый раз; во всех остальных вызовах он лишь безоговорочно возвращает сохранённое значение.

### *Генерируем дескрипторы*

Ещё один частый случай использования метаклассов - автоматизация создания дескрипторов. В Python дескриптором является любой объект, который реализует хотя бы один из следующих методов: `__get__`, `__set__` или `__delete__`

Дескрипторы контролируют доступ к свойствам, а также задают поведение для получения, установки или удаления свойства из словаря объекта. Рассмотрим простую реализацию:

```py
class Descriptor(object):
    def __init__(self, name):
        self.name = name

    def __get__(self, instance, cls=None):
        return instance.__dict__[self.name]

    def __set__(self, instance, value):
        instance.__dict__[self.name] = value

    def __delete__(self, instance):
        del instance.__dict__[self.name]


class A(object):
    x = Descriptor('x')

a = A()
assert not hasattr(a, 'x')
a.x = 1
assert a.x == 1
del a.x
assert not hasattr(a, 'x')
```

Это может выглядеть как излишество, так как мы бы могли напрямую работать с свойствами экземпляров. Тем не менее, дескрипторы полезны в случаях, когда мы хотим добавить дополнительную логику в один из методов get, set или delete. Например, мы можем полностью переписать встроенные свойства/методы с использованием дескрипторов.

Зачем нам нужно было передавать строку `x` в `Descriptor` явно? Ответ крайне прост - с одной стороны, дескриптор должен знать имя атрибута для поиска в словаре объекта, с другой стороны - на момент инициализации он не может ссылаться на словарь объекта, потому что тот пока что не существует. Так, например, в момент присваивания `a = A()` невозможно сообщить классу `A` о том, куда его экземпляр будет присвоен.

Здесь в дело вступают метаклассы. Как раз до того, как будет создан тип, у нас есть полный словарь класса для наших нужд, и мы можем заменять конкретные поля, используя дескрипторы.

В следующем примере мы создаём основной класс, наследники которого могут использовать специальный синтаксис для генерации свойств типа с значениями по умолчанию.

```py
class A(Typed):
    x = int
    y = str, 'foo'
```

Мы хотим, чтобы `x` был числовым свойством с стандартным значением `None`, а `y` - строкой со стандартным значением `foo`. Когда значения по умолчанию присвоены, оба свойства попытаются привести установленные значения к своему типу.

Возможная реализация дескриптора:

```py
import six

class Descriptor(object):
    def __init__(self, name, cls, default=None):
        self.name = name
        self.cls = cls
        self.default = default

    def __set__(self, instance, value):
        # convert the value to `cls` and write to instance dict
        instance.__dict__[self.name] = self.cls(value)

    def __get__(self, instance, cls):
        # retrieve the value from instance dict
        return instance.__dict__.get(self.name, self.default)

class Meta(type):
    _types = [int, str]

    def __new__(meta, name, bases, clsdict):
        for k, v in clsdict.copy().items():
            if v in meta._types:
                # a type with no default
                clsdict[k] = Descriptor(k, v)
            elif isinstance(v, tuple):
                if len(v) == 2 and v[0] in meta._types:
                    # a type and a default value
                    clsdict[k] = Descriptor(k, v[0], v[1])
        return super(Meta, meta).__new__(meta, name, bases, clsdict)

class Typed(six.with_metaclass(Meta)):
    pass

class A(Typed):
    x = int
    y = str, 'foo'

a = A()
assert a.x is None
a.x = '42'
assert a.x == 42
assert a.y == 'foo'
a.y = 42
assert a.y == '42'
```

Заметьте, что мы до сих пор должны передавать имена полей в `Descriptor`, но на этот раз это было сделано метаклассом автоматически, а имена свойств попросту соответствовали ключам в словаре. Это основное преимущество использования метаклассов - реализовывать всю тяжёлую работу в метаклассе, чтобы пользовательский код выглядел проще.

> Источник: [http://ivansmirnov.io/python-metaclasses/](http://ivansmirnov.io/python-metaclasses/), статья может быть доступна по ссылке [http://archive.li/35l34](http://archive.li/35l34).

### Абстрактные классы

Продолжим рассматривать пример с классом _Пользователь_. Мы можем разделить пользователей на два типа: **анонимные пользователи**, то есть те пользователи, которые не зарегистрированы или не вошли в систему под своим логином и паролем, и **авторизованные пользователи**.

```py
class AbstractUser:

    def set_password(self, raw_password):
        raise NotImplementedError()

    def check_password(self, raw_password):
        raise NotImplementedError()

    def is_anonymous(self):
        raise NotImplementedError()
```

> Замечание: Если проводить параллель с другими языками программирования, например, Java, то такой класс более справедливо было бы назвать [интерфейсом](http://stackoverflow.com/questions/761194/interface-vs-abstract-class-general-oo).

```py
class AnonymousUser(AbstractUser):

    def is_anonymous(self):
        return True

class User(AbstractUser):
    def set_password(self, raw_password):
        ...

    def check_password(self, raw_password):
        ...

    def is_anonymous(self):
        return False
```

```py
from abc import ABCMeta, abstractmethod


class AbstractUser(metaclass=ABCMeta):
    def set_password(self, raw_password):
        raise NotImplementedError()

    def check_password(self, raw_password):
        raise NotImplementedError()

    @abstractmethod
    def is_anonymous(self):
        pass
```
