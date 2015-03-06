## distutils: extra_compile_args = -fopenmp
## distutils: extra_link_args = -fopenmp
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True

import numpy as np
import os

cimport numpy as np
cimport cython

from libc.stdlib cimport rand, RAND_MAX

cimport hand_eval

from cython.parallel cimport prange

ctypedef np.int64_t INDEX_t
ctypedef np.uint16_t VALUE_t
cdef:
   int NFIVE = 2598960, NSEVEN = 133784560

   int HIGHCARD = 0
   int PAIR = 1 << 26
   int TWOPAIR = 2 << 26
   int TRIP = 3 << 26
   int STRAIGHT = 4 << 26
   int FLUSH  = 5 << 26
   int FULLHOUSE = 6 << 26
   int QUAD = 7 << 26
   int STRAIGHTFLUSH = 8 << 26


cdef struct Prob:
    double pwin
    double plose


cpdef int score5(long c1, long c2, long c3, long c4, long c5) nogil:
    return hand_eval.score5(c1, c2, c3, c4, c5)


cpdef int score7(long c1, long c2, long c3, long c4, long c5, long c6, long c7) nogil:
    return hand_eval.score7(c1, c2, c3, c4, c5, c6, c7)

def allfive():
    result = np.zeros(9, dtype=np.int32)

    cdef:
        long c1, c2, c3, c4, c5
        int i0, i1, i2, i3, i4
        np.int32_t[:] _out = result

    for i0 in range(52):
        c1 = 1L << (i0)
        for i1 in range(i0+1, 52):
            c2 = 1L << (i1)
            for i2 in range(i1+1, 52):
                c3 = 1L << (i2)
                for i3 in range(i2+1, 52):
                    c4 = 1L << (i3)
                    for i4 in range(i3+1, 52):
                        c5 = 1L << (i4)
                        _out[score5(c1, c2, c3, c4, c5) >> 26] += 1

    return result

def allseven():
    result = np.zeros(9, dtype=np.int32)

    cdef:
        long c1, c2, c3, c4, c5, c6, c7
        int i0, i1, i2, i3, i4, i5, i6
        np.int32_t[:] _out = result

    for i0 in range(52):
        c1 = 1L << (i0)
        for i1 in range(i0+1, 52):
            c2 = 1L << (i1)
            for i2 in range(i1+1, 52):
                c3 = 1L << (i2)
                for i3 in range(i2+1, 52):
                    c4 = 1L << (i3)
                    for i4 in range(i3+1, 52):
                        c5 = 1L << (i4)
                        for i5 in range(i4 + 1, 52):
                            c6 = 1L << (i5)
                            for i6 in range(i5 + 1, 52):
                                c7 = 1L << i6
                                _out[score7(c1, c2, c3, c4, c5, c6, c7) >> 26] += 1

    return result


cpdef int score7_from5(long c1, long c2, long c3, long c4, long c5, long c6, long c7) nogil:
    cdef:
        long tmp, result = 0
        int i, k
        long *p = [
                   c1, c2, c3, c4, c5,
                   c1, c2, c3, c4, c6,
                   c1, c2, c3, c4, c7,
                   c1, c2, c3, c5, c6,
                   c1, c2, c3, c5, c7,
                   c1, c2, c3, c6, c7,
                   c1, c2, c4, c5, c6,
                   c1, c2, c4, c5, c7,
                   c1, c2, c4, c6, c7,
                   c1, c2, c5, c6, c7,
                   c1, c3, c4, c5, c6,
                   c1, c3, c4, c5, c7,
                   c1, c3, c4, c6, c7,
                   c1, c3, c5, c6, c7,
                   c1, c4, c5, c6, c7,
                   c2, c3, c4, c5, c6,
                   c2, c3, c4, c5, c7,
                   c2, c3, c4, c6, c7,
                   c2, c3, c5, c6, c7,
                   c2, c4, c5, c6, c7,
                   c3, c4, c5, c6, c7,
                 ]
    for i in range(21):
        k = i * 5
        tmp = score5(p[k], p[k + 1], p[k + 2], p[k + 3], p[k + 4])
        if tmp > result:
            result = tmp

    return result


cdef void shuffle_part(long[:] deck, int n, int m) nogil:

    cdef:
        int i, j, card

    for i in range(m):
        j = i + rand() / (RAND_MAX / (n - i) + 1);
        card = deck[j]
        deck[j] = deck[i]
        deck[i] = card

cdef void _init_deck(long *deck, long taken) nogil:
    cdef:
       int i, j=0
       long c

    for i in range(52):
        c = 1L << i
        if (c & taken) == 0:
            deck[j] = c
            j += 1

def simulate_headsup(long m1, long m2, long o1, long o2,
                     long[:] deck, int ntrial):

    cdef:
        float nwin=0, nlose=0, delta = 1.0 / ntrial
        int i, s1, s2

    for i in range(ntrial):
        shuffle_part(deck, 48, 5)
        s1 = score7(m1, m2, deck[0], deck[1], deck[2], deck[3], deck[4])
        s2 = score7(o1, o2, deck[0], deck[1], deck[2], deck[3], deck[4])
        if s1 > s2:
            nwin += delta
        if s1 < s2:
            nlose += delta
    return nwin, nlose

cpdef Prob enumerate_headsup(long m1, long m2, long o1, long o2) nogil:

    cdef:
        int nwin=0, nlose=0
        int i1, i2, i3, i4, i5, s1, s2
        long c1, c2, c3, c4, c5
        long d[48]
        Prob result

    _init_deck(d, m1 | m2 | o1 | o2)

    for i1 in prange(48, nogil=True):
        c1 = d[i1]
        for i2 in range(i1 + 1, 48):
            c2 = d[i2]
            for i3 in range(i2 + 1, 48):
                c3 = d[i3]
                for i4 in range(i3 + 1, 48):
                    c4 = d[i4]
                    for i5 in range(i4 + 1, 48):
                        c5 = d[i5]
                        s1 = score7(m1, m2, c1, c2, c3, c4, c5)
                        s2 = score7(o1, o2, c1, c2, c3, c4, c5)
                        if s1 > s2:
                            nwin += 1
                        if s1 < s2:
                            nlose += 1
    ntot = 1712304.0
    result.pwin = nwin / ntot
    result.plose = nlose / ntot
    return result


cpdef Prob enumerate_headsup_flop(long m1, long m2, long o1, long o2, long c1, long c2, long c3) nogil:

    cdef:
        int nwin=0, nlose=0
        int i4, i5, s1, s2
        long c4, c5
        long d[45]
        Prob result

    _init_deck(d, m1 | m2 | o1 | o2 | c1 | c2 | c3)

    for i4 in prange(45, nogil=True):
        c4 = d[i4]
        for i5 in range(i4 + 1, 45):
            c5 = d[i5]
            s1 = score7(m1, m2, c1, c2, c3, c4, c5)
            s2 = score7(o1, o2, c1, c2, c3, c4, c5)
            if s1 > s2:
                nwin += 1
            if s1 < s2:
                nlose += 1
    ntot = 990.0
    result.pwin = nwin / ntot
    result.plose = nlose / ntot
    return result

cpdef Prob enumerate_headsup_turn(long m1, long m2, long o1, long o2, long c1, long c2, long c3, long c4) nogil:

    cdef:
        int nwin=0, nlose=0
        int i5, s1, s2
        long c5
        long d[44]
        Prob result

    _init_deck(d, m1 | m2 | o1 | o2 | c1 | c2 | c3 | c4)

    for i5 in prange(44, nogil=True):
        c5 = d[i5]
        s1 = score7(m1, m2, c1, c2, c3, c4, c5)
        s2 = score7(o1, o2, c1, c2, c3, c4, c5)
        if s1 > s2:
            nwin += 1
        if s1 < s2:
            nlose += 1

    ntot = 44.0
    result.pwin = nwin / ntot
    result.plose = nlose / ntot
    return result

def all_headsup():
    result = np.zeros((52, 52, 52, 52), dtype=np.float)

    cdef:
        int i1, i2, j1, j2
        long c1, c2, c3, c4
        double[:, :, :, :] win_minus_lose = result
        Prob p

    for i1 in range(52):
        print i1
        c1 = 1L << i1
        for i2 in range(i1 + 1, 52):
            c2 = 1L << i2
            for j1 in range(52):
                if j1 == i1 or j1 == i2:
                    continue
                c3 = 1L << j1
                for j2 in range(j1 + 1, 52):
                    if j2 == i1 or j2 == i2:
                        continue
                    c4 = 1L << j2
                    p = enumerate_headsup(c1, c2, c3, c4)
                    win_minus_lose[i1, i2, j1, j2] = p.pwin - p.plose
                    win_minus_lose[i2, i1, j1, j2] = p.pwin - p.plose
                    win_minus_lose[i1, i2, j2, j1] = p.pwin - p.plose
                    win_minus_lose[i2, i1, j2, j1] = p.pwin - p.plose

    return result


