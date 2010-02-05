killall sclang scsynth;
/tmp/sclangfifo;
mkfifo /tmp/sclangfifo;
tail -f /tmp/sclangfifo | sclang;

