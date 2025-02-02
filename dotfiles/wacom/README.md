# doc
https://gist.github.com/odysseywestra/8b2455acea34d7fe7776
https://ubuntu-mate.community/t/scale-your-wacom-tablet-to-a-single-monitor/8036
https://joshuawoehlke.com/wacom-intuos-and-xsetwacom-on-ubuntu-18-04/

# set wacom one pen offset
    $ xrandr
        HDMI-2 connected 1920x1080+3840+1080 (normal left inverted right x axis y axis) 294mm x 166mm

    $ xsetwacom --list devices
        Wacom One Pen Display 13 Pen stylus     id: 24  type: STYLUS
        Wacom One Pen Display 13 Pen eraser     id: 25  type: ERASER

    $ xsetwacom set "Wacom One Pen Display 13 Pen stylus" MapToOutput 1920x1080+3840+1080

# the draw tool: [xournalpp](https://xournalpp.github.io/)

	$ sudo apt-get install xournalpp

