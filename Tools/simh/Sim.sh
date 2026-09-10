if ! command -v altairz80x >/dev/null 2>&1; then
    echo "SIMH AltairZ80 is not installed!"
    echo "Linux/MacOS distributions at https://schorn.ch/altair.html"
    exit 1
fi

ROM="../../Binary/SBC_simh_std.rom"

if [ $# -ge 1 ]; then
    ROM="../../Binary/$1.rom"
fi

if [ -f "$ROM" ]; then
    echo "Testing ROM $ROM on SIMH AltairZ80..."
    altairz80 Sim.cfg $ROM
else
    echo "ROM Image $ROM Not Found!"
fi
