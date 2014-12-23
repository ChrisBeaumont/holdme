# distutils: extra_compile_args = -fopenmp
# distutils: extra_link_args = -fopenmp

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


cpdef int score5(long c1, long c2, long c3, long c4, long c5) nogil:
    return hand_eval.score5(c1, c2, c3, c4, c5)


cpdef int score7(long c1, long c2, long c3, long c4, long c5, long c6, long c7) nogil:
    return hand_eval.score7(c1, c2, c3, c4, c5, c6, c7)

@cython.boundscheck(False)
@cython.wraparound(False)
def allfive():
    result = np.zeros(2598960, dtype=np.int32)

    cdef:
        long c1, c2, c3, c4, c5
        int i0, i1, i2, i3, i4, k=0
        np.int32_t[:] _out = result
        int v

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
                        _out[k] = score5(c1, c2, c3, c4, c5)
                        k += 1
    return result


@cython.boundscheck(False)
@cython.wraparound(False)
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


@cython.cdivision(True)
@cython.boundscheck(False)
@cython.wraparound(False)
cdef void shuffle_part(long[:] deck, int n, int m) nogil:

    cdef:
        int i, j, card

    for i in range(m):
        j = i + rand() / (RAND_MAX / (n - i) + 1);
        card = deck[j]
        deck[j] = deck[i]
        deck[i] = card


@cython.boundscheck(False)
@cython.wraparound(False)
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

@cython.boundscheck(False)
@cython.wraparound(False)
def enumerate_headsup(long m1, long m2, long o1, long o2):
    deck = np.array([1L << i for i in range(52) if i not in (m1, m2, o1, o2)],
                    dtype=np.long)

    cdef:
        float nwin=0, nlose=0, delta=1.0 / 1712304
        int i1, i2, i3, i4, i5, s1, s2
        long c1, c2, c3, c4, c5
        long[:] d = deck

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
                            nwin += delta
                        if s1 < s2:
                            nlose += delta

    return nwin, nlose
