# What is this?
Repetition is an algorithmic sequencer written in Common Lisp, at the moment it specifically targets
the Supercollider platform, but is compatible with anything that supports OSC.

# Requirements (lisp)
## SBCL
At the moment the osc library depends on sbcl/cmucl for float en/decoding
Also, using sb-bsd-sockets for sending the actual OSC messages. this should be trivially
portable, but i won't bother before i have portable OSC as well.

## kosc 
avaliable at [http://github.com/krl/kosc](http://github.com/krl/kosc)
this is a modified version of Nik Gaffney's original osc library, repackaged due to API breakage.

## sheeple
the object system used for events. 
[http://github.com/sykopomp/sheeple](http://github.com/sykopomp/sheeple/)

## cl-ppcre

# Non-lisp requirements
## Supercollider
In order to make use of most of the features you need a working supercollider/scsynth installed

# Example 

Here's a simple randomized drum loop, also in example/drumloop.lisp

    (use-package :repetition)
    (sclang-start)
    
    (defparameter *package-path* (namestring (asdf:system-relative-pathname :repetition "/example/samples/")))
    
    ;; Samples from altemark@freesound  http://www.freesound.org/packsViewSingle.php?id=2288
    ;; license: cc Sampling Plus 1.0    http://creativecommons.org/licenses/sampling+/1.0/
    (load-samples =bd=    (concatenate 'string *package-path* "bd.wav")
    		  =snare= (concatenate 'string *package-path* "snare.wav")
                  =side=  (concatenate 'string *package-path* "side.wav")
    	          =ch=    (concatenate 'string *package-path* "ch.wav")
    	          =oh=    (concatenate 'string *package-path* "oh.wav"))
    
    (play 
      (join
        ;; kick
        (oneof (lenlist 0.5  =bd=
                        0.5  =bd=)
               (lenlist 0.25 =bd=
    			0.75 =bd=))
    
       ;; snare/rim
       (ass ((pan 0.4))
         (oneof (offset 1 =snare=)
    	    (offset 0.75 
    	      (lenlist 0.25 =side=
    		       1    =snare=))))
    
       ;; pan left
       (ass ((pan -0.4))    
         ;; closed hihat random pattern
         (seq-len 2
           (ass ((len (oneof 0.5 0.25))
                 (amp (+ 0.3 (random 0.4))))
	     =ch=))
         
         ;; open hihat
         (offset (oneof 1.75 1.5)
           (ass ((len 0))
	       	 =oh=)))))
    
# What does it sound like?

[Something like like this.](http://rymdkoloni.se/example.ogg) (ogg)

# So what's going on?

In the background the load-samples macro tells the Supercollider server to load the samples
and prepare objects for them.

The play macro then takes sequences of events and structures and evaluates them to get the list
of osc messages it needs to send out. 

In this example the following language functions are used:

## oneof
Oneof randomly returns one of it's arguments, the others are left un-evaluated. Useful for adding
complexity.

## join
Join takes a list of events or sequences and puts them together without altering them in any way.

## seq 
Join takes a list of events or sequences and puts them together end-to end.

## seq-length
Join takes a list of events or sequences and puts them together until they make up a length of 
the value of the first argument.

## ass
This is the assignment filter, it takes a list of lists the form (key value) and applies to every
event in its argument list. The arguments themselves are implicitly joined.

If the value is a function, it will be called once for every event that it sets the value for.

## lenlist
This is a special macro that expands to length-assignments of (all) its underlying events. useful
for creating ad-hoc rythms.

# Supercollider integration example

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

This is where the supercollider integration shows up.

Synthdef takes a event name, arguments and the definition of the synth.

! is a reader macro used to convert s-expressions into supercollider code for those of 
us allergic to curly braces. The above macro expands into:

    "Out.ar(0, (EnvGen.kr(Env.perc(0.05, len, 1, -4), doneAction: 2) * [Saw.ar((freq + Rand(0.0, 1.0))), Saw.ar((freq + Rand(0.0, 1.0)))]))" "Out.ar(0, (EnvGen.kr(Env.perc(0.05, len, 1, -4), doneAction: 2) * [Saw.ar((freq + Rand(0.0, 1.0))), Saw.ar((freq + Rand(0.0, 1.0)))]))"

Otherwise we just have two new language features, join-nv and seq-nv + the helper function sq1

## join/seq-nv
these take a variable name and a list, and joins or sequences together it's body, binding the variable
to each one of the lists members.

# That's all for now

Still lots of development and documentation to be done, but this is fun to play with already and feedback would be appriciated, show up in #repetition on freenode or just send me a mail.
