killall sclang scsynth;
rm /tmp/sclangfifo;
mkfifo /tmp/sclangfifo;
tail -f /tmp/sclangfifo | sclang | grep -v ^DLL;

