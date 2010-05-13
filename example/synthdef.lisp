(use-package :repetition)
(sclang-start)

(synthdef =plonk= ((freq 110) (len 1) (pan 0))
  !(Out.ar 0
	   (* (EnvGen.kr (Env.perc 0.05 len 1 -4) :doneAction 2)
	      (RLPF.ar
	       (list (Saw.ar (+ freq (Rand 0.0 1.0)))
		     (Saw.ar (+ freq (Rand 0.0 1.0))))
	       (SinOsc.kr (/ 2 len) -0.1 300 500)
	       0.7))))

(play
 (seq-nv base (list 0.5 0.5 0.4 0.3)
   (seq-nv sequence (sq1 4)
     (let ((len (oneof 0.2 0.2 0.4)))
       (join-nv voice (sq1 10)
	 (ass ((freq (* sequence 110 base voice))
	       (len len))
	   =plonk=))))))