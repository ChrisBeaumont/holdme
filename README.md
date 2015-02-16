# Holdme

Holdme is a fast Texas Hold'em Poker odds library written in Cython.

### Usage

```python
from holdme import Card, Hand, headsup

h1 = Hand('AC AD')
h2 = Hand('KS TH')

pwin, plose = headsup(h1, h2)
print pwin, plose  # 0.853392855474 0.143615269251

flop = Hand('KC KH TD')
pwin, plose = headsup(h1, h2, flop)
print pwin, plose # 0.0858585858586 0.914141414141

community = flop + Card('AH') + Card('AS')
pwin, plose = headsup(h1, h2, community)
print pwin, plose # 1, 0

print Hand('2C 3C 4C 5C 6C').name  # Straight Flush (6 high)
```