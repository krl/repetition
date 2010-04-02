(in-package :musik)

(defun interval (intervals number &optional (accum 0))
  (cond ((> number 0)
	 (interval (shift intervals 1) (- number 1) (+ accum (first intervals))))
	((< number 0)
	 (interval (shift intervals 1) (+ number 1) (- accum (first intervals))))
	(t accum)))

;; objects

(defproto =tempered= ()
  ((base 0)
   (basefreq (/ 440 4))))

(defproto =scale= (=tempered=)
  ((intervals '(1))))

(defproto =major= (=scale=)
  ((intervals '(2 2 1 2 2 2 1))))

(defproto =minor= (=scale=)
  ((intervals '(2 1 2 2 1 2 2))))

(defmessage shift (scale num)
  (:reply ((scale =scale=) (num =number=))
	  (m scale 'intervals (shift (intervals scale) num)))
  
  (:reply ((list =list=) (num =number=))
	  (cond ((> num 0)
		 (shift (append (rest list) (list (first list))) (- num 1)))
		((< num 0)
		 (shift (append (last list) (butlast list)) (+ num 1)))
		(t
		 list))))

(defmessage get-freq (scale num)
  (:reply ((scale =tempered=) (num =number=))
  	  (* (basefreq =scale=) (expt (expt 2 (/ 1 12)) 
				      (+ (base scale) num))))

  (:reply ((scale =scale=) (num =number=))
	  (call-next-reply scale
			   (reduce (lambda (x y)
				     (if (direct-property-p y 'intervals)
					 (interval (intervals y) x)
					 x))
				   (object-precedence-list scale)
				   :initial-value num))))

;; (deffilter resolve (source)
;;   (map 'list (lambda (x)
;; 	       (m x 'freq (get-freq 
;;   			   (property-value x 'scale)
;;   			   (+ (property-value x 'tone)
;; 			      (property-value x 'base)))))
;;        source))