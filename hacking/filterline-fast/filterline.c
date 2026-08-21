// filterline: filter file by line number.
//
// Experimental rewrite of ../../filterline.c that never copies line data.
// The released version calls getline() for every line of F, which memcpy's
// each line out of the stdio buffer -- including the lines that are then
// discarded. Here the read buffer is scanned with memchr and kept bytes are
// written straight out of that buffer, so skipped input costs a scan and
// nothing else. Output bypasses stdio entirely.
//
// Measured 3-6.5x faster than v0.1.7 on 960MB / 20M lines, and lands on the
// floor for the problem (a bare memchr scan of the same file costs the same
// user time). Numbers, method and validation matrix: notes/2026-08-21-perf.md
//
// Verified byte-identical to v0.1.7 except on duplicate/unsorted L, which the
// released version handles by silently truncating the rest of the output and
// this version tolerates.
//
// @license GPL-3.0+ <http://spdx.org/licenses/GPL-3.0+>

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef IN_CAP
#define IN_CAP (1u << 20)
#endif
#ifndef OUT_CAP
#define OUT_CAP (1u << 20)
#endif

static const char *PROGRAM_VERSION = "0.2.0";

// ---------------------------------------------------------------- output ---

static unsigned char *obuf;
static size_t olen;

static void write_all(const unsigned char *p, size_t n) {
  while (n) {
    ssize_t w = write(STDOUT_FILENO, p, n);
    if (w < 0) {
      if (errno == EINTR)
        continue;
      perror("filterline: write");
      exit(1);
    }
    p += w;
    n -= (size_t)w;
  }
}

static void oflush(void) {
  if (olen) {
    write_all(obuf, olen);
    olen = 0;
  }
}

static void oput(const unsigned char *p, size_t n) {
  if (n >= OUT_CAP / 2) { // big span: hand it straight to the kernel
    oflush();
    write_all(p, n);
    return;
  }
  if (olen + n > OUT_CAP)
    oflush();
  memcpy(obuf + olen, p, n);
  olen += n;
}

// ----------------------------------------------------------------- input ---

typedef struct {
  int fd;
  unsigned char *buf;
  size_t pos, end;
  int partial; // consumed bytes not yet terminated by '\n'
} rdr;

static int refill(rdr *r) {
  r->pos = r->end = 0;
  for (;;) {
    ssize_t n = read(r->fd, r->buf, IN_CAP);
    if (n > 0) {
      r->end = (size_t)n;
      return 1;
    }
    if (n == 0)
      return 0;
    if (errno == EINTR)
      continue;
    perror("filterline: read");
    exit(1);
  }
}

// Consume up to n lines; emit them to stdout if emit != 0.
// Returns the number of lines actually consumed (< n means EOF).
static uint64_t consume_lines(rdr *r, uint64_t n, int emit) {
  uint64_t done = 0;
  while (done < n) {
    if (r->pos == r->end) {
      if (!refill(r)) {
        if (r->partial) { // final line without trailing newline
          r->partial = 0;
          done++;
        }
        break;
      }
    }
    const unsigned char *base = r->buf + r->pos;
    size_t avail = r->end - r->pos;
    uint64_t need = n - done;
    size_t take;

    // Walk at most `need` newlines, stopping early if the chunk runs out.
    // Single pass: never scans past what the run actually needs.
    const unsigned char *p = base, *e = base + avail;
    uint64_t found = 0;
    while (found < need) {
      const unsigned char *nl =
          (const unsigned char *)memchr(p, '\n', (size_t)(e - p));
      if (!nl)
        break;
      p = nl + 1;
      found++;
    }
    if (found == need) { // run ends inside this chunk
      take = (size_t)(p - base);
      done = n;
      r->partial = 0;
    } else { // whole chunk belongs to the run
      take = avail;
      done += found;
      r->partial = (base[avail - 1] != '\n');
    }
    if (emit)
      oput(base, take);
    r->pos += take;
  }
  return done;
}

static void emit_rest(rdr *r) {
  for (;;) {
    if (r->pos == r->end && !refill(r))
      return;
    oput(r->buf + r->pos, r->end - r->pos);
    r->pos = r->end;
  }
}

static int read_num(rdr *r, uint64_t *out) {
  uint64_t v = 0;
  int have = 0;
  for (;;) {
    if (r->pos == r->end && !refill(r)) {
      if (have)
        *out = v;
      return have;
    }
    unsigned char c = r->buf[r->pos++];
    if (c >= '0' && c <= '9') {
      v = v * 10 + (uint64_t)(c - '0');
      have = 1;
    } else if (have) {
      *out = v;
      return 1;
    }
  }
}

// ------------------------------------------------------------------ main ---

int main(int argc, const char *argv[]) {
  int invert = 0;

  if (argc == 2 && strcmp(argv[1], "-V") == 0) {
    printf("%s\n", PROGRAM_VERSION);
    return 0;
  }
  if (argc != 3 && argc != 4) {
    fprintf(stderr, "Usage: %s [-v] FILE1 FILE2\n", argv[0]);
    return 2;
  }
  const char *lfile = argv[1], *ffile = argv[2];
  if (argc == 4) {
    if (strcmp(argv[1], "-v") != 0) {
      fprintf(stderr, "Usage: %s [-v] FILE1 FILE2\n", argv[0]);
      return 2;
    }
    invert = 1;
    lfile = argv[2];
    ffile = argv[3];
  }

  rdr L = {0}, F = {0};
  if ((L.fd = open(lfile, O_RDONLY)) < 0) {
    perror(lfile);
    return 1;
  }
  if ((F.fd = open(ffile, O_RDONLY)) < 0) {
    perror(ffile);
    return 1;
  }
#ifdef F_RDAHEAD
  fcntl(F.fd, F_RDAHEAD, 1);
#endif
  L.buf = malloc(IN_CAP);
  F.buf = malloc(IN_CAP);
  obuf = malloc(OUT_CAP);
  if (!L.buf || !F.buf || !obuf) {
    fprintf(stderr, "filterline: out of memory\n");
    return 1;
  }

  uint64_t current = 0, target;
  if (!invert) {
    while (read_num(&L, &target)) {
      if (target <= current)
        continue; // tolerate dups / unsorted
      if (consume_lines(&F, target - current - 1, 0) != target - current - 1)
        break;
      current = target - 1;
      if (consume_lines(&F, 1, 1) != 1)
        break;
      current = target;
    }
  } else {
    while (read_num(&L, &target)) {
      if (target <= current)
        continue;
      uint64_t keep = target - current - 1;
      if (consume_lines(&F, keep, 1) != keep)
        break;
      current = target - 1;
      if (consume_lines(&F, 1, 0) != 1)
        break;
      current = target;
    }
    emit_rest(&F);
  }
  oflush();
  return 0;
}
