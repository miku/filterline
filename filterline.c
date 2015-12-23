//  Copyright 2015 by Leipzig University Library, http://ub.uni-leipzig.de
//                 by The Finc Authors, http://finc.info
//                 by Martin Czygan, <martin.czygan@uni-leipzig.de>
//
// This file is part of some open source application.
//
// Some open source application is free software: you can redistribute
// it and/or modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.
//
// Some open source application is distributed in the hope that it will
// be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
//
// @license GPL-3.0+ <http://spdx.org/licenses/GPL-3.0+>
//
// filterline: filter file by line number.
// http://unix.stackexchange.com/a/209470/376
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *PROGRAM_VERSION = "0.1.3";

int main (int argc, char *argv[]) {

	FILE *L;
	FILE *F;

	unsigned int to_print;
	unsigned int current = 0;
	char *line = NULL;
	size_t len = 0;

	char *VERSION = "-v";

	if (argc == 2 && strcmp(argv[1], VERSION) == 0) {
		printf("%s\n", PROGRAM_VERSION);
		return 0;
	}

	if (argc != 3) {
		printf("Usage: %s FILE1 FILE2\n\n", argv[0]);
		printf("FILE1: line numbers (sorted, no dups, one-based), FILE2: input file\n");
		return 0;
	}

	if ((L = fopen(argv[1], "r")) == NULL) {
		return 1;
	} else if ((F = fopen(argv[2], "r")) == NULL) {
		fclose(L);
		return 1;
	} else {
		while (fscanf(L, "%u", &to_print) > 0) {
			while (getline(&line, &len, F) != -1 && ++current != to_print);
			if (current == to_print) {
				printf("%s", line);
			}
		}
		fflush(stdout);
		free(line);
		fclose(L);
		fclose(F);
		return 0;
	}
}
