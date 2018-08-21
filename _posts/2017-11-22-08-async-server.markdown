---
layout: post
title: Простой асинхронный веб-сервер
categories: python golang web практики
---

В этой работе вашей задачей будет написать две вариации простого асинхронного HTTP-сервера (одна реализация будет работать на неблокирующих сокетах с использованием модулей `asyncore` и `asynchat`, а вторая с использованием модуля `asyncio`). По мере описания работы мы рассмотрим несколько версий простого TCP-сервера, каждую из которых подвергнем нагрузочному тестированию с помощью `locustio`. В конце работы вам надо будет написать простой WSGI-сервер и запустить на нем один из фреймворков (`bottle`, `django`, `falcon` и т.д.).

### Простой TCP-сервер

Давайте рассмотрим пример простого однопоточного TCP-сервера:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Узнать больше о сетевом программировании можно в материалах к курсу <a href="http://lecturesnet.readthedocs.io/net/low-level/ipc/socket/intro.html">Сетевое программирование</a> ИнФО УРфУ и в книжке Джона Гоерзена <a href="http://www.apress.com/us/book/9781430230038">Foundations of Python Network Programming</a>. Также можно прочитать <a href="http://micromind.me/posts/writing-python-web-server-part-1">эту</a> небольшую статью с примерами на python.</p>
</div>

<div class="admonition note">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Большинство методов работы с сокетами (<code>accept</code>, <code>recv</code>, <code>send</code> и т.д.) в CPython являются обертками над соответствующими системными вызовами, которые реализованы в модуле <a href="https://github.com/python/cpython/blob/master/Modules/socketmodule.c">socketmodule.c</a>, например, реализацию метода <code>accept</code> можно посмотреть <a href="https://github.com/python/cpython/blob/master/Modules/socketmodule.c#L2466">тут</a>.</p>
</div>

```python
import socket

def main(host: str = 'localhost', port: int = 9090) -> None:
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(5)
    socket.setdefaulttimeout(10)

    print(f"Starting Echo Server at {host}:{port}")
    try:
        while True:
            clientsocket, (client_address, client_port) = serversocket.accept()
            print(f"New client {client_address}:{client_port}")

            while True:
                try:
                    data = clientsocket.recv(1024)
                    print(f"Recv: {data}")
                except OSError:
                    break

                if not len(data):
                    break

                sent_data = data
                while True:
                    sent_len = clientsocket.send(sent_data)
                    if sent_len == len(data):
                        break
                    sent_data = sent_data[sent_len:]
                print(f"Send: {data}")

            clientsocket.close()
            print(f"Bye-bye: {client_address}:{client_port}")
    except KeyboardInterrupt:
        print("Shutting down")
    finally:
        serversocket.close()

if __name__ == "__main__":
    main()
```

Запустите сервер:

```bash
$ python tcp_singlethread.py
Starting TCP Echo Server at localhost:9090
```

Откройте другой терминал и запустите `netcat`:

<div class="admonition note">
  <p class="first admonition-title"><strong>Подсказка</strong></p>
  <p class="last"><code>Ctrl+D</code> - завершение работы с <code>netcat</code>.</p>
</div>

```bash
$ nc localhost 9090
Hey server
Hey server
...
```

На стороне сервера вы будете видеть все входящие соединения:

```bash
New client 127.0.0.1:61401
Recv: Hey server
Send: Hey server
...
Bye-bye: 127.0.0.1:61401
```

Следует отметить несколько моментов:

<div class="admonition note">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">С помощью <code>setdefaulttimeout</code> мы указали, что сервер должен ожидать данные от клиента не более десяти секунд, а затем закрывать соединение. Указание таймаутов является хорошей практикой при написании приложений взаимодействующих по сети. Вы можете увеличить это время для экспериментов.</p>
</div>

- `recv` является **блокирующим вызовом**, то есть, наша программа не продолжит выполнение пока мы не получим данные от клиента;
- клиент сам решает, когда завершить передачу данных, таким образом, пока не будет закрыто текущее соединение (клиентский сокет) мы **не можем** принимать соединения от других клиентов.

Насколько хорошо такой сервер может справляться с нагрузкой? Ответ зависит от конкретной ситуации. Давайте рассмотрим простой сценарий:
 - каждый клиент шлет запрос раз в 5-15 секунд;
 - размер запроса гарантированно укладывается в 1024 байта;
 - на каждый запрос нам нужно обратиться к базе данных, что в среднем занимает около 300 миллисекунд;
 - в ответ клиент получает HTML-документ;
 - мы ожидаем не больше 100 пользователей.

Ниже приведен пример простого однопоточного веб-сервера:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last"><code>time.sleep(0.3)</code> иммитирует запрос к БД.</p>
</div>

```python
import socket
import time

def main(host: str = 'localhost', port: int = 9090) -> None:
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(128)

    print(f"Starting Web Server at {host}:{port}")
    try:
        while True:
            clientsocket, _ = serversocket.accept()
            _ = clientsocket.recv(1024)
            time.sleep(0.3)
            clientsocket.sendall(
                b"HTTP/1.1 200 OK\r\n"
                b"Content-Type: text/html\r\n"
                b"Content-Length: 71\r\n\r\n"
                b"<html><head><title>Success</title></head><body>Index page</body></html>"
            )
            clientsocket.close()
    except KeyboardInterrupt:
        print("Shutting down")
    finally:
        serversocket.close()

if __name__ == "__main__":
    main()
```

Нагрузочное тестирование мы будем проводить с помощью модуля [locustio](https://locust.io/). Опишем поведение пользователя:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Попробуйте поэкспериментировать с различными параметрами, например, изменить максимальное число клиентов в очереди, увеличить скорость запросов от пользователей, увеличить число самих пользователей, изменить время ожидания БД.</p>
</div>

```python
from locust import HttpLocust, TaskSet, task

class WebsiteTasks(TaskSet):
    @task
    def index(self):
        self.client.get("/")

class WebsiteUser(HttpLocust):
    task_set = WebsiteTasks
    min_wait = 5000
    max_wait = 15000
```

```bash
$ python web_singlethread.py &
$ locust -f locustfile.py --host=http://127.0.0.1:9090/
```

![](/assets/images/08-async-server/load_testing_single.png)

Мы получили ожидаемые результаты: каждую секунду мы можем обработать не более 3-х запросов, медианное время ожидания ответа составляет 20 секунд.

Чтобы решить проблему мы можем для каждого клиента создавать новый поток:

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Про работу с модулем <code>threading</code> можно почитать на <a href="https://pymotw.com/3/threading/index.html">PyMOTW</a>.</p>
</div>

```python
import socket
import threading
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(threadName)-10s) %(message)s'
)


def client_handler(sock: socket.socket, address: str, port: int) -> None:
    while True:
        try:
            message = sock.recv(1024)
            logging.debug(f"Recv: {message} from {address}:{port}")
        except OSError:
            break

        if len(message) == 0:
            break

        sent_message = message
        while True:
            sent_len = sock.send(sent_message)
            if sent_len == len(sent_message):
                break
            sent_message = sent_message[sent_len:]
        logging.debug(f"Send: {message} to {address}:{port}")
    sock.close()
    logging.debug(f"Bye-bye: {address}:{port}")


def main(host: str = 'localhost', port: int = 9090) -> None:
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(128)
    socket.setdefaulttimeout(10)

    print(f"Starting TCP Echo Server at {host}:{port}")
    try:
        while True:
            clientsocket, (client_address, client_port) = serversocket.accept()
            logging.debug(f"New client: {client_address}:{client_port}")
            client_thread = threading.Thread(
                target=client_handler,
                args=(clientsocket, client_address, client_port))
            client_thread.daemon = True
            client_thread.start()
    except KeyboardInterrupt:
        print("Shutting down")
    finally:
        serversocket.close()


if __name__ == "__main__":
    main()
```

Запустите сервер:

```
$ python tcp_multithread.py
Starting TCP Echo Server at localhost:9090
```

В этот раз выполните несколько параллельных соединений с разных терминалов с помощью `netcat`, на стороне сервера вы должны видеть примерно следующее:

```
[DEBUG] (MainThread) New client: 127.0.0.1:53713
[DEBUG] (Thread-1  ) Recv: b'Hey server\n' from 127.0.0.1:53713
[DEBUG] (Thread-1  ) Send: b'Hey server\n' to 127.0.0.1:53713
[DEBUG] (MainThread) New client: 127.0.0.1:53966
[DEBUG] (Thread-2  ) Recv: b'Hey server\n' from 127.0.0.1:53966
[DEBUG] (Thread-2  ) Send: b'Hey server\n' to 127.0.0.1:53966
...
```

Итак, для каждого нового клиента мы запускаем обработчик  `client_handler` в новом потоке, что позволяет нам не блокировать основной поток выполнения и продолжать принимать новые соединения. Давайте теперь проверим как многопоточный сервер будет выдерживать нагрузку:

```python
import socket
import threading
import time


def client_handler(sock: socket.socket):
    _ = sock.recv(1024)
    time.sleep(0.3)
    sock.sendall(
        b"HTTP/1.1 200 OK\r\n"
        b"Content-Type: text/html\r\n"
        b"Content-Length: 71\r\n\r\n"
        b"<html><head><title>Success</title></head><body>Index page</body></html>"
    )
    sock.close()


def main(host: str = 'localhost', port: int = 9090) -> None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    sock.bind((host, port))
    sock.listen(128)
    print(f"Starting Web Server at {host}:{port}")
    try:
        while True:
            client_sock, (client_addr, client_port) = sock.accept()
            client_thread = threading.Thread(
                target=client_handler,
                args=(client_sock,))
            client_thread.daemon = True
            client_thread.start()
    except KeyboardInterrupt:
        print("Shutting down")
    finally:
        sock.close()


if __name__ == "__main__":
    main()
```

![](/assets/images/08-async-server/load_testing_multi.png)

Ситуация значительно улучшилась, теперь среднее время ответа на клиентский запрос равно времени ожидания «ответа от БД».

Как много потоков мы можем создать?

```py
import threading
import time

def loop():
    while True:
        time.sleep(1)

def main():
    for _ in range(10000):
        t = threading.Thread(target=loop)
        t.start()
        print(threading.active_count())
```

<div class="admonition note">
  <p class="first admonition-title"><strong>Mac OS X Specific</strong></p>
  <p class="last">Указанное ограничение является специфичным для Mac OS X. Лимит на создание потоков задан параметром ядра <code>kern.num_taskthreads</code>. Получить текщее значение можно с помощью команды <code>sysctl -n kern.num_taskthreads</code> (по умолчанию <code>2048</code>).</p>
</div>

```
...
2047
2048
Traceback (most recent call last):
  File "toomanythreads.py", line 18, in <module>
    main()
  File "toomanythreads.py", line 13, in main
    t.start()
  File "/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/threading.py", line 846, in start
    _start_new_thread(self._bootstrap, ())
RuntimeError: can't start new thread
```

> If the requests require a lot of CPU time, RAM or network bandwidth, this may slow down the server if many requests are processed at the same time. For instance, if memory consumption causes the server to swap memory in and out of disk, this will result in a serious performance penalty. By controlling the maximum number of threads you can minimize the risk of resource depletion, both due to limiting the memory taken by the processing of the requests, but also due to the limitation and reuse of the threads. Each thread take up a certain amount of memory too, just to represent the thread itself.

Вместо создания нового потока на каждого нового клиента, мы создадим простейший пул потоков. Все потоки в пуле разделяют серверный сокет и могут выполнять на нем `accept`. Если все потоки заняты обработкой клиентских запросов, то клиент будет ждать в очереди, пока не осовободится один из потоков в пуле.

```py
import socket
import threading
import time
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(threadName)-10s) %(message)s'
)


def worker_thread(serversocket: socket.socket, shutdown_event: threading.Event) -> None:
    while not shutdown_event.isSet():
        try:
            clientsock, (client_address, client_port) = serversocket.accept()
            logging.debug(f"New client: {client_address}:{client_port}")
        except (OSError, ConnectionAbortedError):
            continue

        while True:
            try:
                message = clientsock.recv(1024)
                logging.debug(f"Recv: {message} from {client_address}:{client_port}")
            except OSError:
                break

            if len(message) == 0:
                break

            sent_message = message
            while True:
                sent_len = clientsock.send(sent_message)
                if sent_len == len(sent_message):
                    break
                sent_message = sent_message[sent_len:]
            logging.debug(f"Send: {message} to {client_address}:{client_port}")

        clientsock.close()
        logging.debug(f"Bye-bye: {client_address}:{client_port}")
    logging.debug("Shutting down thread")


def main(host: str = 'localhost', port: int = 9090) -> None:
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(128)

    print(f"Starting TCP Echo Server at {host}:{port}")

    NUMBER_OF_THREADS = 10
    threads = []
    shutdown_event = threading.Event()
    for _ in range(NUMBER_OF_THREADS):
        thread = threading.Thread(target=worker_thread,
            args=(serversocket, shutdown_event))
        thread.daemon = True
        thread.start()
        threads.append(thread)

    try:
        for t in threads:
            t.join()
    except KeyboardInterrupt:
        print("Shutting down...")
    finally:
        serversocket.close()
        shutdown_event.set()
        time.sleep(1)

if __name__ == "__main__":
    main()
```

```
[DEBUG] (Thread-1  ) New client: 127.0.0.1:59951
[DEBUG] (Thread-2  ) New client: 127.0.0.1:59991
[DEBUG] (Thread-1  ) Recv: b'Message 1\n' from 127.0.0.1:59951
[DEBUG] (Thread-1  ) Send: b'Message 1\n' to 127.0.0.1:59951
[DEBUG] (Thread-2  ) Recv: b'Message 2\n' from 127.0.0.1:59991
[DEBUG] (Thread-2  ) Send: b'Message 2\n' to 127.0.0.1:59991
[DEBUG] (Thread-1  ) Recv: b'' from 127.0.0.1:59951
[DEBUG] (Thread-1  ) Bye-bye: 127.0.0.1:59951
[DEBUG] (Thread-1  ) New client: 127.0.0.1:60167
[DEBUG] (Thread-1  ) Recv: b'Message 3\n' from 127.0.0.1:60167
[DEBUG] (Thread-1  ) Send: b'Message 3\n' to 127.0.0.1:60167
...
```

Важно понимать, что потоки не выполнялись парарллельно, потому что в Python есть **глобальная блокировка интерпретатора** (Global Interpreter Lock, GIL), которая не позволяет потокам действительно выполняться параллельно. Небольшая выдержка из официальной [документации](https://docs.python.org/3/c-api/init.html#thread-state-and-the-global-interpreter-lock):

> **The Python interpreter is not fully thread-safe**. In order to support multi-threaded Python programs, there’s a global lock, called the global interpreter lock or GIL, that must be held by the current thread before it can safely access Python objects. Without the lock, even the simplest operations could cause problems in a multi-threaded program: for example, **when two threads simultaneously increment the reference count of the same object, the reference count could end up being incremented only once instead of twice**.

> Therefore, the rule exists that only the thread that has acquired the GIL may operate on Python objects or call Python/C API functions. In order to emulate concurrency of execution, the interpreter regularly tries to switch threads (see sys.setswitchinterval()). **The lock is also released around potentially blocking I/O operations like reading or writing a file, so that other Python threads can run in the meantime.**

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Про процессы и потоки доступным языком можно почитать <a href="http://anuragjain67.github.io/writing/2016/01/15/problem-with-multithreading-in-python">тут</a>.</p>
</div>

Таким образом, мы не утилизируем в полном объеме доступные ресурсы процессора. Для решения этой проблемы мы можем создавать процессы, вместо потоков.

```py
import socket
import multiprocessing
import time
import logging


logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(processName)-10s) (%(threadName)-10s) %(message)s'
)


def worker_process(serversocket: socket.socket) -> None:
    while True:
        clientsocket, (client_address, client_port) = serversocket.accept()
        logging.debug(f"New client: {client_address}:{client_port}")

        while True:
            try:
                message = clientsocket.recv(1024)
                logging.debug(f"Recv: {message} from {client_address}:{client_port}")
            except OSError:
                break

            if len(message) == 0:
                break

            sent_message = message
            while True:
                sent_len = clientsocket.send(sent_message)
                if sent_len == len(sent_message):
                    break
                sent_message = sent_message[sent_len:]
            logging.debug(f"Send: {message} to {client_address}:{client_port}")

        clientsocket.close()
        logging.debug(f"Bye-bye: {client_address}:{client_port}")


def main(host: str = 'localhost', port: int = 9090) -> None:
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(128)

    print(f"Starting TCP Echo Server at {host}:{port}")

    NUMBER_OF_PROCESS = multiprocessing.cpu_count()
    processes = []
    logging.debug(f"Number of processes: {NUMBER_OF_PROCESS}")
    for _ in range(NUMBER_OF_PROCESS):
        process = multiprocessing.Process(target=worker_process,
            args=(serversocket,))
        process.start()
        processes.append(process)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Shutting down...")
    finally:
        for p in processes:
            p.terminate()
        serversocket.close()


if __name__ == "__main__":
    main()
```

```
[DEBUG] (MainProcess) Number of processes: 4
[DEBUG] (Process-1 ) Recv: b'Message 1\n' from 127.0.0.1:62720
[DEBUG] (Process-1 ) Send: b'Message 1\n' to 127.0.0.1:62720
[DEBUG] (Process-2 ) Recv: b'Message 2\n' from 127.0.0.1:62758
[DEBUG] (Process-2 ) Send: b'Message 2\n' to 127.0.0.1:62758
[DEBUG] (Process-3 ) Recv: b'Message 3\n' from 127.0.0.1:62913
[DEBUG] (Process-3 ) Send: b'Message 3\n' to 127.0.0.1:62913
[DEBUG] (Process-4 ) Recv: b'Message 4\n' from 127.0.0.1:62978
[DEBUG] (Process-4 ) Send: b'Message 4\n' to 127.0.0.1:62978
...
```

```py
import socket
import threading
import multiprocessing
import time
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(processName)-10s) (%(threadName)-10s) %(message)s'
)

def worker_thread(serversocket):
    while True:
        clientsocket, (client_address, client_port) = serversocket.accept()
        logging.debug(f"New client {client_address}:{client_port}")

        while True:
            try:
                data = clientsocket.recv(1024)
                logging.debug(f"Recv: {data} from {client_address}:{client_port}")
            except OSError:
                break

            if len(data) == 0:
                break

            sent_data = data
            while True:
                sent_len = clientsocket.send(data)
                if sent_len == len(data):
                    break
                sent_data = sent_data[sent_len:]
            logging.debug(f"Send: {data} to {client_address}:{client_port}")

        clientsocket.close()
        logging.debug(f"Bye-bye: {client_address}:{client_port}")

def worker_process(serversocket):
    NUMBER_OF_THREADS = 10
    for _ in range(NUMBER_OF_THREADS):
        thread = threading.Thread(target=worker_thread,
            args=(serversocket,))
        thread.daemon = True
        thread.start()

    while True:
        time.sleep(1)

def main(host='localhost', port=9090):
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(5)

    NUMBER_OF_PROCESS = multiprocessing.cpu_count()
    logging.debug(f"Number of processes {NUMBER_OF_PROCESS}")
    for _ in range(NUMBER_OF_PROCESS):
        process = multiprocessing.Process(target=worker_process,
            args=(serversocket,))
        process.daemon = True
        process.start()

    while True:
        time.sleep(1)

if __name__ == "__main__":
    main()
```

```
[DEBUG] (MainProcess) (MainThread) Number of processes: 4
[DEBUG] (Process-1 ) (Thread-1  ) New client: 127.0.0.1:51802
[DEBUG] (Process-2 ) (Thread-1  ) New client: 127.0.0.1:51840
[DEBUG] (Process-3 ) (Thread-1  ) New client: 127.0.0.1:51866
[DEBUG] (Process-1 ) (Thread-2  ) New client: 127.0.0.1:51892
[DEBUG] (Process-2 ) (Thread-2  ) New client: 127.0.0.1:51918
[DEBUG] (Process-1 ) (Thread-1  ) Recv: b'Message 1\n' from 127.0.0.1:51802
[DEBUG] (Process-1 ) (Thread-1  ) Send: b'Message 1\n' to 127.0.0.1:51802
[DEBUG] (Process-2 ) (Thread-1  ) Recv: b'Message 2\n' from 127.0.0.1:51840
[DEBUG] (Process-2 ) (Thread-1  ) Send: b'Message 2\n' to 127.0.0.1:51840
[DEBUG] (Process-3 ) (Thread-1  ) Recv: b'Message 3\n' from 127.0.0.1:51866
[DEBUG] (Process-3 ) (Thread-1  ) Send: b'Message 3\n' to 127.0.0.1:51866
[DEBUG] (Process-1 ) (Thread-2  ) Recv: b'Message 4\n' from 127.0.0.1:51892
[DEBUG] (Process-1 ) (Thread-2  ) Send: b'Message 4\n' to 127.0.0.1:51892
[DEBUG] (Process-2 ) (Thread-2  ) Recv: b'Message 5\n' from 127.0.0.1:51918
[DEBUG] (Process-2 ) (Thread-2  ) Send: b'Message 5\n' to 127.0.0.1:51918
...
```

До этого мы рассматривали примеры с блокирующими операциями чтения/записи. Давайте рассмотрим пример с использованием [неблокирующих операций и мультиплексирования](https://eklitzke.org/blocking-io-nonblocking-io-and-epoll):

> There’s a few I/O multiplexing system calls. Examples of I/O multiplexing calls include select (defined by POSIX), the epoll family on Linux, and the kqueue family on BSD. These all work fundamentally the same way: they let the kernel know what events (typically read events and write events) are of interest on a set of file descriptors, and then they block until something of interest happens. For instance, you might tell the kernel you are interested in just read events on file descriptor X, both read and write events on file descriptor Y, and just write events on file descriptor Z.

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">В библиотеке Python, начиная с версии 3.4, есть модуль <a href="https://docs.python.org/3/library/selectors.html"><code>selectors</code></a>, который построен поверх модуля <code>select</code> и позволяет автоматически выбрать наиболее эффективную реализация мультиплексирования для целевой ОС. Дополнительно про мультиплексирование можно почитать <a href="https://realpython.com/python-sockets/">тут</a>.</p>
</div>

```py
import socket
import select
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(processName)-10s) (%(threadName)-10s) %(message)s'
)

read_waiters = {}
write_waiters = {}
connections = {}

def accept_handler(serversocket: socket.socket) -> None:
    clientsocket, (client_address, client_port) = serversocket.accept()
    clientsocket.setblocking(False)
    logging.debug(f"New client: {client_address}:{client_port}")
    connections[clientsocket.fileno()] = (clientsocket, client_address, client_port)
    read_waiters[clientsocket.fileno()] = (recv_handler, (clientsocket.fileno(),))
    read_waiters[serversocket.fileno()] = (accept_handler, (serversocket,))

def recv_handler(fileno) -> None:
    def terminate():
        del connections[clientsocket.fileno()]
        clientsocket.close()
        logging.debug(f"Bye-Bye: {client_address}:{client_port}")

    clientsocket, client_address, client_port = connections[fileno]

    try:
        message = clientsocket.recv(1024)
    except OSError:
        terminate()
        return

    if len(message) == 0:
        terminate()
        return

    logging.debug(f"Recv: {message} from {client_address}:{client_port}")
    write_waiters[fileno] = (send_handler, (fileno, message))

def send_handler(fileno, message) -> None:
    clientsocket, client_address, client_port = connections[fileno]
    sent_len = clientsocket.send(message)
    logging.debug("Send: {} to {}:{}".format(message[:sent_len], client_address, client_port))
    if sent_len == len(message):
        read_waiters[clientsocket.fileno()] = (recv_handler, (clientsocket.fileno(),))
    else:
        write_waiters[fileno] = (send_handler, (fileno, message[sent_len:]))

def main(host: str = 'localhost', port: int = 9090) -> None:
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setblocking(False)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(128)

    read_waiters[serversocket.fileno()] = (accept_handler, (serversocket,))
    while True:
        rlist, wlist, _ = select.select(read_waiters.keys(), write_waiters.keys(), [], 60)

        for r_fileno in rlist:
            handler, args = read_waiters.pop(r_fileno)
            handler(*args)

        for w_fileno in wlist:
            handler, args = write_waiters.pop(w_fileno)
            handler(*args)

if __name__ == "__main__":
    main()
```

```
[DEBUG] (MainProcess) (MainThread) New client: 127.0.0.1:56147
[DEBUG] (MainProcess) (MainThread) New client: 127.0.0.1:56187
[DEBUG] (MainProcess) (MainThread) Recv: b'Hey server\n' from 127.0.0.1:56147
[DEBUG] (MainProcess) (MainThread) Send: b'Hey server\n' to 127.0.0.1:56147
[DEBUG] (MainProcess) (MainThread) Recv: b'Hey server\n' from 127.0.0.1:56187
[DEBUG] (MainProcess) (MainThread) Send: b'Hey server\n' to 127.0.0.1:56187
...
```

```python
import asyncio
from asyncio import StreamReader, StreamWriter


async def client_handler(reader: StreamReader, writer: StreamWriter) -> None:
    data: bytes = await reader.read(1024)
    await asyncio.sleep(0.3)
    writer.write(
        b"HTTP/1.1 200 OK\r\n"
        b"Content-Type: text/html\r\n"
        b"Content-Length: 71\r\n\r\n"
        b"<html><head><title>Success</title></head><body>Index page</body></html>"
    )
    await writer.drain()
    writer.close()


loop = asyncio.get_event_loop()
coro = asyncio.start_server(client_handler, '127.0.0.1', 9090, loop=loop)
server = loop.run_until_complete(coro)

print('Serving on {}'.format(server.sockets[0].getsockname()))
try:
    loop.run_forever()
except KeyboardInterrupt:
    pass

server.close()
loop.run_until_complete(server.wait_closed())
loop.close()
```

### Асинхронный HTTP-сервер

В первой части задания от вас требуется написать простой асинхронный [HTTP-сервер](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview) с помощью модулей [asyncore](https://docs.python.org/3.6/library/asyncore.html) и [asynchat](https://docs.python.org/3.6/library/asynchat.html), которые предоставляют базовую инфраструктуру для создания сетевых асинхронных приложений.

<div class="admonition legend">
  <p class="first admonition-title"><strong>Замечание</strong></p>
  <p class="last">Начиная с версии Python 3.6 модули <code>asyncore</code> и <code>asynchat</code> считаются устаревшими (deprecated) и рекомендуется использовать модуль <a href="https://docs.python.org/3.6/library/asyncio.html#module-asyncio">asyncio</a>.</p>
</div>

Идея лежащая в основе модулей заключается в создании одного или нескольких сетевых каналов (network channels) - экземпляров классов `asyncore.dispatcher` и `asynchat.async_chat`. Каждый созданный канал добавляется в глобальный `map` (словарь вида: `дескриптор сокета: канал`), который используется в функции `loop()`. Вызов функции `loop()` активирует один из механизмов опроса сокетов (`select`, `poll`, `epoll`), который продолжает работать до тех пор, пока все каналы не будут закрыты.

Рассмотрим простой пример сервера, который на каждое новое соединение создает свой обработчик (обратите внимание, что экземпляры классов `AsyncHTTPServer` и `AsyncHTTPRequestHandler` являются сетевыми каналами):

```python
import asyncore
import asynchat

class AsyncHTTPRequestHandler(asynchat.async_chat):
    """ Обработчик клиентских запросов """

    def __init__(self, sock):
        super().__init__(sock)

class AsyncHTTPServer(asyncore.dispatcher):

    def __init__(self, host="127.0.0.1", port=9000):
        super().__init__()
        self.create_socket()
        self.set_reuse_addr()
        self.bind((host, port))
        self.listen(5)

    def handle_accepted(self, sock, addr):
        log.debug(f"Incoming connection from {addr}")
        AsyncHTTPRequestHandler(sock)


server = AsyncHTTPServer()
asyncore.loop()
```



```bash
$ python async_server.py &
$ curl 127.0.0.1:9000
Incoming connection from ('127.0.0.1', 56365)
error: ...
curl: (52) Empty reply from server
```

```python
class AsyncHTTPRequestHandler(asynchat.async_chat):

    def __init__(self, sock):
        super().__init__(sock)
        self.set_terminator(b"\r\n\r\n")

    def collect_incoming_data(self, data):
        log.debug(f"Incoming data: {data}")
        self._collect_incoming_data(data)

    def found_terminator(self):
        self.parse_request()

    def parse_request(self):
        pass

    def parse_headers(self):
        pass
```

```bash
$ python async_server.py &
$ curl -m 3 127.0.0.1:9000
Incoming connection from ('127.0.0.1', 56365)
Incoming data: b'GET / HTTP/1.1\r\nHost: 127.0.0.1:9000\r\nUser-Agent: curl/7.49.1\r\nAccept: */*'
curl: (28) Operation timed out after 3000 milliseconds with 0 bytes received
```

Ниже приведен возможный алгоритм метода `parse_request()`:

```
parse_request():
    Если заголовки не разобраны:
        Разобрать заголовки (parse_headers())
        Если заголовки сформированы неверно:
            Послать ответ: "400 Bad Request"
        Если это POST-запрос:
            Если тело запроса не пустое (Content-Length > 0):
                Дочитать запрос
            Иначе:
                Вызвать обработчик запроса (handle_request())
        Иначе:
            Вызвать обработчик запроса (handle_request())
    Иначе:
        Получить тело запроса (может быть пустым)
        Вызвать обработчик запроса (handle_request())
```


```bash
{
    'method': 'GET',
    'uri': '/',
    'protocol': 'HTTP/1.1',
    'Host': '127.0.0.1:9000',
    'User-Agent': 'curl/7.49.1',
    'Accept': '*/*'
}
```

```python
def handle_request(self):
    method_name = 'do_' + self.method
    if not hasattr(self, method_name):
        self.send_error(405)
        self.handle_close()
        return
    handler = getattr(self, method_name)
    handler()
```

```python
def send_error(self, code, message=None):
    try:
        short_msg, long_msg = self.responses[code]
    except KeyError:
        short_msg, long_msg = '???', '???'
    if message is None:
        message = short_msg

    self.send_response(code, message)
    self.send_header("Content-Type", "text/plain")
    self.send_header("Connection", "close")
    self.end_headers()


responses = {
    200: ('OK', 'Request fulfilled, document follows'),
    400: ('Bad Request',
        'Bad request syntax or unsupported method'),
    403: ('Forbidden',
        'Request forbidden -- authorization will not help'),
    404: ('Not Found', 'Nothing matches the given URI'),
    405: ('Method Not Allowed',
        'Specified method is invalid for this resource.'),
}
```

<details><summary>Полный шаблон для сервера</summary>
<pre><code class="lang-py">import asyncore
import asynchat
import socket
import multiprocessing
import logging
import mimetypes
import os
from urlparse import parse_qs
import urllib
import argparse
from time import strftime, gmtime


def url_normalize(path):
    if path.startswith("."):
        path = "/" + path
    while "../" in path:
        p1 = path.find("/..")
        p2 = path.rfind("/", 0, p1)
        if p2 != -1:
            path = path[:p2] + path[p1+3:]
        else:
            path = path.replace("/..", "", 1)
    path = path.replace("/./", "/")
    path = path.replace("/.", "")
    return path


class FileProducer(object):

    def __init__(self, file, chunk_size=4096):
        self.file = file
        self.chunk_size = chunk_size

    def more(self):
        if self.file:
            data = self.file.read(self.chunk_size)
            if data:
                return data
            self.file.close()
            self.file = None
        return ""


class AsyncServer(asyncore.dispatcher):

    def __init__(self, host="127.0.0.1", port=9000):
        pass

    def handle_accepted(self):
        pass

    def serve_forever(self):
        pass


class AsyncHTTPRequestHandler(asynchat.async_chat):

    def __init__(self, sock):
        pass

    def collect_incoming_data(self, data):
        pass

    def found_terminator(self):
        pass

    def parse_request(self):
        pass

    def parse_headers(self):
        pass

    def handle_request(self):
        pass

    def send_header(self, keyword, value):
        pass

    def send_error(self, code, message=None):
        pass

    def send_response(self, code, message=None):
        pass

    def end_headers(self):
        pass

    def date_time_string(self):
        pass

    def send_head(self):
        pass

    def translate_path(self, path):
        pass

    def do_GET(self):
        pass

    def do_HEAD(self):
        pass

    responses = {
        200: ('OK', 'Request fulfilled, document follows'),
        400: ('Bad Request',
            'Bad request syntax or unsupported method'),
        403: ('Forbidden',
            'Request forbidden -- authorization will not help'),
        404: ('Not Found', 'Nothing matches the given URI'),
        405: ('Method Not Allowed',
            'Specified method is invalid for this resource.'),
    }


def parse_args():
    parser = argparse.ArgumentParser("Simple asynchronous web-server")
    parser.add_argument("--host", dest="host", default="127.0.0.1")
    parser.add_argument("--port", dest="port", type=int, default=9000)
    parser.add_argument("--log", dest="loglevel", default="info")
    parser.add_argument("--logfile", dest="logfile", default=None)
    parser.add_argument("-w", dest="nworkers", type=int, default=1)
    parser.add_argument("-r", dest="document_root", default=".")
    return parser.parse_args()

def run():
    server = AsyncServer(host=args.host, port=args.port)
    server.serve_forever()

if __name__ == "__main__":
    args = parse_args()

    logging.basicConfig(
        filename=args.logfile,
        level=getattr(logging, args.loglevel.upper()),
        format="%(name)s: %(process)d %(message)s")
    log = logging.getLogger(__name__)

    DOCUMENT_ROOT = args.document_root
    for _ in xrange(args.nworkers):
        p = multiprocessing.Process(target=run)
        p.start()
</code></pre>
</details>


### Асинхронный HTTP-сервер с использованием asyncio

### Асинхронный WSGI-Server

```py
class AsyncWSGIServer(httpd.AsyncServer):

    def set_app(self, application):
        self.application = application

    def get_app(self):
        return self.application


class AsyncWSGIRequestHandler(httpd.AsyncHTTPRequestHandler):

    def get_environ(self):
        pass

    def start_response(self, status, response_headers, exc_info=None):
        pass

    def handle_request(self):
        pass

    def finish_response(self, result):
        pass
```

```py
def application(env, start_response):
    start_response('200 OK', [('Content-Type', 'text/plain')])
    return [b'Hello World']
```

```bash
$ python async_wsgi.py my_app:application
```

```py
import falcon
import json


class QuoteResource:

    def on_get(self, req, resp):
        quote = {
            'quote': 'I\'ve always been more interested in the future than in the past.',
            'author': 'Grace Hopper'
        }
        resp.body = json.dumps(quote)

    def on_post(self, req, resp):
        pass

api = falcon.API()
api.add_route('/quote', QuoteResource())
```
