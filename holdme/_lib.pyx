# distutils: extra_compile_args = -fopenmp
# distutils: extra_link_args = -fopenmp

import numpy as np
import os

cimport numpy as np
cimport cython

from cython.parallel cimport prange

ctypedef np.int64_t INDEX_t
ctypedef np.uint16_t VALUE_t
cdef:
   INDEX = np.int64
   VALUE = np.uint16
   int NFIVE = 2598960, NSEVEN = 133784560

_hand5 = _score5 = _hand7 = _score7 = None

def _load5():
    global _hand5, _score5
    if _hand5 is None:
        data_pth = '/Users/beaumont/knish/knish/hand5.npz'
        data = np.load(data_pth)
        _hand5, _score5 = data['key'], data['val']

    return _hand5, _score5


def _load7():
    global _hand7, _score7
    if _hand7 is None:
        data_pth = '/Users/beaumont/knish/knish/hand7.npz'
        data = np.load(data_pth)
        _hand7, _score7 = data['key'], data['val']

    return _hand7, _score7


@cython.boundscheck(False)
@cython.wraparound(False)
cdef int bsearch(INDEX_t v, INDEX_t[:] a, int n) nogil:
    cdef int i = 0, lo=0, hi=n - 1

    if a[hi] == v:
        return hi

    # a[lo] <= v < a[hi]
    while(hi - lo) > 1:
        mid = (hi + lo) >> 1
        if a[mid] <= v:
            lo = mid
        else:
            hi = mid

    return lo

@cython.boundscheck(False)
@cython.wraparound(False)
cdef _score(INDEX_t[:] hands, VALUE_t[:] out,
            INDEX_t[:] all_hands, VALUE_t[:] all_scores):

    cdef:
        int n = all_hands.size, nhand = hands.size, i=0

    for i in prange(nhand, nogil=True):
        out[i] = all_scores[bsearch(hands[i], all_hands, n)]


def _score5_lookup(INDEX_t[:] hands,
           VALUE_t[:] out):

    _hand5, _score5 = _load5()

    cdef:
        INDEX_t[:] keys = _hand5
        VALUE_t[:] scores = _score5

    _score(hands, out, keys, scores)
    return out


cdef int score(long c1, long c2, long c3, long c4, long c5):
    # each card is a bitmask with two bits set. One for the suit, one for the rank
    # [00C 00H 00S 00D 00A 00K 00Q ... 002]
    # the extra zeros allow us to aggregate ranks and suits for up to 7 cards by adding
    cdef:
        int ones=0, twos=0, threes=0, fours=0, i, v
        int is_flush, is_straight, is_twopair
        long h = (c1 + c2 + c3 + c4 + c5), m
        long rankset = (c1 | c2 | c3 | c4 | c5) & 549755813887LL  # chop of suit buits

    # populate ones/twos/threes/fours
    # each stores a bit mask of which card ranks appear 1/2/3/4 times
    for i in range(14):
        v = (h & 7)  # number of cards of rank i
        h >>= 3
        m = 1 << i   # bitmask for rank i
        if v == 0:
            continue
        elif v == 1:
            ones |= m
        elif v == 2:
            is_twopair = twos != 0
            twos |= m
        elif v == 3:
            threes |= m
        else: # v == 4
            fours |= m

    # check for flush, by looking for a suit with 5 cards
    for i in range(4):
        v = (h & 7)
        h >>= 3
        is_flush |= (v == 5)

    # check for a stright
    is_straight = ((rankset == 4681) or
                   (rankset == 37448) or
                   (rankset == 299584) or
                   (rankset == 2396672) or
                   (rankset == 19173376) or
                   (rankset == 153387008LL) or
                   (rankset == 1227096064LL) or
                   (rankset == 9816768512LL) or
                   (rankset == 78534148096LL) or
                   (rankset == 68719477321LL))

    if is_flush & is_straight:  # straight flush
        return (8 << 26) | ones
    if fours:                   # four of a kind
        return (7 << 26) | fours
    if (threes != 0) & (twos != 0): # full house
        return (6 << 26) | (threes << 13) | twos
    if is_flush: # flush
        return (5 << 26) | ones
    if is_straight: #straight
        return (4 << 26) | ones
    if threes: # three of a kind
        return (3 << 26) | threes << 13 | ones
    if is_twopair: # two pair
        return (2 << 26) | twos << 13 | ones
    if twos: # pair
        return (1 << 26) | twos << 13 | ones

    return ones


cdef long convert(int c):
    #XXX doesn't deal with aces right
    cdef:
        int suit = (c % 52) % 14
        int rank = (c % 52) / 14
    return 1L << (3 * rank) + (1L << (3 * suit + 39))

def test():
    cdef:
        long c1, c2, c3, c4, c5
        int i0, i1, i2, i3, i4
        int v

    t0 = time()
    for i0 in range(52):
        c1 = convert(i0)
        for i1 in range(i0+1, 52):
            c2 = convert(i1)
            for i2 in range(i1+1, 52):
                c3 = convert(i2)
                for i3 in range(i2+1, 52):
                    c4 = convert(i3)
                    for i4 in range(i3+1, 52):
                        c5 = convert(i4)
                        v = score(c1, c2, c3, c4, c5)
    print time() - t0, v


def score7(INDEX_t[:] hands,
           out=None):

    _hand7, _score7 = _load7()

    if out is None:
        out = np.zeros(hands.size, dtype=VALUE)

    cdef:
        INDEX_t[:] keys = _hand7
        VALUE_t[:] scores = _score7
        VALUE_t[:] _out = out

    _score(hands, _out, keys, scores)
    return out


@cython.boundscheck(False)
@cython.wraparound(False)
cdef VALUE_t _score7_from_5(INDEX_t c1, INDEX_t c2, INDEX_t c3,
                     INDEX_t c4, INDEX_t c5, INDEX_t c6, INDEX_t c7,
                     INDEX_t[:] hand5,
                     VALUE_t[:] score5,
                     int n) nogil:

    cdef:
        VALUE_t result = 0, tmp = 0
        int i = 0

        INDEX_t *hands = [
                          c1 | c2 | c3 | c4 | c5,
                          c1 | c2 | c3 | c4 | c6,
                          c1 | c2 | c3 | c4 | c7,
                          c1 | c2 | c3 | c5 | c6,
                          c1 | c2 | c3 | c5 | c7,
                          c1 | c2 | c3 | c6 | c7,
                          c1 | c2 | c4 | c5 | c6,
                          c1 | c2 | c4 | c5 | c7,
                          c1 | c2 | c4 | c6 | c7,
                          c1 | c2 | c5 | c6 | c7,
                          c1 | c3 | c4 | c5 | c6,
                          c1 | c3 | c4 | c5 | c7,
                          c1 | c3 | c4 | c6 | c7,
                          c1 | c3 | c5 | c6 | c7,
                          c1 | c4 | c5 | c6 | c7,
                          c2 | c3 | c4 | c5 | c6,
                          c2 | c3 | c4 | c5 | c7,
                          c2 | c3 | c4 | c6 | c7,
                          c2 | c3 | c5 | c6 | c7,
                          c2 | c4 | c5 | c6 | c7,
                          c3 | c4 | c5 | c6 | c7
                          ]

    for i in range(21):
        tmp = score5[bsearch(hands[i], hand5, n)]
        if tmp > result:
            result = tmp

    return result

@cython.boundscheck(False)
@cython.wraparound(False)
def all7():
    _hand5, _score5 = _load5()

    cdef:
        int NHAND = 133784560, i1, i2, i3, i4, i5, i6, i7, i=0
        long c1, c2, c3, c4, c5, c6, c7
        VALUE_t[:] scores = np.zeros(NHAND, dtype=VALUE)
        INDEX_t[:] hands = np.zeros(NHAND, dtype=INDEX)

        INDEX_t[:] hand_db = _hand5
        VALUE_t[:] score_db = _score5
        int n = hand_db.size

    for i1 in range(52):
        print i1
        c1 = 1L << i1
        for i2 in range(i1 + 1, 52):
            c2 = 1L << i2
            for i3 in range(i2 + 1, 52):
                c3 = 1L << i3
                for i4 in range(i3 + 1, 52):
                    c4 = 1L << i4
                    for i5 in range(i4 + 1, 52):
                        c5 = 1L << i5
                        for i6 in range(i5 + 1, 52):
                            c6 = 1L << i6
                            for i7 in range(i6 + 1, 52):
                                c7 = 1L << i7
                                hands[i] = (c1 | c2 | c3 | c4 | c5 | c6 | c7)
                                scores[i] = _score7_from_5(c1, c2, c3, c4, c5, c6, c7, hand_db, score_db, n)
                                i += 1

    return hands, scores


cdef all_deals(INDEX_t[:] deck, int n):
    deck = np.sort(deck)
