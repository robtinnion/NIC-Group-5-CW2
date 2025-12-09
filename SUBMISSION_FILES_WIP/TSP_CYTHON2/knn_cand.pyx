# knn_cand.pyx
# Pure Cython KNN for candidate lists (O(n^2), but fast because C-level loops)

import cython
from libc.math cimport sqrt
cimport numpy as cnp

@cython.boundscheck(False)
@cython.wraparound(False)
def build_candidate_lists_knn(cnp.ndarray[cnp.double_t, ndim=2] coords, int k):
    """
    coords: (n, 2) array of doubles
    k: number of neighbours
    returns Python list of lists of int
    """
    cdef int n = coords.shape[0]
    cdef double xi, yi, dx, dy, dist
    cdef int i, j

    # allocate result
    cdef list result = [None] * n

    # temporary array for distances
    cdef double[:, :] dist_buf = cython.view.array(
        shape=(n, n),
        itemsize=cython.sizeof(cython.double),
        format="d"
    )

    # compute NxN distances (upper triangle only)
    for i in range(n):
        xi = coords[i, 0]
        yi = coords[i, 1]
        for j in range(n):
            if i == j:
                dist_buf[i, j] = 1e300   # sentinel so self is not picked
            else:
                dx = xi - coords[j, 0]
                dy = yi - coords[j, 1]
                dist_buf[i, j] = sqrt(dx*dx + dy*dy)

    # extract k nearest for each i
    for i in range(n):
        # build list of (dist, index)
        tmp = [(dist_buf[i, j], j) for j in range(n)]
        tmp.sort(key=lambda x: x[0])
        result[i] = [tmp[t][1] for t in range(k)]

    return result
