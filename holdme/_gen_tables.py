import numpy as np


def highest(mask, n):
    j = 0
    for i in range(13, -1, -1):
        j += ((mask >> i) & 1)
        if j == n:
            return (mask >> i) << i
    return 0


def lowest(mask):
    for i in range(13):
        if mask & (1 << i):
            return 1 << i
    return 0


def nbits(mask):
    result = 0
    while mask > 0:
        result += (mask & 1)
        mask >>= 1
    return result

# high1
inds = np.arange(2 ** 13, dtype=int)

high1 = np.array([highest(i, 1) for i in inds])
high2 = np.array([highest(i, 2) for i in inds])
high3 = np.array([highest(i, 3) for i in inds])
high5 = np.array([highest(i, 5) for i in inds])
low = np.array([lowest(i) for i in inds])
nbit = np.array([nbits(i) for i in inds])

straights = low * 0
for i in inds:
    mask = (1 << 12) + (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3)
    if (i & mask) == mask:
        straights[i] = 1 << 3

    for j in range(9):
        mask = (1 << j) + (1 << (j + 1)) + (1 << (j + 2)) + (1 << (j + 3)) + (1 << (j + 4))
        if (i & mask) == mask:
            straights[i] = 1 << (j + 4)

unique = low * 0
for i in inds:
    if straights[i] > 0:
        unique[i] = 4 << 26 | straights[i]
    else:
        unique[i] = high5[i]

flush = low * 0
for i in inds:
    if straights[i] > 0:
        flush[i] = 8 << 26 | straights[i]
    else:
        flush[i] = 5 << 26 | high5[i]

with open('tables.h', 'w') as outfile:
    outfile.write('static int high1[] = {%s};\n' % ','.join(map(str, high1.tolist())))
    outfile.write('static int high2[] = {%s};\n' % ','.join(map(str, high2.tolist())))
    outfile.write('static int high3[] = {%s};\n' % ','.join(map(str, high3.tolist())))
    outfile.write('static int high5[] = {%s};\n' % ','.join(map(str, high5.tolist())))
    outfile.write('static int low[] = {%s};\n' % ','.join(map(str, low.tolist())))
    outfile.write('static int straight[] = {%s};\n' % ','.join(map(str, straights.tolist())))
    outfile.write('static int nbits[] = {%s};\n' % ','.join(map(str, nbit.tolist())))
    outfile.write('static int flush[] = {%s};\n' % ','.join(map(str, flush.tolist())))
    outfile.write('static int unique[] = {%s};\n' % ','.join(map(str, unique.tolist())))
