---
layout: post
title: Простой асинхронный веб-сервер
categories: python golang web практики
---

В этой работе вашей задачей будет написать простой асинхронный wsgi-сервер.

### Простой TCP-сервер

Давайте рассмотрим пример простого однопоточного TCP-сервера:

```py
import socket

def main(host='localhost', port=9090):
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(5)

    while True:
        clientsocket, (client_address, client_port) = serversocket.accept()
        print(f"New client {client_address}:{client_port}")

        while True:
            try:
                data = clientsocket.recv(1024)
                print(f"Recv: {data}")
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
            print(f"Send: {data}")

        clientsocket.close()
        print(f"Bye-bye: {client_address}:{client_port}")


if __name__ == "__main__":
    main()
```

> Узнать больше о сетевом программировании можно в материалах к курсу [Сетевое программирование](http://lecturesnet.readthedocs.io/net/low-level/ipc/socket/intro.html) ИнФО УРфУ и в книжке Джона Гоерзена [Foundations of Python Network Programming](http://www.apress.com/us/book/9781430230038). Также можно прочитать [эту](http://micromind.me/posts/writing-python-web-server-part-1) небольшую статью с примерами на python.

Запустите сервер:

```bash
$ python singlethread.py
```

Откройте другой терминал и запустите `netcat`:

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

> **Примечание**: `Ctrl+D` - завершение работы с `netcat`.

Следует отметить несколько моментов:
- `recv` является **блокирующим вызовом**, то есть, наша программа не продолжит выполнение пока мы не получим данные от клиента;
- клиент сам решает, когда завершить передачу данных, таким образом, пока не будет закрыто текущее соединение (клиентский сокет) мы не можем принимать соединения от других клиентов.

Чтобы решить проблему мы можем для каждого клиента создавать новый поток:

```py
import socket
import threading
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(threadName)-10s) %(message)s'
)

def client_handler(sock, address, port):
    while True:
        try:
            data = sock.recv(1024)
            logging.debug(f"Recv: {data} from {address}:{port}")
        except OSError:
            break

        if len(data) == 0:
            break

        sent_data = data
        while True:
            sent_len = sock.send(data)
            if sent_len == len(data):
                break
            sent_data = sent_data[sent_len:]
        logging.debug(f"Send: {data} to {address}:{port}")

    sock.close()
    logging.debug(f"Bye-bye: {address}:{port}")

def main(host='localhost', port=9090):
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(5)

    while True:
        try:
            client_sock, (client_address, client_port) = serversocket.accept()
            logging.debug(f"New client {client_address}:{client_port}")
            client_thread = threading.Thread(target=client_handler,
                args=(client_sock, client_address, client_port))
            client_thread.daemon = True
            client_thread.start()

if __name__ == "__main__":
    main()
```

```
$ python multithread.py
```

```
[DEBUG] (MainThread) New client: 127.0.0.1:53713
[DEBUG] (Thread-1  ) Recv: b'Hey server\n' from 127.0.0.1:53713
[DEBUG] (Thread-1  ) Send: b'Hey server\n' to 127.0.0.1:53713
[DEBUG] (MainThread) New client: 127.0.0.1:53966
[DEBUG] (Thread-2  ) Recv: b'Hey server\n' from 127.0.0.1:53966
[DEBUG] (Thread-2  ) Send: b'Hey server\n' to 127.0.0.1:53966
...
```

Как много тредов мы можем создать?

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

```py
import socket
import threading
import time
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(threadName)-10s) %(message)s'
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

def main(host='localhost', port=9090):
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    serversocket.bind((host, port))
    serversocket.listen(5)

    NUMBER_OF_THREADS = 2
    for _ in range(NUMBER_OF_THREADS):
        thread = threading.Thread(target=worker_thread,
            args=(serversocket,))
        thread.daemon = True
        thread.start()

    while True:
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

```py
import socket
import multiprocessing
import time
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] (%(processName)-10s) %(message)s'
)

def worker_process(serversocket):
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

def accept_handler(serversocket):
    clientsocket, (client_address, client_port) = serversocket.accept()
    clientsocket.setblocking(False)
    logging.debug(f"New client: {client_address}:{client_port}")
    connections[clientsocket.fileno()] = (clientsocket, client_address, client_port)
    read_waiters[clientsocket.fileno()] = (recv_handler, (clientsocket.fileno(),))
    read_waiters[serversocket.fileno()] = (accept_handler, (serversocket,))

def recv_handler(fileno):
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

def send_handler(fileno, message):
    clientsocket, client_address, client_port = connections[fileno]
    sent_len = clientsocket.send(message)
    logging.debug("Send: {} to {}:{}".format(message[:sent_len], client_address, client_port))
    if sent_len == len(message):
        read_waiters[clientsocket.fileno()] = (recv_handler, (clientsocket.fileno(),))
    else:
        write_waiters[fileno] = (send_handler, (fileno, message[sent_len:]))

def main(host='localhost', port=9090):
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

### Асинхронный HTTP-сервер

В первой части задания от вас требуется написать простой асинхронный [HTTP-сервер](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview) с помощью модулей [asyncore](https://docs.python.org/3.6/library/asyncore.html) и [asynchat](https://docs.python.org/3.6/library/asynchat.html), которые предоставляют базовую инфраструктуру для создания сетевых асинхронных приложений.

Идея лежащая в основе модулей заключается в создании одного или нескольких сетевых каналов (network channels) - экземпляров классов `asyncore.dispatcher` и `asynchat.async_chat`. Каждый созданный канал добавляется в глобальный `map` (словарь вида: `дескриптор сокета: канал`), который используется в функции `loop()`. Вызов функции `loop()` активирует один из механизмов "пулинга" (`select`, `poll`, `epoll`), который продолжает работать до тех пор, пока все каналы не будут закрыты.

> **Замечание**: Начиная с версии Python 3.6 модули `asyncore` и asynchat` считаются устаревшими (deprecated) и рекомендуется использовать модуль [asyncio](https://docs.python.org/3.6/library/asyncio.html#module-asyncio).

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

