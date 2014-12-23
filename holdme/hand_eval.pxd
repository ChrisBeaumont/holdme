cdef extern from "hand_eval.h":
    int score7(long c1, long c2, long c3, long c4, long c5, long c6, long c7) nogil
    int score5(long c1, long c2, long c3, long c4, long c5) nogil
