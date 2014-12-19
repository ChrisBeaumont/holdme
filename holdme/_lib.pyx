# distutils: extra_compile_args = -fopenmp
# distutils: extra_link_args = -fopenmp

import numpy as np
import os

cimport numpy as np
cimport cython

from libc.stdlib cimport rand, RAND_MAX

from cython.parallel cimport prange

ctypedef np.int64_t INDEX_t
ctypedef np.uint16_t VALUE_t
cdef:
   INDEX = np.int64
   VALUE = np.uint16
   int NFIVE = 2598960, NSEVEN = 133784560


cpdef int score5(long c1, long c2, long c3, long c4, long c5) nogil:
    """
    Compute a score from 5 cards

    Parameters
    ----------
    c1, c2, c3, c4, c5 : ints
       The five cards, expressed in bitmask form

    Returns
    -------
    score : int
       A 32 bit integer, whose value sorts several hands by increasing strength
    """

    # each card is a bitmask with two bits set. One for the suit, one for the rank
    # [00C 00H 00S 00D 00A 00K 00Q ... 002]
    # the extra zeros allow us to aggregate ranks and suits for up to 7 cards by adding
    cdef:
        int ones=0, twos=0, threes=0, fours=0
        int i, v
        int is_flush = 0, is_straight=0, is_twopair=0
        long h = (c1 + c2 + c3 + c4 + c5), m
        long rankset = (c1 | c2 | c3 | c4 | c5) & 549755813887LL  # chop of suit buits

    # populate ones/twos/threes/fours
    # each stores a bit mask of which card ranks appear 1/2/3/4 times
    for i in range(13):
        v = (h & 7)  # number of cards of rank i
        h >>= 3
        m = 1 << i   # bitmask for rank i
        is_twopair |= (v == 2) and (twos != 0)
        ones |= m * (v == 1)
        twos |= m * (v == 2)
        threes |= m * (v == 3)
        fours |= m * (v == 4)

    # check for flush, by looking for a suit with 5 cards
    for i in range(4):
        v = (h & 7)
        h >>= 3
        is_flush |= (v == 5)

    # check for a stright
    if rankset == 4681:
        is_straight = 1 << 4
    elif rankset == 37448:
        is_straight = 1 << 5
    elif rankset == 299584:
        is_straight = 1 << 6
    elif rankset == 2396672:
        is_straight = 1 << 7
    elif rankset == 19173376:
        is_straight = 1 << 8
    elif rankset == 153387008LL:
        is_straight = 1 << 9
    elif rankset == 1227096064LL:
        is_straight = 1 << 10
    elif rankset == 9816768512LL:
        is_straight = 1 << 11
    elif rankset == 78534148096LL:
        is_straight = 1 << 12
    elif rankset == 68719477321LL:
        is_straight = 1 << 3

    if is_flush & (is_straight > 0):  # straight flush
        return (8 << 26) | is_straight
    if fours:                   # four of a kind
        return (7 << 26) | fours << 13 | ones
    if (threes != 0) & (twos != 0): # full house
        return (6 << 26) | (threes << 13) | twos
    if is_flush:
        return (5 << 26) | ones
    if is_straight:
        return (4 << 26) | is_straight
    if threes: # three of a kind
        return (3 << 26) | threes << 13 | ones
    if is_twopair: # two pair
        return (2 << 26) | twos << 13 | ones
    if twos: # pair
        return (1 << 26) | twos << 13 | ones

    return ones

cdef inline int highest(int mask, int n) nogil:
    cdef:
        int i, j=0
    for i in range(13, -1, -1):
        j += ((mask >> i) & 1)
        if j == n:
            return (mask >> i) << i

cdef inline int lowest(int mask) nogil:
    cdef:
        int i
    for i in range(13):
        if mask & (1 << i):
            return 1 << i

cdef inline int flush(long c1, long c2, long c3, long c4, long c5, long c6, long c7, int suit) nogil:
    cdef:
        int i, v
        int is_straight=0
        long rankset, ones=0, h
        long *straights = [68719477321LL, 4681, 37448, 299584, 2396672, 19173376, 153387008LL, 1227096064LL, 9816768512LL, 78534148096LL]
        long s = 1L << (3 * suit + 39)

    c1 *= ((c1 & s) > 0)
    c2 *= ((c2 & s) > 0)
    c3 *= ((c3 & s) > 0)
    c4 *= ((c4 & s) > 0)
    c5 *= ((c5 & s) > 0)
    c6 *= ((c6 & s) > 0)
    c7 *= ((c7 & s) > 0)

    h = (c1 + c2 + c3 + c4 + c5 + c6 + c7)
    rankset = (c1 | c2 | c3 | c4 | c5 | c6 | c7)

    for i in range(13):
        v = (h & 7)  # number of cards of rank i
        h >>= 3
        ones |= (v == 1) << i

    # straight flush
    for i in range(9, -1, -1):
        if ((rankset & straights[i]) == straights[i]):
            return 8 << 26 | (1 << (i + 3))
    return 5 << 26 | highest(ones, 5)


@cython.boundscheck(False)
@cython.wraparound(False)
cdef int unique(long c1, long c2, long c3, long c4, long c5, long c6, long c7, long h, long rankset) nogil:

    cdef:
        long *straights = [68719477321LL, 4681, 37448, 299584, 2396672, 19173376, 153387008LL, 1227096064LL, 9816768512LL, 78534148096LL]
        int i, ones = 0

    # straight
    for i in range(9, -1, -1):
        if ((rankset & straights[i]) == straights[i]):
            return (4 << 26) | (1 << (i + 3))


    # each stores a bit mask of which card ranks appear 1/2/3/4 times
    for i in range(13):
        v = (h & 7)  # number of cards of rank i
        h >>= 3
        ones |= (v == 1)  << i

    return highest(ones, 5)



@cython.boundscheck(False)
@cython.wraparound(False)
cpdef int score7(long c1, long c2, long c3, long c4, long c5, long c6, long c7) nogil:
    # each card is a bitmask with two bits set. One for the suit, one for the rank
    # [00C 00H 00S 00D 00A 00K 00Q ... 002]
    # the extra zeros allow us to aggregate ranks and suits for up to 7 cards by adding
    cdef:
        int ones = 0, twos = 0, threes = 0, fours = 0, notfours = 0
        int i, v, m
        int is_twopair=0, is_threepair=0, is_twotrips=0
        long h = (c1 + c2 + c3 + c4 + c5 + c6 + c7)
        long h2 = h >> 39  # suits
        long rankset = (c1 | c2 | c3 | c4 | c5 | c6 | c7)
        long *straights = [68719477321LL, 4681, 37448, 299584, 2396672, 19173376, 153387008LL, 1227096064LL, 9816768512LL, 78534148096LL]


    # check for flush, by looking for a suit with >=5 cards
    for i in range(4):
        v = (h2 & 7)
        h2 >>= 3
        if v >= 5:
            return flush(c1, c2, c3, c4, c5, c6, c7, i)

    # 7 unique cards
    if (rankset & 549755813887LL) == (h & 549755813887LL):
        return unique(c1, c2, c3, c4, c5, c6, c7, h, rankset)

    # each stores a bit mask of which card ranks appear 1/2/3/4 times
    for i in range(13):
        v = (h & 7)  # number of cards of rank i
        h >>= 3
        m = 1 << i
        is_threepair |= (v == 2) & is_twopair
        is_twotrips |= (v == 3) & (threes != 0)
        is_twopair |= (v == 2) & (twos != 0)
        ones |= (v == 1) * m
        twos |= (v == 2) * m
        threes |= (v == 3) * m
        fours |= (v == 4) * m
        notfours |= ((v != 4) & (v > 0)) * m

    # quads
    if fours:
        return (7 << 26) | (fours << 13) | highest(notfours, 1)

    # FH
    if (threes != 0) & (twos != 0): # 3 and 2
        return (6 << 26) | (threes << 13) | highest(twos, 1)
    if is_twotrips:
        return (6 << 26) | (highest(threes, 1) << 13) | lowest(threes)

    # straight
    for i in range(9, -1, -1):
        if ((rankset & straights[i]) == straights[i]):
            return (4 << 26) | (1 << (i + 3))

    # 3kind
    if threes:
        return (3 << 26) | threes << 13 | highest(ones, 2)

    # 2pair
    if is_threepair:
        return (2 << 26) | (highest(twos, 2) << 13) | highest(lowest(twos) | ones, 1)

    if is_twopair:
        return (2 << 26) | twos << 13 | highest(ones, 1)

    if twos: # pair
        return (1 << 26) | twos << 13 | highest(ones, 3)

    return highest(ones, 5)

cpdef long splitmask(int c) nogil:
    cdef:
        int suit = c / 13
        int rank = c % 13
    return (1L << (3 * rank)) + (1L << (3 * suit + 39))


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
        c1 = splitmask(i0)
        for i1 in range(i0+1, 52):
            c2 = splitmask(i1)
            for i2 in range(i1+1, 52):
                c3 = splitmask(i2)
                for i3 in range(i2+1, 52):
                    c4 = splitmask(i3)
                    for i4 in range(i3+1, 52):
                        c5 = splitmask(i4)
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


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def simulate_headsup(long m1, long m2, long o1, long o2,
                     long[:] deck, int ntrial):

    cdef:
        int i, j, k, s1, s2
        long *com = [0, 0, 0, 0, 0]
        float nwin=0, nlose=0, delta = 1.0 / ntrial

    for i in prange(ntrial, nogil=True):
        for j in range(5):
            k = <int>(rand()/(RAND_MAX / 48.0))
            com[j] = deck[k]
        s1 = score7(com[0], com[1], com[2], com[3], com[4], m1, m2)
        s2 = score7(com[0], com[1], com[2], com[3], com[4], o1, o2)
        if s1 > s2:
            nwin += delta
        if s1 < s2:
            nlose += delta
    return nwin, nlose