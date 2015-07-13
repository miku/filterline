#!/usr/bin/env python
#
# synthesize test data

import json
import random
import string

FILE = 20000000
LINES = 5000000

def genstring(size=3, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))

if __name__ == '__main__':
    with open("%s.ldj" % FILE, "w") as handle:
        for i in xrange(FILE):
            handle.write(json.dumps({"id": "id-%s" % random.randint(0, LINES), "name": genstring(3)}))
            handle.write("\n")
