(in-package :musik)

(defun 1rand (x)
  (+ 1 (random x)))

(defun oneof (&rest alternatives)
  (nth (random (length alternatives)) alternatives))

(defun nseq (int &optional (start 0))
  (loop for i from 0 below int collect (+ start i)))

(defun 1nseq (int)
  (nseq int 1))

;; for the object system
(defun m (parents &rest args)
  (object :parents (if (listp parents) parents (list parents))
	  :properties (loop for (key val) on args by #'cddr :collect (list key val))))