from collections import namedtuple, Counter
from itertools import combinations

import numpy as np

from . import _lib

HIGH, PAIR, TWOPAIR, THREE, STRAIGHT, FLUSH, FULLHOUSE, FOUR, STRAIGHTFLUSH = range(9)

RANKS = '23456789TJQKA'
SUITS = 'CHSD'


class Card(object):

    def __init__(self, name):
        r, s = name.upper()
        self._index = RANKS.index(r) + SUITS.index(s) * 13

    @property
    def index(self):
        return self._index

    @property
    def bitmask(self):
        return 1 << self._index

    @property
    def rank(self):
        return self._index % 13

    @property
    def suit(self):
        return self._index // 13

    def __str__(self):
        return RANKS[self.rank] + SUITS[self.suit]

    def __repr__(self):
        return "Card(%s)" % self

    @classmethod
    def from_index(cls, i):
        return cls(RANKS[i % 13] + SUITS[i // 13])

    @classmethod
    def from_bitmask(cls, b):
        for i in range(52):
            if b & 1:
                return cls.from_index(i)
            b >>= 1


class Hand(object):

    def __init__(self, name=''):
        self._cards = [Card(n) for n in name.split()]

    @property
    def rank(self):
        if len(self._cards) == 5:
            return _lib.score5(*(c.bitmask for c in self._cards))
        return _lib.score7(*(c.bitmask for c in self._cards))

    @property
    def name(self):
        return hand_name(self.rank)

    @property
    def cards(self):
        return self._cards

    def __len__(self):
        return len(self._cards)


def _mask2rank(mask):
    result = []
    for r in RANKS:
        if (mask & 1):
            result.append(r)
        mask >>= 1
    return ''.join(result[::-1])


def deck():
    return [Card.from_index(i) for i in range(52)]


def hand_name(score):

    tid = score >> 26
    b1 = _mask2rank((score >> 13) & ((1 << 13) - 1))
    b2 = _mask2rank(score & ((1 << 13) - 1))

    if tid == 0:  # PAIR
        return "High Card (%s)" % b2
    if tid == 1:
        return "Pair of %ss (%s)" % (b1, b2)
    if tid == 2:
        return "Two Pair (%s with %s kicker)" % (', '.join(b1), b2)
    if tid == 3:
        return "Three %ss (%s)" % (b1, b2)
    if tid == 4:
        return "Straight (%s high)" % b2[0]
    if tid == 5:
        return "Flush (%s)" % b2
    if tid == 6:
        return "Full House (%ss full of %ss)" % (b1, b2)
    if tid == 7:
        return "Four %ss (%s kicker)" % (b1, b2)
    if tid == 8:
        return "Straight Flush (%s high)" % b2[0]


def headsup(h1, h2, community=None):
    community = community or Hand()
    args = [c.bitmask for h in [h1, h2, community] for c in h._cards]
    if len(community) == 0:
        result = _lib.enumerate_headsup(*args)
    elif len(community) == 3:
        result = _lib.enumerate_headsup_flop(*args)
    elif len(community) == 4:
        result = _lib.enumerate_headsup_turn(*args)

    return result['pwin'], result['plose']
