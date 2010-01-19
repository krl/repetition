(in-package :musik)

(defproto =wonk= (=sc-new=)
  ((name "basen")
   (args '(:amp 0.14
	   :wobfreq 1))))

(stop)

(play
 (joinlet ((base (/ 440 8.0))
	   (len  (oneof 2 2 1 3))
	   (melwob (oneof 1.0 1.0 3.0))
	   (mult (*  1.0 (oneof 1 1 1 2/3 3/4 4/5 5/6 6/7)))
	   (mult2 (* 1.0 (oneof 1 1 1 2/3 3/4 4/5 5/6 6/7))))

   (join
    (sc-create =wonk= 'len len :sustain len :freq (* base mult 6  (1rand 2)) :wobfreq (/ melwob len))
    (sc-create =wonk= 'len len :sustain len :freq (* base mult2 6 (1rand 2)) :wobfreq (/ melwob len)))

  (join-n 2
    (seq
     (sc-create =wonk= 'len (/ len 2) :sustain len         :freq (* base mult  (1rand 2)))
     (sc-create =wonk= 'len (/ len 2) :sustain (/ len 2.0) :freq (* base mult2 (1rand 2)))))))