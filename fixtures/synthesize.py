#!/usr/bin/env python
#
# synthesize test data

import random

FILE = 1000000000
LINES = 10000000

if __name__ == '__main__':
    with open("%s.F" % FILE, "w") as handle:
        for i in range(FILE):
            handle.write("line %s\n" % i)

    filename = "%s.L" % LINES
    with open(filename, "w") as handle:
        for _ in range(LINES):
            handle.write("%s\n" % random.randint(1, FILE-1))


    print('Run now: "sort -S50% -u -n -o %s %s"' % (filename, filename))
