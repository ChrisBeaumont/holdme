from . import _lib

(HIGH, PAIR, TWOPAIR, THREE, STRAIGHT,
 FLUSH, FULLHOUSE, FOUR, STRAIGHTFLUSH) = range(9)

RANKS = '23456789TJQKA'
SUITS = 'CHSD'


class Card(object):

    def __init__(self, name):
        """
        Parameters
        ----------
        name : str
           A string like 'Ac', 'Td', or '2s', naming the rank and suit
        """
        r, s = name.upper()
        self._index = RANKS.index(r) + SUITS.index(s) * 13

    @property
    def index(self):
        # A number between [0-51] identifying the card
        return self._index

    @property
    def bitmask(self):
        # A bitmask of the index
        return 1 << self._index

    @property
    def rank(self):
        # The rank of the card, as a number [0-12]. A=12
        return self._index % 13

    @property
    def suit(self):
        # The suit of the card, as a number [0, 3]
        return self._index // 13

    def __str__(self):
        return RANKS[self.rank] + SUITS[self.suit]

    def __repr__(self):
        return "Card(%s)" % self

    @classmethod
    def from_index(cls, i):
        """
        Make a new card from an index [0-51]
        """
        return cls(RANKS[i % 13] + SUITS[i // 13])

    @classmethod
    def from_bitmask(cls, b):
        """
        Make a new card from a bitmask.
        """
        for i in range(52):
            if b & 1:
                return cls.from_index(i)
            b >>= 1


class Hand(object):

    def __init__(self, name=''):
        """
        Parameters
        ----------
        name : str or list of cards

            If str, a space-delimited sequence
            of card names (see Card class)

        Examples
        --------

        hand = Hand('2c 3d 4s Tc Qd')
        hand = Hand([Card('2C'), Card('4D')])
        """
        self._cards = name
        if isinstance(self._cards, str):
            self._cards = [Card(n) for n in name.split()]

    @property
    def rank(self):
        """
        If hand has 5 or 7 cards, the strength of the hand.

        Returns
        -------
        strength : int
           A number. Sorting hands by increasing rank arranges
           them from weakest to strongest

        Note
        ----
        This method does not check that a given hand is valid (ie contains
        no duplicate cards)
        """
        if len(self._cards) == 5:
            return _lib.score5(*(c.bitmask for c in self._cards))
        elif len(self._cards) == 7:
            return _lib.score7(*(c.bitmask for c in self._cards))
        raise ValueError("Can only compute hand strength for "
                         "5 or 7 card hands")

    @property
    def name(self):
        """
        The name of a hand, like "Full House (3s and 5s)"
        """
        return hand_name(self.rank)

    @property
    def cards(self):
        return self._cards

    def __len__(self):
        return len(self._cards)

    def __str__(self):
        return "Hand('%s')" % (' '.join(str(c) for c in self._cards))

    def __add__(self, other):
        """
        Adding Hands to cards or hands produces a new hand with the
        union of cards
        """
        if isinstance(other, Hand):
            return Hand(self.cards + other.cards)
        elif isinstance(other, Card):
            return Hand(self.cards + [other])
        else:
            raise TypeError("Can only add Hand or Card to Hand")

    __repr__ = __str__


def _mask2rank(mask):
    result = []
    for r in RANKS:
        if (mask & 1):
            result.append(r)
        mask >>= 1
    return ''.join(result[::-1])


def deck():
    """
    Return a list of all 52 Card instances
    """
    return [Card.from_index(i) for i in range(52)]


def hand_name(score):
    """
    Convert holdme's internal hand rank to a human-readable name
    """
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
    """
    Compute the probability that Hand 1 beats/loses to Hand 2 by
    enumerating over all holdem games

    Parameters
    ----------
    h1 : Hand
       The first hand
    h2 : Hand
       The second hand
    community : Hand (optional)
       Any previously dealt community cards

    Returns
    -------
    pwin, plose : (float, float)
       The probability that h1 beats/loses to h2
    """
    community = community or Hand()
    args = [c.bitmask for h in [h1, h2, community] for c in h._cards]
    if len(community) == 0:
        result = _lib.enumerate_headsup(*args)
    elif len(community) == 3:
        result = _lib.enumerate_headsup_flop(*args)
    elif len(community) == 4:
        result = _lib.enumerate_headsup_turn(*args)
    else:
        s1 = _lib.score7(*[c.bitmask for h in [h1, community]
                         for c in h._cards])
        s2 = _lib.score7(*[c.bitmask for h in [h2, community]
                         for c in h._cards])
        return float(s1 > s2), float(s1 < s2)

    return result['pwin'], result['plose']
