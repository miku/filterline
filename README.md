README
======

filterline filters a file by line numbers.

Taken from [here](http://unix.stackexchange.com/questions/209404/filter-file-by-line-number). There's an [awk version](https://gist.github.com/miku/bc8315b10413203b31de), too.

----

One use case for such a filter is *data compaction*. Say, you harvest an API every day and you keep the JSON responses in a log.

What is a log?

> A log is perhaps the simplest possible storage abstraction. It is an **append-only**, totally-ordered sequence of records ordered by time.

From: [The Log: What every software engineer should know about real-time data's unifying abstraction](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)

For simplicity the log is just a *file*. So everytime you harvest the API, you just append to a file:

```sh
$ cat harvest-2015-06-01.ldj >> log.ldj
# on the next day ...
$ cat harvest-2015-06-02.ldj >> log.ldj
...
```

The API responses can contain entries that are *new* and entries which represent *updates*. If you want to answer the question

> What is the current state of the data?

you have to find the most recent version of each record in that log file. A typical solution would be to switch from a file to a database of sorts and do some kind of [upsert](https://wiki.postgresql.org/wiki/UPSERT#.22UPSERT.22_definition).

But how about logs with 100M, 500M or billions of records? And what if you do not want to run extra component, like a database?

You can make this process a shell one-liner, and a reasonably fast one, too.

Let's say the log entries look like this:

    $ head log.ldj
    {"id": 1, "msg": "A"}
    {"id": 2, "msg": "B"}
    {"id": 1, "msg": "C"}
    {"id": 1, "msg": "D"}
    ...

Let's say, `log.ldj` contains 1B entries (line numbers are at most ten digits) and you want to get the latest entry for each `id`. Utilizing [ldjtab](https://github.com/miku/ldjtab), the following will extract the ids along with the line number (padded), perform some munging and use `filterline` in the end to filter the original file:

    $ filterline <(ldjtab -padlength 10 -key id log.ldj | tac | \
                   sort -u -k1,1 | cut -f2 | sed 's/^0*//' | sort -n) \
                   log.ldj > latest.ldj

The filtered `latest.ldj` will contain the last entry for each `id` in the log.

Installation
------------

There are deb and rpm [packages](https://github.com/miku/filterline/releases).

To build from source:

    $ git clone https://github.com/miku/filterline.git
    $ cd filterline
    $ make

Usage
-----

Note that line numbers (L) **must be sorted** and **must not contain duplicates**.

    $ filterline
    Usage: filterline FILE1 FILE2

    FILE1: line numbers, FILE2: input file

    $ cat fixtures/L
    1
    2
    5
    6

    $ cat fixtures/F
    line 1
    line 2
    line 3
    line 4
    line 5
    line 6
    line 7
    line 8
    line 9
    line 10

    $ filterline fixtures/L fixtures/F
    line 1
    line 2
    line 5
    line 6

    $ filterline <(echo 1 2 5 6) fixtures/F
    line 1
    line 2
    line 5
    line 6

Performance
-----------

Filtering out 10 million lines from a 1 billion lines file (14G) takes about a minute:

    $ time filterline 10000000.L 1000000000.F > /dev/null
    real    0m54.523s
    user    0m37.553s
    sys     0m8.029s

A similar [awk script](https://gist.github.com/miku/bc8315b10413203b31de) takes about 2-3 times longer.
