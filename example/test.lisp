(in-package :musik)

(synthdef =basen= ((freq 100) (pan 0) (amp 0.3) (sustain 1) (wobfreq 10))
  !(Out.ar 
    0 (*
       (RLPF.ar (list (Saw.ar (+ freq (SinOsc.kr (Rand 0 100) 0 (/ freq 100))))
		      (Saw.ar (+ freq (SinOsc.kr (Rand 0 100) 0 (/ freq 100)))))
		(SinOsc.kr wobfreq -0.1 200 360)
		0.4)
       (EnvGen.kr (Env.linen 0.01 sustain 0.01 1 -4) :doneaction 2)
       amp)))

(play (m =basen= 'sustain 1 'wobfreq 8 'freq (* (oneof 40 60) (1rand 4))))

;; (samples =kick=  "/mnt/fat/torrent/Mpc-Samples.Deep.n.Hard.Kicks.for.MPC4000-ViH/HARD/K088.WAV"
;; 	 =hat1=  "/mnt/fat/share/samples/drum_cd/Hi Hats/07_01_hihat.wav"
;; 	 =hat2=  "/mnt/fat/share/samples/drum_cd/Hi Hats/07_09_hihat.wav"
;; 	 =crash= "/mnt/fat/share/samples/drum_cd/Crashes/CR101.WAV"
;; 	 =snare= "/mnt/fat/share/samples/drum_cd/Snares/12_07_snare.wav")

;; (stop)

(play (join
       (m =crash= :amp 10)
       (seq-n 4
	 (oneof (m =kick= :amp 10)
		(seq 
		 (m =kick= :amp 10 'len 0.5)
		 (m =kick= :amp 10 'len 0.5)))
	 (m =snare= :amp 10))
       (seq
	(seq-n 15
	  (m =hat1= :amp (+ 9 (random 2.0)) 'len 0.5))
	(seq-n 2
	  (m =hat2= 'len 0.25 :amp 10)))))

(stop)

(play (joinlet ((base (oneof 40 60 70)))
       (join-n 10
       	 (seq 
       	  (m =wonk= 'len 1.5 :sustain 1.5 :freq (* base (1rand 10) 1.3) :wobfreq 8 :amp 0.2)
       	  (m =wonk= 'len 0.5 :sustain 0.5 :freq (* base (1rand 10) 0.9) :wobfreq 8 :amp 0.2)))
	=crash=
	(seq (m =kick= 'len (oneof 1 1.5) :amp 5)
	     (m =snare= 'len 0 :amp 5))
	(seq-n 4 (m =hat1= 'len 0.5 :amp (+ 1.0 (random 0.4))))))

(stop)

(play
 (joinlet ((base (/ 440 8.0))
	   (len  (oneof 1 0.5 0.5 3 2 2))
	   (melwob (oneof 8.0 1.0 1.0 4.0))
	   (mult  (* 1.0 (oneof 1 1 1 1 2/3 3/4 4/5)))
	   (mult2 (* 1.0 (oneof 1 1 1 1 2/3 3/4 4/5))))

   ;; (join-n 10
   ;;   (m =skren= :sustain len :freq (* base mult mult2 (1rand 8)) 'len len))

   (m =crash= 'len len)

   ;; (seq (m =kick= 'len (- len 0.5))
   ;;      (m =snare= 'len 0))

   ;; (seq (seq-n (- (* len 4) 3) (m =hat1= 'len 0.25 :amp (+ 0.3 (random 0.4))))
   ;; 	(m =hat2= 'len 0))

   (seq-n 2
     (join 
      (m =wonk= 'len (/ len 2.0) :sustain (/ len 2.0) :freq (* base mult  (1rand 3)) :wobfreq melwob)
      (m =wonk= 'len (/ len 2.0) :sustain (/ len 2.0)  :freq (* base mult2 (1rand 3)) :wobfreq melwob)))))
   
  ;;  (join
  ;;   (m =wonk= 'len len :sustain len :freq (* base mult 4  (1rand 2)) :wobfreq (/ melwob len))
  ;;   (m =wonk= 'len len :sustain len :freq (* base mult2 4 (1rand 2)) :wobfreq (/ melwob len)))

  ;; (join-n 2
  ;;   (seq
  ;;    (m =wonk= 'len (/ len 2) :sustain len         :freq (* base mult  (1rand 2)))
  ;;    (m =wonk= 'len (/ len 2) :sustain (/ len 2.0) :freq (* base mult2 (1rand 2)))))