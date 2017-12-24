---
layout: post
title: Бот для мессенджера Telegram
categories: python golang web практики
---

Эта работа посвящена созданию бота для социальной сети [Telegram](https://telegram.org). Для ее выполнения вам понадобится зарегистрироваться на сайте https://telegram.org (если вы ранее этого не сделали).

> **Мотивация**: 18 апреля 2016 года появилась [новость](https://telegram.org/blog/botprize), что выделенен призовой фонд в размере одного миллиона долларов для всех желающих поучаствовать в разработке собственного бота для сети Telegram. Гранты выдаваемые участникам начинаются от 25 тысяч долларов. Конкурс продлён до 2017 года включительно.

### Meet the Botfather

Предварительно мы рассмотрим простой пример создания так называемого эхо-бота. Чтобы зарегистрировать нового бота в телеграмме, вам нужно выполнить несколько простых шагов, которые подробно описаны в этом [руководстве](https://core.telegram.org/bots). Ниже приведен пример регистрации бота с именем `cs102_bot`:

![](/assets/images/05-telegram/tele_bot.png)

Обратите внимание, что последним ответом `BotFather` был токен доступа (`access_token`), который нам понадобится в дальнейшей работе.

> **Внимание**: У вас будет свой токен доступа, которым не следует делиться с другими.

На текущем этапе созданный нами бот ничего не умеет делать и не знает ни одной команды. Для "обучения" бота мы будем использовать [API](https://core.telegram.org/bots/api), который предоставляет телеграмм:

> The Bot API is an HTTP-based interface created for developers keen on building bots for Telegram

Мы не будем напрямую работать с API, как это было в работе с API ВКонтакте, а воспользуемся модулем [pyTelegramBotAPI](https://github.com/eternnoir/pyTelegramBotAPI). Подробное руководство на русском языке по работе с этим модулем вы можете найти [тут](https://kondra007.gitbooks.io/telegram-bot-lessons/content/chapter1.html).

Теперь нам нужно установить модуль pyTelegramBotAPI:

```sh
$ pip3 install pytelegrambotapi
```

Ниже приведен пример простого эхо бота, который дублирует каждое ваше сообщение:

```python
import telebot


access_token = # PUT YOUR ACCESS TOKEN HERE
# Создание бота с указанным токеном доступа
bot = telebot.TeleBot(access_token)


# Бот будет отвечать только на текстовые сообщения
@bot.message_handler(content_types=['text'])
def echo(message):
    bot.send_message(message.chat.id, message.text)


if __name__ == '__main__':
    bot.polling(none_stop=True)
```

Запустить бота можно следующим образом:

```sh
$ python3 bot.py
```

Теперь зайдите в телеграмм и напишите вашему боту любое сообщение:

![](/assets/images/05-telegram/tele_echo.png)

### Делаем бота умнее

Теперь обучим нашего бота делать чуть больше и понимать команды. Целью всей работы является написать бота, который бы позволил получить расписание занятий для любой группы. Бот должен понимать следующие команды:

* `near_lesson GROUP_NUMBER` - ближайшее занятие для указанной группы;
* `DAY WEEK_NUMBER GROUP_NUMBER` - расписание занятий в указанный день (`monday, thuesday, ...`). Неделя может быть четной (`1`), нечетной (`2`) или же четная и нечетная (`0`);
* `tommorow GROUP_NUMBER` - расписание на следующий день (если это воскресенье, то выводится расписание на понедельник, учитывая, что неделя может быть четной или нечетной);
* `all WEEK_NUMBER GROUP_NUMBER` - расписание на всю неделю.

Разберем пример с выводом расписания на понедельник. Для этого нам нужно получить код html-страницы для соответствующей группы, а затем из этой страницы выделить интересующую нас информацию.

> **Замечание**: Чтобы вам было проще ориентироваться в работе -  рекомендуется скачать пример любой страницы с расписанием:
![](/assets/images/05-telegram/html_schedule.png)

Чтобы получить исходный код страницы достаточно выполнить `GET` запрос. `URL`, к которому мы будем обращаться, имеет следующий формат:

```
http://www.ifmo.ru/ru/schedule/0/GROUP/WEEK/raspisanie_zanyatiy_GROUP.htm
```

Где `WEEK` это неделя (четная-нечетная), если неделя не указана, то расписание включает и четную и нечетную недели; `GROUP` - номер группы.

```python
import requests
import config


def get_page(group, week=''):
    if week:
        week = str(week) + '/'
    url = '{domain}/{group}/{week}raspisanie_zanyatiy_{group}.htm'.format(
        domain=config.domain, 
        week=week, 
        group=group)
    response = requests.get(url)
    web_page = response.text
    return web_page
```

> **Замечание**: Сайт Университета ИТМО не приветствует большого числа обращений. Поэтому подумайте о возможности сохранения страниц с расписанием локально или их хранение в памяти на время работы бота, чтобы при повторном обращении к той же страницы вам не пришлось делать новый запрос к серверу университета.


Теперь из этой страницы нам нужно извлечь время занятий, место проведения, аудиторию и название дисциплины. Для этого нам понадобится HTML-парсер. В этой работе предлогается использовать модуль [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/bs4/doc/).

```python
from bs4 import BeautifulSoup


def get_schedule(web_page):
    soup = BeautifulSoup(web_page, "html5lib")
    
    # Получаем таблицу с расписанием на понедельник
    schedule_table = soup.find("table", attrs={"id": "1day"})

    # Время проведения занятий
    times_list = schedule_table.find_all("td", attrs={"class": "time"})
    times_list = [time.span.text for time in times_list]

    # Место проведения занятий
    locations_list = schedule_table.find_all("td", attrs={"class": "room"})
    locations_list = [room.span.text for room in locations_list]

    # Название дисциплин и имена преподавателей
    lessons_list = schedule_table.find_all("td", attrs={"class": "lesson"})
    lessons_list = [lesson.text.split('\n\n') for lesson in lessons_list]
    lessons_list = [', '.join([info for info in lesson_info if info]) for lesson_info in lessons_list]

    return times_list, locations_list, lessons_list
```

Методы `find` и `find_all` позволяют найти теги с указанными атрибутами.

Таким образом, мы получили время, место и название дисциплины (получение номера аудитории остается для самостоятельного выполнения). Наконец добавим нашему боту возможность вывода расписания на понедельник:

```python
@bot.message_handler(commands=['monday'])
def get_monday(message):
    _, group = message.text.split()
    web_page = get_page(group)
    times_lst, locations_lst, lessons_lst = get_schedule(web_page)

    resp = ''
    for time, location, lession in zip(times_lst, locations_lst, lessons_lst):
        resp += '<b>{}</b>, {}, {}\n'.format(time, location, lession)

    bot.send_message(message.chat.id, resp, parse_mode='HTML')
```

![](/assets/images/05-telegram/monday.png)

> **Замечание**: Вы можете легко обобщить функции `get_monday` и `get_schedule` на любой день недели.

### Размещаем бота в Сети  
Последняя часть работы посвящена размещению бота на облачной платформе [Heroku](https://www.heroku.com).

От вас требуется зарегистрироваться на Heroku и создать там новое приложение:

![](/assets/images/05-telegram/heroku_step1.png)


![](/assets/images/05-telegram/heroku_step2.png)

В папке с вашим проектом создайте три файла:
* `runtime.txt` - версия интерпретатора Python, которая требуется для запуска приложения;
* `requirements.txt` - модули, необходимые для работы приложения;
* `Procfile` - указывает тип приложения и главный класс (в нашем случае это python-приложение и файл bot.py соответственно).

Пример содержимого этих файлов приведен ниже:

```
### runtime.txt ###
python-3.5.2


### requirements.txt ###
beautifulsoup4==4.5.1
bs4==0.0.1
pyTelegramBotAPI==2.1.7
requests==2.11.1


### Procfile ###
web: python3 bot.py
```

Далее зайдите на вкладку `Deploy`, где подробно описан процесс размещения вашего приложения на сервисе Heroku:

![](/assets/images/05-telegram/heroku_step3.png)

После пуша на heroku master приложение автоматически настраивает проект и запускает бота. При успешном завершении ваш бот должен работать на удалённой машине.
Чтобы проследить ход выполнения этих операций и найти возможные ошибки введите в консоли 
`heroku logs --tail`
