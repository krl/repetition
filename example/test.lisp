(in-package :musik)
(sclang-start)

(synthdef =basen= ((freq 100) (pan 0) (amp 0.5) (sustain 1) (wobfreq 4))
  !(Out.ar 
    0 (*
       (RLPF.ar (list (Saw.ar (+ freq (SinOsc.kr (Rand 0 100) 0 (/ freq 100))))
		      (Saw.ar (+ freq (SinOsc.kr (Rand 0 100) 0 (/ freq 100)))))
		(SinOsc.kr wobfreq -0.1 200 320)
		0.4)
       (EnvGen.kr (Env.linen 0.01 sustain 0.01 1 -4) :doneAction 2)
       amp)))

(samples =kick=  "/mnt/fat/share/samples/drum_cd/909/C_Kick.wav"
	 =snare= "/mnt/fat/share/samples/drum_cd/909/909snare1.WAV"
	 =hat=   "/mnt/fat/share/samples/drum_cd/909/C_HH.wav"
	 =hat2=  "/mnt/fat/share/samples/drum_cd/909/909ophat1.WAV")

(stop)

(play (join
       (seq (m =basen= 'freq 30)
	    (m =basen= 'freq (oneof 30 33) 'wobfreq (oneof 4 6 1)))
       (ass ((rate 0.2))
	 (join
	  (seq-n 4 (m =hat2= 'len 0.5 'amp 0.1))
	  (seq (m =kick= 'len (oneof 0.875 0.75))
		    =kick=)
	       (m =snare= 'timetag 1)))))
