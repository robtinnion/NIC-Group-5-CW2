from setuptools import setup, Extension 
from Cython.Build import cythonize
import numpy as np

extensions = [
    Extension(
        "two_opt_cand",
        ["two_opt_cand.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=["/O2"],
        language="c++",
    ),
    Extension(
        "three_opt_cand",
        ["three_opt_cand.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=["/O2"],
        language="c++",
    ),
    Extension(
        "knn_cand",
        ["knn_cand.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=["/O2"],
        language="c++",
    )
]

setup(
    name="TSP_CYTHON",
    ext_modules=cythonize(extensions, language_level="3"),
)