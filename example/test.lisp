(in-package :musik)

(defproto =wonk= (=sc-new=)
  ((name "basen")
   (:amp 0.4)
   (:wobfreq 1)))

(samples =kick=  "/mnt/fat/torrent/Mpc-Samples.Deep.n.Hard.Kicks.for.MPC4000-ViH/HARD/K088.WAV"
	 =hat1=  "/mnt/fat/share/samples/drum_cd/Hi Hats/07_01_hihat.wav"
	 =hat2=  "/mnt/fat/share/samples/drum_cd/Hi Hats/07_09_hihat.wav"
	 =crash= "/mnt/fat/share/samples/drum_cd/Crashes/CR101.WAV"
	 =snare= "/mnt/fat/share/samples/drum_cd/Snares/12_07_snare.wav")

(stop)

(play
 (joinlet ((base (/ 440 4.0))
	   (len  (oneof 2 2 1 0.5 0.5 3))
	   (melwob (oneof 1.0 1.0 3.0))
	   (mult (*  1.0 (oneof 1 1 1 2/3 3/4 4/5)))
	   (mult2 (* 1.0 (oneof 1 1 1 2/3 3/4 4/5))))

   (m =crash= 'len len)

   (seq (m =kick= 'len (- len 0.5))
        (m =snare= 'len 0))

   (seq (seq-n (- (* len 4) 3) (m =hat1= 'len 0.25))
	(m =hat2= 'len 0))

   (seq-n (* len 2)
     (join 
      (m =wonk= 'len (/ len 4.0) :sustain (/ len 4.0) :freq (* base mult (1rand 3)) :wobfreq (/ melwob len))
      (m =wonk= 'len (/ len 4.0) :sustain (/ len 4.0) :freq (* base mult2 (1rand 3)) :wobfreq (/ melwob len))))))
   
  ;;  (join
  ;;   (m =wonk= 'len len :sustain len :freq (* base mult 4  (1rand 2)) :wobfreq (/ melwob len))
  ;;   (m =wonk= 'len len :sustain len :freq (* base mult2 4 (1rand 2)) :wobfreq (/ melwob len)))

  ;; (join-n 2
  ;;   (seq
  ;;    (m =wonk= 'len (/ len 2) :sustain len         :freq (* base mult  (1rand 2)))
  ;;    (m =wonk= 'len (/ len 2) :sustain (/ len 2.0) :freq (* base mult2 (1rand 2)))))
  ))