from setuptools import setup, find_packages
from Cython.Build import cythonize
import numpy as np

setup(name='holdme',
      version='0.1',
      packages=find_packages(),
      ext_modules=cythonize('*/_lib.pyx'), include_dirs=[np.get_include()])
