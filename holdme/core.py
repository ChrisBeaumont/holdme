from collections import namedtuple, Counter
from itertools import combinations

import numpy as np

from ._lib import score7

HIGH, PAIR, TWOPAIR, THREE, STRAIGHT, FLUSH, FULLHOUSE, FOUR, STRAIGHTFLUSH = range(9)


class Card(namedtuple('card', 'rank suit')):
    _ranks = [None, None, '2', '3', '4', '5', '6', '7', '8', '9',
              'T', 'J', 'Q', 'K', 'A']
    _suits = ['C', 'H', 'S', 'D']

    @property
    def index(self):
        return (self.rank - 2) + self.suit * 13

    def __str__(self):
        return "%s%s" % (self._ranks[self.rank], self._suits[self.suit])

    def __hash__(self):
        return 1 << self.index

    @classmethod
    def from_index(cls, idx):
        rank = idx % 13 + 2
        suit = idx / 13
        return cls(rank, suit)

    @classmethod
    def from_name(cls, *names):
        rank, suit = cls._ranks, cls._suits
        return [cls(rank.index(r), suit.index(s)) for r, s in names]

"""
5 card hand identifiers

Each function returns None if the cards do not satisfy the particular hand
Otherwise, each function returns a list of tuples. Sorting several
outputs from a given function orders the inputs from weakest to strongest.
"""


def pair(ranks, suits):
    c = Counter(ranks)
    top = c.most_common(4)
    if len(top) == 4 and top[0][1] == 2 and top[1][1] == 1:
        return top[0][0], tuple(sorted(t[0] for t in top[1:])[::-1])


def twopair(ranks, suits):
    c = Counter(ranks)
    top = c.most_common(3)
    if len(top) == 3 and top[0][1] == 2 and top[1][1] == 2 and top[2][1] == 1:
        return top[0][0], top[1][0], top[2][0]


def three(ranks, suits):
    c = Counter(ranks)
    top = c.most_common(3)
    if len(top) == 4 and top[0][1] == 2 and top[1][1] == 1:
        return top[0][0], tuple(sorted(t[0] for t in top[1:])[::-1])


def four(ranks, suits):
    c = Counter(ranks)
    top = c.most_common(2)
    if len(top) == 2 and top[0][1] == 4 and top[1][1] == 1:
        return top[0][0], top[1][0]


def fullhouse(ranks, suits):
    c = Counter(ranks)
    top = c.most_common(3)
    if len(top) >= 2 and (top[0][1] == 3 and top[1][1] == 2 and (len(top) < 3 or top[2][1] == 1)):
        return top[0][0], top[1][0]


def straight(ranks, suits):
    straights = {frozenset((2, 3, 4, 5, 6)): 6,
                 frozenset((3, 4, 5, 6, 7)): 7,
                 frozenset((4, 5, 6, 7, 8)): 8,
                 frozenset((5, 6, 7, 8, 9)): 9,
                 frozenset((6, 7, 8, 9, 10)): 10,
                 frozenset((7, 8, 9, 10, 11)): 11,
                 frozenset((8, 9, 10, 11, 12)): 12,
                 frozenset((9, 10, 11, 12, 13)): 13,
                 frozenset((10, 11, 12, 13, 14)): 14,
                 frozenset((14, 2, 3, 4, 5)): 5
                 }
    return straights.get(frozenset(ranks))


def flush(ranks, suits):
    if all(s == suits[0] for s in suits):
        return tuple(sorted(ranks)[::-1])


def highcard(ranks, suits):
    return tuple(sorted(ranks)[::-1])


def straightflush(ranks, suits):
    if flush(ranks, suits):
        return straight(ranks, suits)


def hand_value(cards):
    ranks = [c.rank for c in cards]
    suits = [c.suit for c in cards]

    for handval, ishand in ((STRAIGHTFLUSH, straightflush),
                            (FOUR, four),
                            (FULLHOUSE, fullhouse),
                            (FLUSH, flush),
                            (STRAIGHT, straight),
                            (THREE, three),
                            (TWOPAIR, twopair),
                            (PAIR, pair),
                            (HIGH, highcard)):
        x = ishand(ranks, suits)
        if x:
            return handval, x


def allfive():
    deck = [(r, s) for r in range(2, 15) for s in range(4)]
    return {cards: hand_value(*zip(*cards)) for cards in combinations(deck, 5)}


def deck():
    return [Card.from_index(i) for i in range(52)]


def preflop_prob(c1, c2, o1, o2):
    """
    Given your pocket cards c1, c2 and an opponents' o1, o2,
    compute the win, tie, and lose probability

    Parameters
    ----------
    c1 : Card
    c2 : Card
    o1 : Card
    o2 : Card

    Returns
    -------
    pwin, ptie, plose
    """
    holecards = set((c1, c2, o1, o2))
    cards = [hash(d) for d in deck() if d not in holecards]

    communities = np.array([sum(c) for c in combinations(cards, 5)],
                           dtype=np.int64)

    me = communities | (hash(c1) | hash(c2))
    you = communities | (hash(o1) | hash(o2))

    me = score7(me)
    you = score7(you)

    pwin = (me > you).mean()
    plose = (me < you).mean()
    ptie = 1 - pwin - plose

    return pwin, ptie, plose


# from time import time
# t0 = time()
# hands = allfive()
# print time() - t0
