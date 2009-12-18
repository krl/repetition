(require 'musik)
(in-package :musik)

(defmessage wobb ('sc-message :name "basen" :amp 0.1))
(defmessage kick ('sc-message :name "kick"))

(defpart main
  (let ((len (oneof 0.33))
	(base (oneof 40 30 50)))
    (join-n (x 10)
      (seq
       (wobb :len 1 :sustain 1 :freq (* (+ x 1) base) :wobfreq 8)
       (wobb :len len :sustain len :freq (* (+ x (oneof 1.1 1.2 1.5 1.7)) base) :wobfreq 6)))))

(playloop main)

(playloop 
 (let ((len (oneof 0.33 0.5))
       (freq (+ 20 (* (random 13) 1.5))))
   (ass :len len
	:sustain len
	:wobfreq (* (/ 1 len) (1rand 3))
	(seq-n (y 2)
	  (join-n (x 8) (wobb :freq (* freq (+ x 1 y (random 2)) 
				       (if (zerop y) 1.3 1.9))))))))



(setf *kick*   "/mnt/fat/share/samples/drum_cd/Bass Drums/01_28_bdrum.wav"
      *snare*  "/mnt/fat/share/samples/drum_cd/Snares/GATE_SN_10.WAV"
      *hat*    "/mnt/fat/share/samples/drum_cd/Percussion/AFROBELL3.WAV"
      *pretto* "/mnt/fat/share/samples/kirk/2SoloStrings/KhsoSoloStringSamples1/s1B_EsVibFA#2.wav")

(sendnow (ks-load :path *kick*))
(sendnow (ks-load :path *snare*))
(sendnow (ks-load :path *hat*))


(progn
  (stoploop)
  (playloop drumma))

(defpart drumma
  (ass :len 0.5
       (join
	(ks-play :path *kick*)
	(seq (kick) (snare)))))

(sendnow (ks-play :path "/mnt/fat/share/samples/kirk/2SoloStrings/KhsoSoloStringSamples1/s1B_EsVibFA#2.wav"))