# cython: boundscheck=False, wraparound=False, cdivision=True, initializedcheck=False

cimport cython
from libc.stdlib cimport malloc, free

@cython.boundscheck(False)
@cython.wraparound(False)
cpdef two_opt_cand(list tour, list cand, list dist, int max_iter=2000, bint verbose=False):
    """
    Fast 2-opt local search (candidate list guided) - Cython version.
    tour  : list of city indices in visiting order
    cand  : candidate list [for each city: list of nearest neighbors]
    dist  : distance matrix dist[i][j]
    max_iter : how many improvement passes allowed
    """

    cdef int n = len(tour)
    cdef int i, j
    cdef int a, b, c, d
    cdef double oldd, newd
    cdef double best_len = 0
    cdef bint improved = True
    cdef int it = 0

    # ===== allocate pos[] lookup array =====
    cdef int* pos = <int*> malloc(n * sizeof(int))
    if pos == NULL:
        raise MemoryError()

    # initial mapping + initial length
    for i in range(n):
        pos[tour[i]] = i
        a = tour[i]
        b = tour[(i+1) % n]
        best_len += dist[a][b]

    # ===== 2-opt local improvement loop =====
    while improved and it < max_iter:
        improved = False
        it += 1

        for i in range(n):
            a = tour[i]
            b = tour[(i+1) % n]

            for c in cand[a]:
                j = pos[c]
                if j <= i+1 or j >= n-1:
                    continue
                d = tour[(j+1) % n]

                oldd = dist[a][b] + dist[c][d]
                newd = dist[a][c] + dist[b][d]

                if newd < oldd:
                    # perform 2-opt reversal in Python slice (still fast)
                    tour[i+1:j+1] = tour[i+1:j+1][::-1]

                    # rebuild pos[] (fast in C loop)
                    for j in range(n):
                        pos[tour[j]] = j

                    improved = True
                    break
            if improved:
                break

    free(pos)
    return tour, best_len
