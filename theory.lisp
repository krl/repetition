(require :musik)
(in-package :musik)

;; theory

(defparameter minor '(0 2 3 5 7 8 10))
(defparameter major '(0 2 4 5 7 9 10))

(defparameter *triad '(1 3 5))
(defparameter *7 '(1 3 5 7))

(defun 1nth (place seq)
  (let ((length (length seq)))
    (nth (mod (- place 1) length) seq)))

(defun seq-note (note &optional (seq major) (oct 12))
  (let ((length (length seq)))
    (+
     (nth (mod (- note 1) length) seq)
     (* (floor (/ (- note 1) length)) oct)
     )))

(defun chord-note (length number &key (base 40) (scale major) (chord *triad))
  (make-note length 
	     (+ base
		(seqnote (seqnote number chord 7) scale))))