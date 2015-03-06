#include "tables.h"
#include "hand_eval.h"
#include <stdio.h>

int score5(card_t c1, card_t c2, card_t c3, card_t c4, card_t c5) {
    int ones = 0, twos = 0, threes = 0, fours = 0;
    int s;

    card_t hand = c1 | c2 | c3 | c4 | c5;

    // build rankmask for each suit
    int hearts = hand & 8191;
    int clubs = (hand >> 13) & 8191;
    int diamonds = (hand >> 26) & 8191;
    int spades = hand >> 39;
    int rankmask = hearts | clubs | diamonds | spades;

    // count the number of cards of each suit
    int nhearts = nbits[hearts];
    int nspades = nbits[spades];
    int nclubs = nbits[clubs];
    int ndiamonds = nbits[diamonds];

    // if a hand has a flush, the best hand is a flush or straight flush
    // lookup the result
    if (nhearts >= 5)
        return flush[hearts];
    else if (nspades >= 5)
        return flush[spades];
    else if (nclubs >= 5)
        return flush[clubs];
    else if (ndiamonds >= 5)
        return flush[diamonds];

    if (nbits[rankmask] == 5)
        return unique[rankmask];

    fours = (hearts & clubs & diamonds & spades);
    threes = (( clubs & diamonds )|( hearts & spades )) & (( clubs & hearts )|( diamonds & spades ));
    twos = rankmask ^ (hearts ^ clubs ^ diamonds ^ spades);
    ones = rankmask & (~(twos | threes | fours));

    if (fours)
        return QUAD | fours << 13 | ones;

    if ((threes > 0) & (twos > 0))
        return FULLHOUSE | threes << 13 | twos;

    s = straight[rankmask];
    if (s)
        return STRAIGHT | s;

    if (threes) {
        return TRIP | threes << 13 | ones;
    }

    if (nbits[twos] == 2)
        return TWOPAIR | twos << 13 | ones;

    if (twos)
        return PAIR | twos << 13 | ones;

    return ones;

}

int score7(card_t c1, card_t c2, card_t c3, card_t c4, card_t c5, card_t c6, card_t c7) {
    // each card is a bitmask
    int ones = 0, twos = 0, threes = 0, fours = 0, notfours = 0;
    int s;

    card_t hand = c1 | c2 | c3 | c4 | c5 | c6 | c7;
    int hearts = hand & 8191;
    int clubs = (hand >> 13) & 8191;
    int diamonds = (hand >> 26) & 8191;
    int spades = hand >> 39;
    int rankmask = hearts | clubs | diamonds | spades;

    // count the number of cards of each suit
    int nhearts = nbits[hearts];
    int nspades = nbits[spades];
    int nclubs = nbits[clubs];
    int ndiamonds = nbits[diamonds];

    // if a hand has a flush, the best hand is a flush or straight flush
    // lookup the result
    if (nhearts >= 5)
        return flush[hearts];
    else if (nspades >= 5)
        return flush[spades];
    else if (nclubs >= 5)
        return flush[clubs];
    else if (ndiamonds >= 5)
        return flush[diamonds];

    // lookup result for 7 unique cards
    if (nbits[rankmask] == 7)
        return unique[rankmask];

    // 13-bit mask of which ranks have 4 cards
    fours = (hearts & clubs & diamonds & spades);
    notfours = rankmask & (~fours);
    if (fours) {
        return (QUAD) | (fours << 13) | high1[notfours];
    }

    // 13-bit mask of which ranks have 3/2 cards
    // technically quads are also in these masks, but we
    // determined above there are no quads.
    threes = (( clubs & diamonds )|( hearts & spades )) & (( clubs & hearts )|( diamonds & spades ));
    twos = rankmask ^ (hearts ^ clubs ^ diamonds ^ spades);

    // Full house
    if ((threes != 0) & (twos != 0))
        return (FULLHOUSE) | (threes << 13) | high1[twos];

    if (nbits[threes] == 2)
        return (FULLHOUSE) | (high1[threes] << 13) | low[threes];

    s = straight[rankmask];
    if (s)
        return STRAIGHT | s;

    // 13-bit mask for which ranks appear once
    ones = rankmask & (~(twos | threes | fours));

    if (threes)
        return TRIP | threes << 13 | high2[ones];

    if (nbits[twos] == 3)
        return TWOPAIR | (high2[twos] << 13) | high1[low[twos] | ones];

    if (nbits[twos] == 2)
        return TWOPAIR | twos << 13 | high1[ones];

    if (twos)
        return PAIR | twos << 13 | high3[ones];

    return high5[ones];
}

inline void deck(card_t *deck) {
    int i;
    for(i=0; i < 52; i++) {
        deck[i] = 1L << i;
    }
}

void all7() {
    int i, j, k, l, m, n, o;
    int score=0;
    int sums[] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    card_t d[52];
    deck(d);

    for(i=0; i<9; i++) {
        sums[i] = 0;
    }

    for(i=0; i<52; i++) {
        for(j=i+1; j<52; j++) {
            for(k=j+1; k<52; k++) {
                for(l=k+1; l<52; l++) {
                    for(m=l+1; m<52; m++) {
                        for(n=m+1; n<52; n++) {
                            for(o=n+1; o<52; o++) {
                                score = score7(d[i], d[j], d[k], d[l], d[m], d[n], d[o]);
                                sums[score >> 26] += 1;
                            }
                        }
                    }
                }
            }
        }
    }

    for(i=0; i<9; i++) {
        printf("%20.20s %i\n", HAND_NAMES[i], sums[i]);
    }

}
