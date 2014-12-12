from functools import reduce
from itertools import combinations
from operator import or_
from collections import Counter

import numpy as np

HIGH, PAIR, TWOPAIR, THREE, STRAIGHT, FLUSH, FULLHOUSE, FOUR, STRAIGHTFLUSH = range(9)

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
    ranks, suits = zip(*cards)

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


def card_idx(card):
    rank, suit = card
    index = rank - 2 + suit * 13
    return 1 << index


def hand_idx(hand):
    return reduce(or_, map(card_idx, hand))


def allfive():
    deck = [(r, s) for r in range(2, 15) for s in range(4)]
    hands = list(combinations(deck, 5))

    idxs = np.array([hand_idx(h) for h in hands])
    hand_val = np.zeros(idxs.shape, dtype=object)
    hand_val[:] = [hand_value(h) for h in hands]  # prevent from unpacking tuple sets

    # convert hand value into shorts
    _, hand_val = np.unique(hand_val, return_inverse=True)
    hand_val = hand_val.astype(np.uint16)

    # sort by hand idx
    ind = np.argsort(idxs)
    return idxs[ind], hand_val[ind]


def build_index():
    k, v = allfive()
    np.savez_compressed('hand5.npz', key=k, val=v)

if __name__ == "__main__":
    build_index()
