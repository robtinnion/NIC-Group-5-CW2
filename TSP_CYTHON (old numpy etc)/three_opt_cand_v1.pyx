# ============================================================
# three_opt_cand.pyx — Clean full version
# Candidate-guided 3-opt with don't-look bits (single pattern, stable)
# ============================================================

import cython
from libc.math cimport sqrt

@cython.cdivision(True)
@cython.boundscheck(False)
@cython.wraparound(False)
cpdef tuple three_opt_cy(list tour,
                         list cand,
                         object dist,
                         int max_iter=1000,
                         bint verbose=False):

    cdef int n = len(tour)
    if n < 6:
        return tour, _tour_length_list(tour, dist)

    cdef int i, j
    cdef double best_len = _tour_length_list(tour, dist)
    cdef double delta
    cdef bint improved_any, improved_here

    cdef int[:] tour_pos = _alloc_int_array(n)
    cdef int[:] pos      = _alloc_int_array(n)
    cdef int[:] dont_look = _alloc_int_array(n)
    _init_tour_arrays(tour, tour_pos, pos, dont_look, n)

    cdef int MAX_CAND_A = 20
    cdef int MAX_CAND_C = 10

    if verbose:
        print("3-OPT init len =", best_len)

    for _ in range(max_iter):
        improved_any = False

        for i in range(n):
            if dont_look[i]:
                continue

            improved_here = _three_opt_try_from_a(i,
                                                  tour_pos, pos,
                                                  cand, dist,
                                                  n,
                                                  MAX_CAND_A, MAX_CAND_C,
                                                  &delta)

            if improved_here and delta < 0.0:
                best_len += delta
                improved_any = True
                dont_look[i] = 0

                j = i+1 if i < n-1 else 0
                if j > 0:   dont_look[j-1] = 0
                if j < n-1: dont_look[j+1] = 0

            else:
                dont_look[i] = 1

        if not improved_any:
            break

    out = [0]*n
    for i in range(n):
        out[i] = tour_pos[i]

    return out, best_len


# ============================================================
# Basic helpers
# ============================================================

cdef int[:] _alloc_int_array(int n):
    return cython.view.array(shape=(n,),
                             itemsize=cython.sizeof(cython.int),
                             format="i")

cdef void _init_tour_arrays(list tour,
                            int[:] tour_pos,
                            int[:] pos,
                            int[:] dont_look,
                            int n):
    cdef int i, city
    for i in range(n):
        city = <int>tour[i]
        tour_pos[i] = city
        pos[city]   = i
        dont_look[i] = 0

cdef double _dist(object dist, int a, int b):
    return <double>dist[a][b]

cdef double _tour_length_list(list tour, object dist):
    cdef int n = len(tour)
    cdef int i, a, b
    cdef double s=0
    for i in range(n):
        a = tour[i]
        b = tour[(i+1)%n]
        s += <double>dist[a][b]
    return s


# ============================================================
# 3-OPT — stable single-pattern implementation
# ============================================================

cdef bint _three_opt_try_from_a(int i,
                                int[:] tour_pos,
                                int[:] pos,
                                list cand,
                                object dist,
                                int n,
                                int MAX_A,
                                int MAX_C,
                                double* out_delta):

    cdef int a = tour_pos[i]
    cdef int b_idx = i+1 if i<n-1 else 0
    cdef int b = tour_pos[b_idx]

    cdef list cand_a = cand[a]
    cdef int limA = min(len(cand_a), MAX_A)

    cdef int idxA, city_c, j, k
    cdef int c, d_idx, d, e, f_idx, f
    cdef list cand_c
    cdef int limC

    cdef double base, cand_cost, delta

    for idxA in range(limA):
        city_c = cand_a[idxA]
        j = pos[city_c]
        if j==i or j==b_idx or j<=i+1:
            continue

        d_idx = j+1 if j<n-1 else 0
        c, d = tour_pos[j], tour_pos[d_idx]

        cand_c = cand[c]
        limC = min(len(cand_c), MAX_C)

        for k in range(limC):
            e = cand_c[k]
            f_idx = pos[e]+1
            if f_idx>=n:
                f_idx=0
            if not _valid_ijk(i,j,pos[e],n):
                continue
            f = tour_pos[f_idx]

            base = (_dist(dist,a,b)+_dist(dist,c,d)+_dist(dist,e,f))
            cand_cost = (_dist(dist,a,c)+_dist(dist,b,e)+_dist(dist,d,f))
            delta = cand_cost - base

            if delta < 0.0:
                _apply_3opt_move(i,j,pos[e],tour_pos,pos,n)
                out_delta[0] = delta
                return True

    return False


cdef bint _valid_ijk(int i,int j,int k,int n):
    return i<j<k<n and j>i+1 and k>j+1


# ============================================================
# Apply + reversal ops
# ============================================================

cdef void _apply_3opt_move(int i,int j,int k,int[:] tour_pos,int[:] pos,int n):
    _reverse(tour_pos, i+1, j)
    _reverse(tour_pos, j+1, k)
    cdef int idx, city
    for idx in range(n):
        city=tour_pos[idx]
        pos[city]=idx

cdef void _reverse(int[:] a,int l,int r):
    cdef int t
    while l<r:
        t=a[l]; a[l]=a[r]; a[r]=t
        l+=1; r-=1
