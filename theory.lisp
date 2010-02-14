(in-package :musik)

(defun shift (list)
  (append (rest list) (list (first list))))

(defun interval (intervals number &optional (accum 0))
  (if (zerop number) accum
      (interval (shift intervals) (- number 1) (+ accum (first intervals)))))

;; objects

(defproto =chromatic= ()
  ((basefreq (/ 440 4))))

(defproto =scale= (=chromatic=))

(defproto =major= (=scale=)
  ((intervals '(2 2 1 2 2 2 1))))

(defproto =minor= (=chromatic=)
  ((intervals '(2 1 2 2 1 2 2))))

(defmessage get-freq (scale num)
  (:reply ((scale =chromatic=) (num =number=))
	  (* (basefreq =scale=) (expt (expt 2 (/ 1 12)) num)))

  (:reply ((scale =scale=) (num =number=))
	  (call-next-reply scale (interval (intervals scale) num))))

(macroexpand-1 '(deffilter resolve (list)
  (map 'list (lambda (x)
	       (m x 'freq (get-freq 
  			   (property-value x 'scale)
  			   (property-value x 'tone))))
       list)))