from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np

setup(name='knish',
      version='0.1',
      py_modules=['knish'],
      package_data={'knish': ['hands.npz']},
      ext_modules=cythonize('_lib.pyx'), include_dirs=[np.get_include()])
