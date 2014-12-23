from setuptools import setup, find_packages, Extension
from Cython.Build import cythonize
import numpy as np


# hand_eval = Extension('hand_eval',
#                      sources=['holdme/hand_eval.c'])

extensions = [Extension('holdme._lib', ['holdme/_lib.pyx', 'holdme/hand_eval.c'])]
setup(name='holdme',
      version='0.1',
      packages=find_packages(),
      ext_modules=cythonize(extensions),
      include_dirs=[np.get_include()])
