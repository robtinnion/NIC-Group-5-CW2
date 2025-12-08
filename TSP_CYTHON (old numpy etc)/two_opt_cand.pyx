# cython: boundscheck=False, wraparound=False, cdivision=True, language_level=3

cimport cython
from libc.math cimport sqrt
from libc.stdint cimport uint32_t

############################################################
# XORSHIFT32 — deterministic RNG per-call
############################################################
cdef inline uint32_t xs32(uint32_t *state):
    cdef uint32_t x = state[0]
    x ^= x << 13
    x ^= x >> 17
    x ^= x << 5
    state[0] = x
    return x

cdef inline int rand_int(uint32_t *state, int limit):
    return <int>(xs32(state) % limit)


############################################################
# DISTANCE
############################################################
cdef inline double edge_len(object coords, int u, int v):
    cdef double dx = float(coords[u, 0]) - float(coords[v, 0])
    cdef double dy = float(coords[u, 1]) - float(coords[v, 1])
    return sqrt(dx*dx + dy*dy)


############################################################
# 2-OPT WITH RANDOMISED CANDIDATE ORDER
############################################################
cpdef tuple two_opt_cand(
        list tour,
        list cand,
        object coords,
        int max_iter,        # no default
        bint verbose=False,
        int seed=1):

    cdef int n = len(tour)
    if n <= 2:
        return tour, 0.0

    cdef uint32_t rng = <uint32_t>seed

    cdef int i, j, t
    cdef int a, b, c, d, city
    cdef int l, r, idx, K
    cdef double best_len = 0.0
    cdef double oldd, newd
    cdef bint improved

    pos = [0] * n

    # initial mapping + base cost
    for i in range(n):
        pos[tour[i]] = i

    for i in range(n):
        a = tour[i]
        b = tour[(i+1) % n]
        best_len += edge_len(coords, a, b)

    ########################################################
    # MAIN LOOP
    ########################################################
    for t in range(max_iter):

        improved = False

        for i in range(n):

            a = tour[i]
            b = tour[(i + 1) % n]
            neigh = cand[a]
            K = len(neigh)

            # RANDOM CAND ORDER
            # Sample each candidate index exactly once in random order
            perm = list(range(K))
            for idx in range(K):
                j = idx + rand_int(&rng, K - idx)
                perm[idx], perm[j] = perm[j], perm[idx]

            for idx in perm:
                c = neigh[idx]
                j = pos[c]

                if j <= i+1 or j >= n-1:
                    continue

                d = tour[(j+1) % n]

                oldd = edge_len(coords, a, b) + edge_len(coords, c, d)
                newd = edge_len(coords, a, c) + edge_len(coords, b, d)

                if newd + 1e-12 < oldd:

                    l = i+1
                    r = j
                    while l < r:
                        city = tour[l]
                        tour[l] = tour[r]
                        tour[r] = city
                        l += 1
                        r -= 1

                    for j in range(n):
                        pos[tour[j]] = j

                    best_len += (newd - oldd)
                    improved = True
                    break

            if improved:
                break

        if not improved:
            break

    return tour, best_len
