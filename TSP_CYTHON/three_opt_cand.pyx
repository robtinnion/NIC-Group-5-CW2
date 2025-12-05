# cython: boundscheck=False, wraparound=False, cdivision=True, language_level=3

cimport cython
from libc.math cimport sqrt
from libc.stdint cimport uint32_t

############################################################
# XORSHIFT32
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
# BASIC DIST
############################################################
cdef inline double edge_len(object coords, int u, int v):
    cdef double dx = float(coords[u,0]) - float(coords[v,0])
    cdef double dy = float(coords[u,1]) - float(coords[v,1])
    return sqrt(dx*dx + dy*dy)

############################################################
# RANDOMISED 3-OPT
############################################################
cpdef tuple three_opt_cy(list tour,
                         list cand,
                         object coords,
                         int max_iter,     # no default
                         bint verbose=False,
                         int seed=1):

    cdef int n = len(tour)
    cdef uint32_t rng = <uint32_t>seed

    if n < 6:
        return tour, 0.0

    cdef int it, i, j, k
    cdef int a, b, c, d, e, f
    cdef double old_cost, new_cost
    cdef bint improved

    # compute initial length
    cdef double L = 0
    for i in range(n):
        L += edge_len(coords, tour[i], tour[(i+1)%n])

    for it in range(max_iter):

        i = rand_int(&rng, n)
        j = rand_int(&rng, n)
        k = rand_int(&rng, n)

        if not (0 <= i < j < k < n-1):
            continue

        a = tour[i]
        b = tour[(i+1)%n]
        c = tour[j]
        d = tour[(j+1)%n]
        e = tour[k]
        f = tour[(k+1)%n]

        old_cost = edge_len(coords,a,b) + edge_len(coords,c,d) + edge_len(coords,e,f)

        # Try 3-opt move: reverse middle segments
        # (Simplified LKH-style improvement)
        new_cost = (
            edge_len(coords,a,c) +
            edge_len(coords,b,e) +
            edge_len(coords,d,f)
        )

        if new_cost + 1e-12 < old_cost:

            # reverse segment (i+1, j)
            l = i+1
            r = j
            while l < r:
                tour[l], tour[r] = tour[r], tour[l]
                l += 1
                r -= 1

            # reverse segment (j+1, k)
            l = j+1
            r = k
            while l < r:
                tour[l], tour[r] = tour[r], tour[l]
                l += 1
                r -= 1

            L += (new_cost - old_cost)

            if verbose:
                print(f"[3-OPT] improve iter={it} → {L:.2f}")

    return tour, L
