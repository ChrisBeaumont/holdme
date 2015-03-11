# Implementation Notes

The design of the internal data structures in holdme is motivated by need for
fast hand strength calculation. You don't need to worry about this to actually
*use* holdme, since the user-facing API is much friendlier. But if you
like these kinds of details:

## Representing Cards and Hands

Internally, we represent cards by bitmasks stored as 64-bit integers.
Each card has a single bit set:
```
   2C = 1 << 0
   3C = 1 << 1
       ⋮
   AC = 1 << 12
   2H = 1 << 13
       ⋮
   2S = 1 << 26
       ⋮
   2D = 1 << 39
```
This allows us to represent sets of cards by the bitwise OR
of the individual cards.

## Representing Hand strength

The strength of a hand is also encoded as a 32-bit integer. These integers
are such that two hands H1 and H2 tie if their scores are the same, and
H1 beats H2 if score(H1) > score(H2). While there are only 7462 distinct hand
ranks in poker, we do *not* store ranks using [0-7462]. Instead, we divide
the hand strength into 3 blocks

```
Unused | Hand Category (4 bits) | Sub category A (13 bits) | Sub B (13 bits)
```

The hand category stores the hand "type"
```
 High card: 0
 Pair: 1
     ⋮
 Straight Flush: 8
```
The two subcategories differentiate between strengths of hands of the same
type. The data they store depends on the hand type
```
     Highcard: Block B stores the rank of the 5 highest rank cards in the hand
               (where each rank is a 13-bit bitmask, ORed together)
         Pair: Block A stores the rank of the pair. Block B stores the ranks
               of the 3 highest non-paired cards
     Two Pair: Block A stores the ranks of both pairs. Block B stores the
               rank of the highest non-paired card
        Trips: Block A stores the rank of the trip. Block B stores the rank
               of the highest 2 remaining cards
     Straight: Block A stores the rank of the highest card in the straight
        Flush: Block B stores the highest 5 ranks of
   Full House: Block A stores the rank of the trips. Block B stores the rank
               of the pair
        Quads: Block A stores the rank of the quad. Block B stores the rank
               of the highest non-quad card
     St Flush: Same as straight
```
