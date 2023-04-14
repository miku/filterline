# README

filterline filters a file by line numbers.

Taken from [here](http://unix.stackexchange.com/questions/209404/filter-file-by-line-number). There's an [awk version](https://gist.github.com/miku/bc8315b10413203b31de), too.

## Installation

There are deb and rpm [packages](https://github.com/miku/filterline/releases).

To build from source:

    $ git clone https://github.com/miku/filterline.git
    $ cd filterline
    $ make

## Usage

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

Since 0.1.4, there is an `-v` flag to "invert" matches.

    $ filterline -v <(echo 1 2 5 6) fixtures/F
    line 3
    line 4
    line 7
    line 8
    line 9
    line 10

## Performance

Filtering out 10 million lines from a 1 billion lines file (14G) takes about 33
seconds (dropped caches, i7-2620M):

    $ time filterline 10000000.L 1000000000.F > /dev/null
    real    0m33.434s
    user    0m25.334s
    sys     0m5.920s

A similar [awk script](https://gist.github.com/miku/bc8315b10413203b31de) takes about 2-3 times longer.

## Use case: data compaction

One use case for such a filter is *data compaction*. Imagine that you harvest
an API every day and you keep the JSON responses in a log.

What is a log?

> A log is perhaps the simplest possible storage abstraction. It is an
  **append-only**, totally-ordered sequence of records ordered by time.

From: [The Log: What every software engineer should know about real-time data's unifying abstraction](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)

For simplicity let's think of the log as a *file*. So everytime you harvest
the API, you just *append* to a file:

```sh
$ cat harvest-2015-06-01.ldj >> log.ldj
$ cat harvest-2015-06-02.ldj >> log.ldj
...
```

The API responses can contain entries that are *new* and entries which
represent *updates*. If you want to answer the question:

> What is the current state of each record?

... you would have to find the most recent version of each record in that log file. A
typical solution would be to switch from a file to a database of sorts and do
some kind of
[upsert](https://wiki.postgresql.org/wiki/UPSERT#.22UPSERT.22_definition).

But how about logs with 100M, 500M or billions of records? And what if you do
not want to run extra component, like a database?

You can make this process a shell one-liner, and a reasonably fast one, too.

## Data point: Crossref Snapshot

[Crossref](https://en.wikipedia.org/wiki/Crossref) hosts a constantly evolving
index of scholarly metadata, available via
[API](https://www.crossref.org/documentation/retrieve-metadata/rest-api/). We
use `filterline` to turn a sequence of hundreds of daily api updates into a
single snapshot, via
[span-crossref-snapshot](https://github.com/miku/span/blob/master/cmd/span-crossref-snapshot/main.go)
(more
[details](https://github.com/datasets/awesome-data/issues/284#issuecomment-405089255)):

```shell
$ filterline L <(zstd -d -c -T0 data.ndj.zst) | zstd -c -T0 > snapshot.ndj.zst

             ^                  ^                             ^
             |                  |                             |
       lines to keep       ~4B+ messages, 1T+             latest versions, ~140M
```

Crunching through ~4B messages takes about 65 minutes, about 1M messages/s.

> Look, ma, just [files](http://www.catb.org/~esr/writings/taoup/html/ch01s06.html).

