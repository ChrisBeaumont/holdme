from itertools import combinations

from ..core import Card, Hand, headsup
from .._lib import allfive, enumerate_headsup, allseven


class TestCard(object):

    def test_string(self):

        def check(c):
            assert str(Card(c)) == c

        for r in '23456789TJQKA':
            for s in 'CHSD':
                c = r + s
                yield check, c

    def test_index(self):
        for i in range(52):
            c = Card.from_index(i)

    def test_bitmask(self):
        assert Card('2C').bitmask == 1
        assert Card('3C').bitmask == 2
        assert Card('AC').bitmask == 1 << 12
        assert Card('2H').bitmask == 1 << 13
        assert Card('AD').bitmask == 1 << 51

    def test_from_index(self):
        def check(i):
            assert Card.from_index(i).index == i

        for i in range(52):
            yield check, i

    def test_from_bitmask(self):
        def check(i):
            bm = Card.from_index(i).bitmask
            assert Card.from_bitmask(bm).bitmask == bm


class TestHandNames(object):

    def test_high(self):
        h = Hand('2C 3C 5C 7C 9D')
        assert h.name == 'High Card (97532)'

    def test_pair(slf):
        h = Hand('2C 2D 3H 5H 7H')
        assert h.name == 'Pair of 2s (753)'

    def test_twopair(slf):
        h = Hand('2C 2D 3H 3S 7H')
        assert h.name == 'Two Pair (3, 2 with 7 kicker)'

    def test_three(self):
        h = Hand('JC JD JH 3S 7H')
        assert h.name == 'Three Js (73)'

    def test_straight(self):
        h = Hand('2C 3C 6D 5S 4S')
        assert h.name == 'Straight (6 high)'

    def test_ace_high_straight(self):
        h = Hand('TS JS QC KC AD')
        assert h.name == 'Straight (A high)'

    def test_ace_low_straight(self):
        h = Hand('2S 3S 4C 5C AS')
        assert h.name == 'Straight (5 high)'

    def test_flush(self):
        h = Hand('9S TS AS 2S 4S')
        assert h.name == 'Flush (AT942)'

    def test_full_house(self):
        h = Hand('9S 9D 9H AH AC')
        assert h.name == 'Full House (9s full of As)'

    def test_four(self):
        h = Hand('2H 2S 2C 2D 3S')
        assert h.name == 'Four 2s (3 kicker)'

    def test_straight_flush(self):
        h = Hand('2H 3H 4H 5H 6H')
        assert h.name == 'Straight Flush (6 high)'

    def test_straight_flush_5(self):
        h = Hand('AC 2C 3C 4C 5C')
        assert h.name == 'Straight Flush (5 high)'

    def test_straight_flush_A(self):
        h = Hand('TH JH QH KH AH')
        assert h.name == 'Straight Flush (A high)'


def test_7_hands():

    def check(hand, expected):
        h = Hand(hand)
        assert h.name == expected

    yield check, '4D 5C AC 6C JH 3D 2H', 'Straight (6 high)'


def test_allfive():
    sums = allfive().tolist()
    print sums
    assert sums == [1302540, 1098240, 123552,
                    54912, 10200, 5108, 3744, 624, 40]


def test_allseven():
    sums = allseven().tolist()
    print sums
    assert sums == [23294460, 58627800, 31433400,
                    6461620, 6180020, 4047644, 3473184, 224848, 41584]


def test_headsup():

    def check(h1, h2, expected_pwin, expected_plose):
        pwin, plose = headsup(Hand(h1), Hand(h2))
        print pwin, plose
        assert abs(pwin - expected_pwin) < 1e-3
        assert abs(plose - expected_plose) < 1e-3

    yield check, 'AH AS', 'QC QD', .8069, .1896
    yield check, 'KC KD', '6H 6S', .7970, .2003
    yield check, 'TD JD', '6H 2S', .6941, .2942


def test_headsup_flop():

    def check(h1, h2, com, expected_pwin, expected_plose):
        pwin, plose = headsup(Hand(h1), Hand(h2), Hand(com))
        print pwin, plose
        assert abs(pwin - expected_pwin) < 1e-3
        assert abs(plose - expected_plose) < 1e-3

    yield check, 'AH AS', 'QC QD', 'QH QS 2D', .0010, .9990


def test_headsup_turn():

    def check(h1, h2, com, expected_pwin, expected_plose):
        pwin, plose = headsup(Hand(h1), Hand(h2), Hand(com))
        print pwin, plose
        assert abs(pwin - expected_pwin) < 1e-3
        assert abs(plose - expected_plose) < 1e-3

    yield check, 'AH AS', 'QC QD', 'QH QS 2D AC', .0227, .9773
