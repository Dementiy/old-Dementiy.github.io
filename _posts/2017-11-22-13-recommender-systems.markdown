---
layout: post
title: Рекомендательная система кинофильмов и аниме
categories: python datascience
---

<img src="http://www.bibliotecaviva.cl/wp-content/uploads/2017/06/animanga_.jpg" width="600"/>

## 1. Пререквизиты к работе

**TODO**: Ссылки на статьи Николенко

## 2. Наборы данных

Наборы данных состоят из 73,516 оценок пользователей и 12,294 записей об аниме:

`Anime.csv`:
- `anime_id` — уникальный идентификатор аниме на [MyAnimeList](https://myanimelist.net/).
- `name` — полное название аниме.
- `genre` — список жанров разделенных через запятую.
- `type` — movie, TV, OVA и т.д.
- `episodes` — как много эпизодов в аниме (1 для фильмов).
- `rating` — средний рейтинг аниме.
- `members` — количество участников, которые находятся в группе этого аниме.

`Rating.csv`:
- `user_id` - идентификатор пользователя, сгенерированный случайным образом.
- `anime_id` - идентификатор аниме.
- `rating` - оценка пользователя (-1, если пользователь просмотрел аниме, но не выставил оценку).

## 3. Контентная фильтрация (content-based)

### 3.1 Загружаем набор данных


```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
%matplotlib inline
```

В репозитории уже есть наборы данных в папке `data`, но вы всегда можете получить их с Kaggle.


```python
anime = pd.read_csv('data/anime.csv')
```

Посмотрим на пять первых строк:


```python
anime.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>anime_id</th>
      <th>name</th>
      <th>genre</th>
      <th>type</th>
      <th>episodes</th>
      <th>rating</th>
      <th>members</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>32281</td>
      <td>Kimi no Na wa.</td>
      <td>Drama, Romance, School, Supernatural</td>
      <td>Movie</td>
      <td>1</td>
      <td>9.37</td>
      <td>200630</td>
    </tr>
    <tr>
      <th>1</th>
      <td>5114</td>
      <td>Fullmetal Alchemist: Brotherhood</td>
      <td>Action, Adventure, Drama, Fantasy, Magic, Mili...</td>
      <td>TV</td>
      <td>64</td>
      <td>9.26</td>
      <td>793665</td>
    </tr>
    <tr>
      <th>2</th>
      <td>28977</td>
      <td>Gintama°</td>
      <td>Action, Comedy, Historical, Parody, Samurai, S...</td>
      <td>TV</td>
      <td>51</td>
      <td>9.25</td>
      <td>114262</td>
    </tr>
    <tr>
      <th>3</th>
      <td>9253</td>
      <td>Steins;Gate</td>
      <td>Sci-Fi, Thriller</td>
      <td>TV</td>
      <td>24</td>
      <td>9.17</td>
      <td>673572</td>
    </tr>
    <tr>
      <th>4</th>
      <td>9969</td>
      <td>Gintama&amp;#039;</td>
      <td>Action, Comedy, Historical, Parody, Samurai, S...</td>
      <td>TV</td>
      <td>51</td>
      <td>9.16</td>
      <td>151266</td>
    </tr>
  </tbody>
</table>
</div>




```python
anime.shape
```




    (12294, 7)




```python
anime.info()
```

    <class 'pandas.core.frame.DataFrame'>
    RangeIndex: 12294 entries, 0 to 12293
    Data columns (total 7 columns):
    anime_id    12294 non-null int64
    name        12294 non-null object
    genre       12232 non-null object
    type        12269 non-null object
    episodes    12294 non-null object
    rating      12064 non-null float64
    members     12294 non-null int64
    dtypes: float64(1), int64(2), object(4)
    memory usage: 672.4+ KB


Видим, что количество эпизодов имеет тип `object`, мы к этому вернемся в разделе подготовка данных, а пока посмотрим на количество пропусков:


```python
anime.isnull().sum()
```




    anime_id      0
    name          0
    genre        62
    type         25
    episodes      0
    rating      230
    members       0
    dtype: int64



В данных есть пропуски, некоторые мы можем заполнить, например, жанр. Для этого можно обратиться к API сайта [https://myanimelist.net/](https://myanimelist.net/).

### 3.2 Подготовка данных и борьба с пропусками

#### 3.2.1 Пропуски в типе


```python
anime[anime['type'].isnull()].head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>anime_id</th>
      <th>name</th>
      <th>genre</th>
      <th>type</th>
      <th>episodes</th>
      <th>rating</th>
      <th>members</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>10898</th>
      <td>30484</td>
      <td>Steins;Gate 0</td>
      <td>Sci-Fi, Thriller</td>
      <td>NaN</td>
      <td>Unknown</td>
      <td>NaN</td>
      <td>60999</td>
    </tr>
    <tr>
      <th>10900</th>
      <td>34437</td>
      <td>Code Geass: Fukkatsu no Lelouch</td>
      <td>Action, Drama, Mecha, Military, Sci-Fi, Super ...</td>
      <td>NaN</td>
      <td>Unknown</td>
      <td>NaN</td>
      <td>22748</td>
    </tr>
    <tr>
      <th>10906</th>
      <td>33352</td>
      <td>Violet Evergarden</td>
      <td>Drama, Fantasy</td>
      <td>NaN</td>
      <td>Unknown</td>
      <td>NaN</td>
      <td>20564</td>
    </tr>
    <tr>
      <th>10907</th>
      <td>33248</td>
      <td>K: Seven Stories</td>
      <td>Action, Drama, Super Power, Supernatural</td>
      <td>NaN</td>
      <td>Unknown</td>
      <td>NaN</td>
      <td>22133</td>
    </tr>
    <tr>
      <th>10918</th>
      <td>33845</td>
      <td>Free! (Shinsaku)</td>
      <td>School, Sports</td>
      <td>NaN</td>
      <td>Unknown</td>
      <td>NaN</td>
      <td>8666</td>
    </tr>
  </tbody>
</table>
</div>



У всех аниме, у которых не указан тип, также не указаны признаки число эпизодов и рейтинг. Поэтому мы удалим эти строки из набора данных:


```python
anime = anime[~anime['type'].isnull()]
```

#### 3.2.2 Пропуски в жанрах (неудачная попытка)


```python
anime[anime['genre'].isnull()].head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>anime_id</th>
      <th>name</th>
      <th>genre</th>
      <th>type</th>
      <th>episodes</th>
      <th>rating</th>
      <th>members</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2844</th>
      <td>33242</td>
      <td>IS: Infinite Stratos 2 - Infinite Wedding</td>
      <td>NaN</td>
      <td>Special</td>
      <td>1</td>
      <td>7.15</td>
      <td>6604</td>
    </tr>
    <tr>
      <th>3541</th>
      <td>33589</td>
      <td>ViVid Strike!</td>
      <td>NaN</td>
      <td>TV</td>
      <td>12</td>
      <td>6.96</td>
      <td>12345</td>
    </tr>
    <tr>
      <th>6040</th>
      <td>29765</td>
      <td>Metropolis (2009)</td>
      <td>NaN</td>
      <td>Movie</td>
      <td>1</td>
      <td>6.27</td>
      <td>313</td>
    </tr>
    <tr>
      <th>6646</th>
      <td>32695</td>
      <td>Match Shoujo</td>
      <td>NaN</td>
      <td>ONA</td>
      <td>1</td>
      <td>6.02</td>
      <td>242</td>
    </tr>
    <tr>
      <th>7018</th>
      <td>33187</td>
      <td>Katsudou Shashin</td>
      <td>NaN</td>
      <td>Movie</td>
      <td>1</td>
      <td>5.79</td>
      <td>607</td>
    </tr>
  </tbody>
</table>
</div>




```python
#import requests
#from requests.auth import HTTPBasicAuth
```


```python
#response = requests.get("https://myanimelist.net/api/anime/search.xml?q=Steins+Gate", auth=HTTPBasicAuth("dementiy", "h2ocktlsyfgtcrt"))
```


```python
#response.text
```


```python
# bf.data(fromstring(response.text))['anime']['entry']
```


```python
#response = requests.post("https://myanimelist.net/api/account/verify_credentials.xml",
#                         auth=HTTPBasicAuth("dementiy", "h2ocktlsyfgtcrt"))
```


```python
#from xmljson import badgerfish as bf
#from xml.etree.ElementTree import fromstring
#from json import dumps
```

#### 3.2.3 Пропуски в эпизодах

У некоторых аниме неизвестно количество эпизодов даже если они имеют приблизительно равный рейтинг. Например, такие популярные аниме как «Naruto Shippuden» или «Attack on Titan Season 2» продолжали трансилироваться на японском телевидение на момент сбора данных, таким образом, количество эпизодов для этих аниме рассматривалось как «Unknown».

Часть пропусков мы заполним вручную. Те аниме, которые относятся к жанрам «Hentai», «OVA« (Original Video Animation) и «Movies» мы будем рассматривать как состоящие из 1 эпизода. Оставшиеся пропуски мы заполним медианными значениями по типу.


```python
anime[anime['episodes'] == 'Unknown'].head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>anime_id</th>
      <th>name</th>
      <th>genre</th>
      <th>type</th>
      <th>episodes</th>
      <th>rating</th>
      <th>members</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>74</th>
      <td>21</td>
      <td>One Piece</td>
      <td>Action, Adventure, Comedy, Drama, Fantasy, Sho...</td>
      <td>TV</td>
      <td>Unknown</td>
      <td>8.58</td>
      <td>504862</td>
    </tr>
    <tr>
      <th>252</th>
      <td>235</td>
      <td>Detective Conan</td>
      <td>Adventure, Comedy, Mystery, Police, Shounen</td>
      <td>TV</td>
      <td>Unknown</td>
      <td>8.25</td>
      <td>114702</td>
    </tr>
    <tr>
      <th>615</th>
      <td>1735</td>
      <td>Naruto: Shippuuden</td>
      <td>Action, Comedy, Martial Arts, Shounen, Super P...</td>
      <td>TV</td>
      <td>Unknown</td>
      <td>7.94</td>
      <td>533578</td>
    </tr>
    <tr>
      <th>991</th>
      <td>966</td>
      <td>Crayon Shin-chan</td>
      <td>Comedy, Ecchi, Kids, School, Shounen, Slice of...</td>
      <td>TV</td>
      <td>Unknown</td>
      <td>7.73</td>
      <td>26267</td>
    </tr>
    <tr>
      <th>1021</th>
      <td>33157</td>
      <td>Tanaka-kun wa Itsumo Kedaruge Specials</td>
      <td>Comedy, School, Slice of Life</td>
      <td>Special</td>
      <td>Unknown</td>
      <td>7.72</td>
      <td>5400</td>
    </tr>
  </tbody>
</table>
</div>



Заменим все `Unknown` на `nan`:


```python
anime['episodes'] = anime['episodes'].replace('Unknown', np.nan)
anime['episodes'] = anime['episodes'].astype('float64')
```


```python
anime.loc[(anime["genre"] == "Hentai") & (anime["episodes"].isnull()), "episodes"] = 1
anime.loc[(anime["type"] == "OVA") & (anime["episodes"].isnull()), "episodes"] = 1
anime.loc[(anime["type"] == "Movie") & (anime["episodes"].isnull()), "episodes"] = 1
```


```python
anime[anime['episodes'].isnull()].head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>anime_id</th>
      <th>name</th>
      <th>genre</th>
      <th>type</th>
      <th>episodes</th>
      <th>rating</th>
      <th>members</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>74</th>
      <td>21</td>
      <td>One Piece</td>
      <td>Action, Adventure, Comedy, Drama, Fantasy, Sho...</td>
      <td>TV</td>
      <td>NaN</td>
      <td>8.58</td>
      <td>504862</td>
    </tr>
    <tr>
      <th>252</th>
      <td>235</td>
      <td>Detective Conan</td>
      <td>Adventure, Comedy, Mystery, Police, Shounen</td>
      <td>TV</td>
      <td>NaN</td>
      <td>8.25</td>
      <td>114702</td>
    </tr>
    <tr>
      <th>615</th>
      <td>1735</td>
      <td>Naruto: Shippuuden</td>
      <td>Action, Comedy, Martial Arts, Shounen, Super P...</td>
      <td>TV</td>
      <td>NaN</td>
      <td>7.94</td>
      <td>533578</td>
    </tr>
    <tr>
      <th>991</th>
      <td>966</td>
      <td>Crayon Shin-chan</td>
      <td>Comedy, Ecchi, Kids, School, Shounen, Slice of...</td>
      <td>TV</td>
      <td>NaN</td>
      <td>7.73</td>
      <td>26267</td>
    </tr>
    <tr>
      <th>1021</th>
      <td>33157</td>
      <td>Tanaka-kun wa Itsumo Kedaruge Specials</td>
      <td>Comedy, School, Slice of Life</td>
      <td>Special</td>
      <td>NaN</td>
      <td>7.72</td>
      <td>5400</td>
    </tr>
  </tbody>
</table>
</div>




```python
known_animes = {
    "Naruto: Shippuuden": 500,
    "One Piece": 784,
    "Detective Conan": 854,
    "Dragon Ball Super": 86,
    "Crayon Shin chan": 942,
    "Yu Gi Oh Arc V": 148,
    "Shingeki no Kyojin Season 2": 25,
    "Boku no Hero Academia 2nd Season": 25,
    "Little Witch Academia TV": 25
}
```


```python
for k,v in known_animes.items():    
    anime.loc[anime["name"] == k, "episodes"] = v
```

Оставшиеся пропуски заполним медианными значениями по каждой группе:


```python
anime['episodes'] = anime['episodes'].fillna(
    anime.groupby('type')['episodes'].transform('median')
)
```


```python
anime[anime['anime_id'] == 33157]
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>anime_id</th>
      <th>name</th>
      <th>genre</th>
      <th>type</th>
      <th>episodes</th>
      <th>rating</th>
      <th>members</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>1021</th>
      <td>33157</td>
      <td>Tanaka-kun wa Itsumo Kedaruge Specials</td>
      <td>Comedy, School, Slice of Life</td>
      <td>Special</td>
      <td>1.0</td>
      <td>7.72</td>
      <td>5400</td>
    </tr>
  </tbody>
</table>
</div>




```python
anime['episodes'] = anime['episodes'].astype('int')
```

#### 3.2.4 Кодирование типа


```python
pd.get_dummies(anime[["type"]]).head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>type_Movie</th>
      <th>type_Music</th>
      <th>type_ONA</th>
      <th>type_OVA</th>
      <th>type_Special</th>
      <th>type_TV</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
    </tr>
    <tr>
      <th>2</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
    </tr>
    <tr>
      <th>3</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
    </tr>
  </tbody>
</table>
</div>



#### 3.2.5 Rating, Members and Genre

For members feature, I Just converted the strings to float.Episode numbers, members and rating are different from categorical variables and very different in values. Rating ranges from 0-10 in the dataset while the episode number can be even 800+ episodes long when it comes to long running popular animes such as One Piece, Naruto etc. So I ended up using sklearn.preprocessing.MinMaxScaler as it scales the values from 0-1.Many animes have unknown ratings. These were filled with the median of the ratings.


```python
anime["rating"].hist();
```


![png](recommender-systems_files/recommender-systems_47_0.png)



```python
#plt.figure(figsize=(10, 8))
sns.boxplot(data=anime, x='type', y='rating');
```

    /Library/Frameworks/Python.framework/Versions/3.5/lib/python3.5/site-packages/seaborn/categorical.py:454: FutureWarning: remove_na is deprecated and is a private function. Do not use.
      box_data = remove_na(group_data)



![png](recommender-systems_files/recommender-systems_48_1.png)



```python
#anime["rating"] = anime["rating"].astype(float)
#anime["rating"].fillna(anime["rating"].median(), inplace = True)
anime['rating'] = anime['rating'].fillna(
    anime.groupby('type')['rating'].transform('median')
)
anime["members"] = anime["members"].astype(int)
```


```python
# Scaling
anime_features = pd.concat([
    anime["genre"].str.get_dummies(sep=", "),
    pd.get_dummies(anime[["type"]]),
    anime[["rating"]],
    anime[["members"]],
    anime["episodes"]
], axis=1)
anime["name"] = anime["name"].map(lambda name:re.sub('[^A-Za-z0-9]+', " ", name))
anime_features.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Action</th>
      <th>Adventure</th>
      <th>Cars</th>
      <th>Comedy</th>
      <th>Dementia</th>
      <th>Demons</th>
      <th>Drama</th>
      <th>Ecchi</th>
      <th>Fantasy</th>
      <th>Game</th>
      <th>...</th>
      <th>Yuri</th>
      <th>type_Movie</th>
      <th>type_Music</th>
      <th>type_ONA</th>
      <th>type_OVA</th>
      <th>type_Special</th>
      <th>type_TV</th>
      <th>rating</th>
      <th>members</th>
      <th>episodes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>...</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>9.37</td>
      <td>200630</td>
      <td>1</td>
    </tr>
    <tr>
      <th>1</th>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>...</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>9.26</td>
      <td>793665</td>
      <td>64</td>
    </tr>
    <tr>
      <th>2</th>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>...</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>9.25</td>
      <td>114262</td>
      <td>51</td>
    </tr>
    <tr>
      <th>3</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>...</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>9.17</td>
      <td>673572</td>
      <td>24</td>
    </tr>
    <tr>
      <th>4</th>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>...</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>9.16</td>
      <td>151266</td>
      <td>51</td>
    </tr>
  </tbody>
</table>
<p>5 rows × 52 columns</p>
</div>




```python
anime_features.columns
```




    Index(['Action', 'Adventure', 'Cars', 'Comedy', 'Dementia', 'Demons', 'Drama',
           'Ecchi', 'Fantasy', 'Game', 'Harem', 'Hentai', 'Historical', 'Horror',
           'Josei', 'Kids', 'Magic', 'Martial Arts', 'Mecha', 'Military', 'Music',
           'Mystery', 'Parody', 'Police', 'Psychological', 'Romance', 'Samurai',
           'School', 'Sci-Fi', 'Seinen', 'Shoujo', 'Shoujo Ai', 'Shounen',
           'Shounen Ai', 'Slice of Life', 'Space', 'Sports', 'Super Power',
           'Supernatural', 'Thriller', 'Vampire', 'Yaoi', 'Yuri', 'type_Movie',
           'type_Music', 'type_ONA', 'type_OVA', 'type_Special', 'type_TV',
           'rating', 'members', 'episodes'],
          dtype='object')




```python
from sklearn.preprocessing import MinMaxScaler
```


```python
min_max_scaler = MinMaxScaler()
anime_features = min_max_scaler.fit_transform(anime_features)
```


```python
np.round(anime_features, 2)
```




    array([[ 0.  ,  0.  ,  0.  , ...,  0.92,  0.2 ,  0.  ],
           [ 1.  ,  1.  ,  0.  , ...,  0.91,  0.78,  0.03],
           [ 1.  ,  0.  ,  0.  , ...,  0.91,  0.11,  0.03],
           ..., 
           [ 0.  ,  0.  ,  0.  , ...,  0.39,  0.  ,  0.  ],
           [ 0.  ,  0.  ,  0.  , ...,  0.4 ,  0.  ,  0.  ],
           [ 0.  ,  0.  ,  0.  , ...,  0.45,  0.  ,  0.  ]])



#### Метод К-ближайших соседей (K nearest Neighbor, KNN)

Для поиска похожих аниме мы будем использовать очень простой алгоритм машинного обучения - метод K-ближайших соседей, суть которого заключается в поиске k наиболее похожих объектов на данный при заданной метрике схожести, которой может быть `euclidean` (Евклидово расстояние), `jaccard similarity` (коэффициент Жаккара) , `minkowsky` (метрика Минковского) или произвольная метрика.

KNN используется как в задачах классификации, так и в задачах регрессии. При решении задач классификации для прогнозирования метки класса мы сначала ищем ближайших объектов 

KNN is used for both classification and regression problems. In classification problems to predict the label of a instance we first find k closest instances to the given one based on the distance metric and based on the majority voting scheme or weighted majority voting(neighbors which are closer are weighted higher) we predict the labels.


KNN Classification, Image Credit : Introduction to KNN, AnalyticsVidya
In an unsupervised setting such as this context we can simply find the neighbors and use them to recommend similar items. In rough words, to suggest similar animes I first find k-similar anime’s and recommend them to user. In this case I’ve retrieved top 5 most similar anime’s to a given query. For example, if I query “Naruto” to the recommender system, it will return me top 5 anime’s similar to Naruto.

I’ve used genre, type, episodes, rating and members as features and did not use the name feature by choice. I could have handled the text feature with tf-idf or other tactics like bag of words, but using the names actually would have made the recommendation ‘too easy’. It’s easy to show similar anime’s like Naruto if we show Naruto 2nd season and all the Naruto movies, I wanted to see how far a simple approach without using text features will go.

#### Fit Nearest Neighbor To Data


```python
from sklearn.neighbors import NearestNeighbors
```


```python
nbrs = NearestNeighbors(n_neighbors=6, algorithm='ball_tree').fit(anime_features)
```


```python
distances, indices = nbrs.kneighbors(anime_features)
```

#### Query examples and helper functions

Many anime names have not been documented properly and in many cases the names are in Japanese instead of English and the spelling is often different. For that reason I've also created another helper function get_id_from_partial_name to find out ids of the animes from part of names.


```python
def get_index_from_name(name):
    return anime[anime["name"]==name].index.tolist()[0]
```


```python
all_anime_names = list(anime.name.values)
```


```python
def get_id_from_partial_name(partial):
    for name in all_anime_names:
        if partial in name:
            print(name,all_anime_names.index(name))
```


```python
""" print_similar_query can search for similar animes both by id and by name. """

def print_similar_animes(query=None,id=None):
    if id:
        for id in indices[id][1:]:
            print(anime.ix[id]["name"])
    if query:
        found_id = get_index_from_name(query)
        for id in indices[found_id][1:]:
            print(anime.ix[id]["name"])
```

#### Query Examples


```python
print_similar_animes(query="Naruto")
```

    Naruto Shippuuden
    Katekyo Hitman Reborn 
    Bleach
    Dragon Ball Z
    Boku no Hero Academia


    /Library/Frameworks/Python.framework/Versions/3.5/lib/python3.5/site-packages/ipykernel/__main__.py:10: DeprecationWarning: 
    .ix is deprecated. Please use
    .loc for label based indexing or
    .iloc for positional indexing
    
    See the documentation here:
    http://pandas.pydata.org/pandas-docs/stable/indexing.html#ix-indexer-is-deprecated



```python
print_similar_animes("Evangelion")
```


    ---------------------------------------------------------------------------

    IndexError                                Traceback (most recent call last)

    <ipython-input-440-2a397c10b122> in <module>()
    ----> 1 print_similar_animes("Evangelion")
    

    <ipython-input-438-5d437245a55d> in print_similar_animes(query, id)
          6             print(anime.ix[id]["name"])
          7     if query:
    ----> 8         found_id = get_index_from_name(query)
          9         for id in indices[found_id][1:]:
         10             print(anime.ix[id]["name"])


    <ipython-input-435-f64d6779b872> in get_index_from_name(name)
          1 def get_index_from_name(name):
    ----> 2     return anime[anime["name"]==name].index.tolist()[0]
    

    IndexError: list index out of range



```python
print_similar_animes("Fairy Tail")
```

    Fairy Tail 2014 
    Magi The Labyrinth of Magic
    Magi The Kingdom of Magic
    Densetsu no Yuusha no Densetsu
    Magi Sinbad no Bouken TV 



```python
print_similar_animes("Black Lagoon")
```

    Black Lagoon The Second Barrage
    Canaan
    Gangsta 
    Jormungand
    Dimension W



```python
[name for name in anime.name if name.startswith("Macross")]
```




    ['Macross Do You Remember Love ',
     'Macross',
     'Macross F Movie 2 Sayonara no Tsubasa',
     'Macross F',
     'Macross F Movie 1 Itsuwari no Utahime',
     'Macross F Close Encounter Deculture Edition',
     'Macross Plus',
     'Macross Plus Movie Edition',
     'Macross Zero',
     'Macross F Music Clip Shuu Nyankuri',
     'Macross ',
     'Macross 7',
     'Macross 7 Encore',
     'Macross 7 Movie Ginga ga Ore wo Yondeiru ',
     'Macross Flash Back 2012',
     'Macross 7 Plus',
     'Macross Dynamite 7',
     'Macross F Choujikuu Gekijou',
     'Macross 25th Anniversary All That VF Macross F Version',
     'Macross 25th Anniversary All That VF Macross Zero Version',
     'Macross II Lovers Again',
     'Macross FB7 Ore no Uta wo Kike ',
     'Macross Fufonfia',
     'Macross XX',
     'Macross Fufonfia Specials']


