(in-package :musik)

(defproto =wonk= (=sc-new=)
  ((name "basen")
   (len  0.1)
   (args '(:amp 0.14
	   :wobfreq 1))))

(stop)

(play
 (joinlet ((base 30)
	   (len  (oneof 2 3))
	   (mult (oneof 1.0 1.5 1.2 1.9)))
   (join
    (sc-create =wonk= 'len len :sustain len :freq (* base mult 6 (1rand 2)) :wobfreq (/ 1.0 len))
    (sc-create =wonk= 'len len :sustain len :freq (* base mult 6 (1rand 2) 1.5) :wobfreq (/ 1.0 len)))

  (join-n 2
    (seq
     (sc-create =wonk= 'len (/ len 2) :sustain len :freq (* base (1rand 4)))
     (sc-create =wonk= 'len (/ len 2) :sustain (/ len 2.0) :freq (* base mult (1rand 4)))))))