(in-package :musik)
(sclang-start)

(synthdef =basen= ((outbus 0) (freq 100) (pan 0) (amp 0.5) (sustain 1) (wobfreq 4))
  !(Out.ar 
    outbus (*
	    (RLPF.ar (list (Saw.ar (+ freq (SinOsc.kr (Rand 0 10) 0 (/ freq 100))))
			   (Saw.ar (+ freq (SinOsc.kr (Rand 0 10) 0 (/ freq 100)))))
		     (SinOsc.kr wobfreq -0.1 400 2000)
		     0.7)
	    (EnvGen.kr (Env.linen 0.1 sustain 0.1 1 -4) :doneAction 2)
	    amp)))

(samples =kick=  "/mnt/fat/share/samples/drum_cd/909/C_Kick.wav"
	 =snare= "/mnt/fat/share/samples/drum_cd/909/909snare2.WAV"
	 =hat=   "/mnt/fat/share/samples/drum_cd/909/C_HH.wav"
	 =hat2=  "/mnt/fat/share/samples/drum_cd/909/909ophat1.WAV"
	 =crash= "/mnt/fat/share/samples/drum_cd/Crashes/CR201.WAV")

(defun eerie ()
 (let ((wob   (oneof 0.1 0.5 0.3 1 6))
       (len   (oneof 2 2 0.5 1 3))
       (fmult (oneof 1 1 1 1 2/3 3/4 4/5))
       (base  (* 440 (oneof 1 2/3 3/4 4/5) 1/2)))

   (join-nv voice '(1 1.5 2 2.5)
     (ass ((freq (* base fmult voice))
	   (wobfreq wob)
	   (len len)
	   (sustain #'len)
	   (pan (lambda (x) (- 1 (random 2.0))))
	   (amp (lambda (x) (random 0.3))))
	  =basen=))))

(defun kick ()
  (join-nv rate '(0.2 0.3 0.4 1 2)
    (ass ((rate (+ rate (random 0.01))))
       =kick=)))

(play (over (eerie)
	(lambda (list)
	  (let ((length (len (first list))))
	    (trim length
	      (join
		(seq-n (* length 2)
		  (ass ((len 0.5)
			(amp (random 0.3)))
		       =hat=))
		(ass ((len (len (first list))))
		     (kick))	      
		(offset (oneof 0.25 0.5)
		  (seq =snare= =snare=))
		;; melody notes
		(let ((notes (oneof 2 3 1)))
		  (seq-n notes
		    (ass ((freq (* (freq (apply 'oneof list)) (oneof 4/3 2)))
			  (amp (+ 0.1 (random 0.1)))
			  (wobfreq (/ 1 length notes))
			  (len (/ length notes))
			  (sustain #'len))
			 =basen=)))))))))

(stop)