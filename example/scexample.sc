
s.reboot;

(
SynthDef("basen", {|freq = 100, pan = 0, amp = 0.3, sustain = 1, wobfreq = 10 |

	var signal = [
		Saw.ar(freq + SinOsc.kr(Rand(0,100), 0, freq / 100)),
		Saw.ar(freq + SinOsc.kr(Rand(0,100), 0, freq / 100))];
		
	var lowpass = RLPF.ar(signal, SinOsc.ar(wobfreq, -0.1, 200, 360), 0.4);
	var env = EnvGen.kr(Env.linen(0.01, sustain, 0.01, 1, -4), doneAction: 2);

	Out.ar(0,lowpass * amp * env);
		
}).send(s);
)