README
======

filterline filters a file by line numbers.

Taken from [here](http://unix.stackexchange.com/questions/209404/filter-file-by-line-number). There's an [awk version](https://gist.github.com/miku/bc8315b10413203b31de), too.

Installation: Clone and make or [packages](https://github.com/miku/filterline/releases).

Line numbers must be sorted.

Usage:

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
