(require :musik)
(in-package :musik)

(defun basspart (base)
  (seq
   (chord-note 1 1 :base (+ 40 (seq-note base)) :chord *7 :scale minor)
   (pause 1)
   (s-of 3
     (chord-note 1/2 (1random 12) :base (+ 40 (seq-note base)) :chord *7 :scale minor))
   (pause .5)))

(progn (reset)
       (sleep .1)
       (send (scale-bpm 240
			(seq
			 (s-of 2
			   (join
			    (add-keys `(:channel ,*drums*)
				      (join
				       (s-of 4
					 (make-note 2 -kick)
					 (make-note 2 -snare))
				       (s-of 2
					(s-of 7
					  (make-note 1 -hic))
					(make-note .5 -hio)
					(make-note .5 -rim))))
			    (let ((chord (1random 8)))
			      (n-of 4
				(add-keys `(:channel ,*piano*)
					  (seq
					   (basspart 1)
					   (basspart chord)
					   (basspart 2)
					   (basspart 5)))))))
			 (add-keys `(:channel ,*piano*)
				   (chord-note 4 1 :chord *7)))))
       (play))