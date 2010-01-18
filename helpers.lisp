(in-package :musik)

(defun 1rand (x)
  (+ 1 (random x)))

(defun oneof (&rest alternatives)
  (nth (random (length alternatives)) alternatives))