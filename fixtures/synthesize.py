#!/usr/bin/env python
#
# synthesize test data

import random

FILE = 1000000000
LINES = 10000000

if __name__ == '__main__':
    with open("%s.F" % FILE, "w") as handle:
	for i in xrange(FILE):
	    handle.write("line %s\n" % i)

    filename = "%s.L" % LINES
    with open(filename, "w") as handle:
	for _ in xrange(LINES):
	    handle.write("%s\n" % random.randint(1, FILE-1))


    print('Run now: "sort -n -o %s %s"' % (filename, filename))
