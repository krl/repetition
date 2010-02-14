(in-package :musik)
(sclang-start)

(synthdef =basen= ((out 0) (freq 100) (pan 0) (amp 0.5) (sustain 1) (wobfreq 4))
  !(Out.ar 
    out (*
       (RLPF.ar (list (Saw.ar (+ freq (SinOsc.kr (Rand 0 100) 0 (/ freq 100))))
		      (Saw.ar (+ freq (SinOsc.kr (Rand 0 100) 0 (/ freq 100)))))
		(SinOsc.kr wobfreq -0.1 320 320)
		0.4)
       (EnvGen.kr (Env.linen 0.01 sustain 0.01 1 -4) :doneAction 2)
       amp)))

(samples =kick=  "/mnt/fat/share/samples/drum_cd/909/C_Kick.wav"
	 =snare= "/mnt/fat/share/samples/drum_cd/909/HandClap.wav"
	 =hat=   "/mnt/fat/share/samples/drum_cd/909/C_HH.wav"
	 =hat2=  "/mnt/fat/share/samples/drum_cd/909/909ophat1.WAV")

(stop)

(deffilter octave (list)
  (reduce (lambda (x y) 
	    (if (find 'freq (available-properties y))
		(append x (list (m y 'freq (* (freq y) 2))))
		x))
	  list
	  :initial-value list))
		    
(play 
 (octave
 (seq (m =basen= 'freq 30)
      (m =basen= 'freq (oneof 30 33) 'wobfreq (oneof 1 3))
      =kick=)))

       (seq-n 4 (m =hat2= 'len 0.5 'amp 0.1))
       (m =hat= 'timetag (oneof 1.25 1.75) 'len 0 'amp 0.2)
       (seq (m =kick= 'len (oneof 0.875 0.75))
	    =kick=)
       (m =snare= 'timetag 1)))

(functionp #'len)

(play
 (ass ((freq (lambda (x) (* (freq x) (+ 1 (* (random 0.001) (oneof 1 -1)))))))
   (resolve
    (join-n 10
      (ass ((wobfreq (oneof 0.5 2))
	    (amp 0.04)
	    (scale =major=)
	    (sustain #'len))    
	(ass ((len 0.5))
	  (join
	   (m =basen= 'tone 3)
	   (m =basen= 'tone 5)
	   (m =basen= 'tone 7)))
	(ass ((len 0.5))
	  (join
	   (m =basen= 'tone 3)
	   (m =basen= 'tone 5)
	   (m =basen= 'tone 7)))
	(ass ((len 1))
	  (join
	   (m =basen= 'tone 0)
	   (m =basen= 'tone 2)
	   (m =basen= 'tone 4))))))))

(stop)