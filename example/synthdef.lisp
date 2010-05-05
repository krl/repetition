(use-package :repetition)
(sclang-start)

(synthdef =plonk= ((freq 110) (len 1))
  !(Out.ar 0
	   (* (EnvGen.kr (Env.perc 0.05 len 1 -4) :doneAction 2)
	      (list (Saw.ar (+ freq (Rand 0.0 1.0)))
		    (Saw.ar (+ freq (Rand 0.0 1.0)))))))

(play
 (seq-nv base (list 0.5 0.5 0.4 0.3)
   (seq-nv sequence (sq1 8)
     (join-nv voice (sq1 4)
       (ass ((freq (* sequence 110 base voice))
	     (len 0.1))
	 =plonk=)))))