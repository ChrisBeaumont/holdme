from time import time
import numpy as np

from _lib import all7


def build_index():
    t0 = time()
    k, v = all7()
    print time() - t0

    idx = np.argsort(k)

    np.savez_compressed('hand7.npz', key=k[idx], val=v[idx])

if __name__ == "__main__":
    build_index()
