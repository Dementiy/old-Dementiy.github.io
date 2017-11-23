---
layout: post
title: Настройка рабочего окружения
categories: python golang практики
---

В этом посте я постараюсь описать все, что понадобится для выполнения практик. Скорее всего этот пост будет время от времени обновляться, так что следите за изменениями и задавайте вопросы, если что-то непонятно.

### Установка интерпретатора Python

В первую очередь вам будет нужен интерпретатор языка Python (о том, что такое "интерпретатор" можно почитать [тут]()), а также компилятор языка Golang, если вы захотите выполнить практики на двух языках. Установка компилятора Golang останется в качестве самостоятельного задания (официальное руководство по установке можно найти [тут](https://golang.org/doc/install)). Где взять интерпретатор Python? На юникс-подобных операционных системах (Linux, MacOS и др.) интерпретатор Python, скорее всего, уже установлен. Проверить это вы можете набрав в терминале (командной строке) команду `python`, например:

```sh
$ python
Python 2.7.10 (default, Jul 30 2016, 18:31:42)
[GCC 4.2.1 Compatible Apple LLVM 8.0.0 (clang-800.0.34)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

> Знак доллара `$` обозначает приглашение к вводу команд. В Windows такое приглашение обычно выглядит как символ больше `>`.

Обратите внимание на версию, в моем случае это 2.7.10. Нам она не подходит ("*Why not?*" - можно почитать [тут](https://wiki.python.org/moin/Python2orPython3) и [тут](http://sebastianraschka.com/Articles/2014_python_2_3_key_diff.html)). Нам нужен интерпретатор третьей версии. Если вы видите, что версия вторая, то попробуйте набрать команду `python3`:

```sh
$ python3
Python 3.6.1 (v3.6.1:69c0db5050, Mar 21 2017, 01:21:04)
[GCC 4.2.1 (Apple Inc. build 5666) (dot 3)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

Если же появляется сообщение об ошибке, то интерпретатор нужно установить. Скачать интерпретатор под нужную операционную систему вы можете с официального [сайта](https://www.python.org/downloads/) (если вы пользователь Linux-системы, то установить интерпретатор можете из репозитория).
После установки обязательно проверьте, что интерпретатор запускается:

```sh
$ python3
>>> print("Hello, World!")
Hello, World!
>>> quit()
```

Это интерактивный режим работы с интерпретатором языка Python ([REPL](https://ru.wikipedia.org/wiki/REPL)). Три символа "_больше_" `>>>` являются приглашением к вводу команд. Для завершения работы с интерпретатором нужно набрать команду `quit()`.

> **Замечание**: Если вы устанавливаете Python на Windows, то есть вероятность, что, набрав команду `python` или `python3` после установки, вы получите сообщение об ошибке. Если так, то попробуйте набрать `py` или `py3`, вместо `python` и `python3`, соответственно. Если вы по-прежнему получаете сообщение об ошибке, то возможно, что путь к интерпретатору не указан в переменной окружения `PATH`. "У меня все равно ничего не работает!" - прочитайте как правильно все [настроить](https://docs.python.org/3/using/windows.html#configuring-python).

### Выбор редактора кода

Вам будет нужен редактор кода. Это может быть "простой" текстовый редактор с подсветкой синтаксиса [SublimeText](http://sublimetext.com/3) или же полноценная среда разработки [PyCharm](https://www.jetbrains.com/pycharm/download/) (подходящим для меня решением оказалась связка из редактора [Vim](http://www.vim.org/) с разными плагинами и интересного, на мой взгляд, проекта [Kite](https://kite.com/)). Я вам рекомендую попробовать оба варианта, но средой разработки пользоваться после того, как научитесь работать с интерпретатором и системой контроля версий.

Для ваших работ заведите себе отдельную папку, назовите ее `cs102` (можете назвать иначе). В этой папке создайте новый файл с именем `hello.py`, откройте его с помощью редактора `SublimeText` (или любого [другого](https://wiki.python.org/moin/PythonEditors), который вам больше понравился):

![](/assets/images/00-introduction/sublimetext.png)

Откройте терминал (командную строку), перейдите в папку с созданным файлом с помощью команды `cd путь_к_cs102` (рекомендую вам создать `alias`, т.е. короткое имя для пути, чтобы в будущем вы всегда могли быстро перейти в эту папку) и запустите скрипт с помощью команды `python hello.py`:

![](/assets/images/00-introduction/bash.png)

Таким образом, вы написали и запустили простейшую программу (скрипт). Запомните эти шаги.

### Работа с виртуальными окружениями

Для выполнения работ рекомендуется использовать модуль `virtualenv`, предназначенный для создания и управления изолированными (виртуальными) окружениями. `virtualenv` позволяет заключить в отдельный каталог необходимые версии python-пакетов и использовать только их. Используя `virtualenv`, вы можете устанавливать свежие версии пакетов из [Python Package Index](https://pypi.python.org/pypi), при этом не получая проблем с совместимостью версий загруженных пакетов и тех, что уже имеются в системе.

```sh
$ pip install virtualenv
```

Для более комфортной работы с `virtualenv` мы будем использовать расширение `virtualenvwrapper` (ниже приведены команды для Unix-like систем, см. замечание):

```bash
$ pip install virtualenvwrapper
$ echo "source virtualenvwrapper.sh" >> ~/.bashrc
$ source ~/.bashrc
```

> **Замечание**: Для пользователей Windows следует установить модуль `virtualenvwrapper-win` вместо `virtualenvwrapper`. Также рекомендуется установить [Git SCM](https://git-for-windows.github.io/).

Создать новое виртуальное окружение можно с помощью команды `mkvirtualenv` (обратите внимание на то, как меняется путь к интерпретатору python):

```sh
$ which python3
/Library/Frameworks/Python.framework/Versions/3.6/bin/python3
$ mkvirtualenv cs102
$ workon cs102
(cs102) $ which python
/Users/dementiy/.virtualenvs/cs102/bin/python
(cs102) $ deactivate
$
```

> **Замечание**: Если у вас не получается настроить `virtualenvwrapper` на ОС Windows, то можете ограничиться `virtualenv`:
```sh
$ virtualenv cs102-env
$ cs102-env\Scripts\activate.bat
(cs102-env) $ # Окружение активировано
$ deactivate
```

Давайте в созданном виртуальном окружении установим два новых пакета: [bpython](http://www.bpython-interpreter.org) и [ipython](https://ipython.org/). Это тоже интерпретаторы языка Python, но с дополнительными функциями (подсветка синтаксиса, подсказки и др):

```sh
# Не забудем перейти в наше виртуальное окружение
$ workon cs102
# Установим необходимые пакеты
(cs102) $ pip install bpython jupyter
# Запуск bpython
(cs102) $ python -m bpython
# Запуск ipython
(cs102) $ ipython
```

> **Замечание**: `bpython` на Windows может [не работать](https://docs.bpython-interpreter.org/windows.html).

В этом примере мы использовали [pip](https://docs.python.org/3.5/installing/index.html) для установки новых пакетов. Иногда устанавливаемый пакет требует наличие других пакетов для своей работы, обычно эти пакеты устанавливаются автоматически (говорят "по зависимостям"). Но может возникнуть ситуация, когда вам придется вручную установить нужную библиотеку. Если вы не знаете как это сделать, то поищите ответ на [stackoverflow.com](http://stackoverflow.com), скорее всего кто-то уже столкнулся с той же проблемой, что и вы.

Теперь всякий раз приступая к работе, активируйте созданное виртуальное окружение с помощью команды `workon cs102`. Полный список команд по работе с `virtualenvwrapper` можно найти [тут](https://virtualenvwrapper.readthedocs.io/en/latest/command_ref.html).

### Система контроля версий

Мы будем пользоваться системой контроля версий (что такое контроль версий и зачем он вам нужен можно почитать [тут](https://git-scm.com/book/ru/v1/Введение-О-контроле-версий)). Все изменения, которые будут происходить с вашими работами, могут храниться локально (у вас на компьютере), а могут и удаленно, так, что вы всегда сможете продолжить работу над своим проектом. Поэтому вам нужно зарегистрироваться либо на [https://github.com](https://github.com), либо на [https://bitbucket.org](https://bitbucket.org/) (а можно и там и там). На случай, если вы хотите ограничить доступ к вашей кодовой базе, то на bitbucket есть возможность создания бесплатного приватного репозитория. 

Рассмотрим пример создания приватного репозитория на bitbucket (рекомендую проделать эти шаги и на github).

Зарегистрируйтесь на сайте [https://bitbucket.org](https://bitbucket.org/). По завершении регистрации вам будет предложено создать новый репозиторий (либо вкладка `Repository -> Crete new repository`). Укажите следующие параметры для вашего проекта (в дальнейшем их можно будет изменить):

![](/assets/images/00-introduction/bitbucket.png)

Далее раскройте список со словами `I'm starting from scratch`:

![](/assets/images/00-introduction/scratch.png)

Достаточно повторить указанные шаги, но вместо файла `contributors.txt` мы сделаем коммит (загрузим изменения на сервер) нашей программы `hello.py`:

```sh
(cs102) $ git init
Initialized empty Git repository in /Users/dementiy/Projects/cs102/.git/
(cs102) $ git remote add origin https://Dementiy@bitbucket.org/Dementiy/cs102.git
(cs102) $ git add hello.py
(cs102) $ git commit -m 'Initial commit with my first program on Python'

*** Please tell me who you are.

Run

git config --global user.email "you@example.com"
git config --global user.name "Your Name"

to set your account`s default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'user@Air-user.(none)')
```

Система контроля версий подсказывает нам, что нужно выполнить предварительную настройку репозитория, указав `user.email` и `user.name`:

```sh
(cs102) $ git config --global user.email "Dementiy@yandex.ru"
(cs102) $ git config --global user.name "Dmitriy"
(cs102) $ git commit -m 'Initial commit with my first program on Python'
[master (root-commit) b9c8e00] Initial commit with my first program on Python
1 file changed, 1 insertion(+)
create mode 100644 hello.py
(cs102) $ git push -u origin master
Password for 'https://Dementiy@bitbucket.org':
Counting objects: 3, done.
Writing objects: 100% (3/3), 258 bytes | 0 bytes/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To https://Dementiy@bitbucket.org/Dementiy/cs102.git
* [new branch] master -> master
Branch master set up to track remote branch master from origin.
```

> **Замечание**: если после выполнения команды `git init` вы получили сообщение об ошибке о том, что команда `git` не найдена, то, скорее всего, вы работаете под Windows и `git` нужно [установить](https://git-scm.com/download/win).

Теперь убедитесь, что новый файл появился на bitbucket.org. Для этого зайдите в раздел `Source`:

![](/assets/images/00-introduction/source.png)

Давайте немного изменим нашу программу `hello.py`, добавив в нее функцию и проверку на то, выполняется ли наша программа как скрипт или она используется как модуль (библиотека, подключаемая в других скриптах):

```python
def message():
    print("Hello, World!")

if __name__ == "__main__":
    message()
```

```sh
# Запуск программы как скрипта
(cs102) $ python3 hello.py
Hello, World!

# Использование программы как модуля
(cs102) $ python3
>>> import hello
>>> hello.message()
Hello, World!
```

Итак, мы внесли нужные изменения в программу, `git` эти изменения также заметил. Проверить это можно с помощью команды `git status`:

```sh
(cs102) $ git status
On branch master
Your branch is up-to-date with 'origin/master'.
Changes not staged for commit:
(use "git add <file>..." to update what will be committed)
(use "git checkout -- <file>..." to discard changes in working directory)

modified: hello.py

no changes added to commit (use "git add" and/or "git commit -a")
```

Один из файлов был изменен: `modified: hello.py`. Теперь нам нужно сделать коммит, чтобы зафиксировать изменения в истории проекта:

```sh
(cs102) $ git add hello.py
(cs102) $ git commit -m "Add function message()"
(cs102) $ git push
```

Пока нам этого будет достаточно.

**Задание**: Добавьте в репозиторий файл с именем `README.md`, который должен содержать информацию о вас как о разработчике и небольшое описание вашего репозитория (например, "Решения практических работ с сайта https://dementiy.github.io"). `README.md` должен быть в формате Markdown, про который можно почитать [тут](https://github.com/OlgaVlasova/markdown-doc/blob/master/README.md). Также можете воспользоваться онлайн редактором [Dillinger](http://dillinger.io/).

Все вопросы и замечания пишите в комментариях или в Slack'е ([что такое Slack?](https://get.slack.help/hc/en-us/articles/115004071768-What-is-Slack-)).

