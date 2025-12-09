from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np
import sys

# Function to set platform-specific compile args
def get_extra_compile_args():
    if sys.platform == "win32":
        # For MSVC compiler on Windows
        return ["/O2"]
    else:
        # For GCC/Clang on Linux/macOS
        return ["-O2"]

extensions = [
    Extension(
        "two_opt_cand",
        ["two_opt_cand.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=get_extra_compile_args(),
        language="c++",
    ),
    Extension(
        "three_opt_cand",
        ["three_opt_cand.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=get_extra_compile_args(),
        language="c++",
    ),
    Extension(
        "knn_cand",
        ["knn_cand.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=get_extra_compile_args(),
        language="c++",
    )
]

setup(
    name="TSP_CYTHON",
    ext_modules=cythonize(extensions, language_level="3"),
)
