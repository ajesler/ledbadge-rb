# ledbadge-rb

This is a basic ruby script for controlling a B1236 LED badge. These were given out at Codemania 2012 as name tags for attendees. 

Run the script like so:

    ajesler@ubuntu$ruby messages.rb "Codemania was awesome!"

By default, the message will be displayed scrolling across the badge at maximum speed.
To set a message that "snows" down at a slow speed, try the following:

    ajesler@ubuntu$ruby message.rb --speed 1 --action SNOW "Hi!"

It defaults to assuming the badge is connected to `"/dev/ttyUSB0"` on linux. You can override this with the `device` option like so:

    ajesler@ubuntu$ruby message.rb --device "/dev/ttyUSB1" "Connected to a different device port."


This requires you to have `gem` installed, as the trollop and serialport gems are required.

Has not been tested on Windows or OSX yet. Windows may require the install of a driver for the device. The driver is included in the badgesoftware zip (http://codemania.co.nz/badgesoftware.zip). This has the manufacturers program for programming the badge and supports all badge funtionality.


## Badge Documentation 

The badges have a 12 x 36 matrix of LEDs. Messages can be up to 250 characters long.

Two images of up to 12x384 can be loaded onto the badge. They must be monochrome, with black pixels being LED off, and white pixels being LED on.
These images may be scrolled, allowing for 10 frames of animation of a scene 12x36. When using both images, 20 frames of animation of may be produced.

See http://www.codemania.co.nz/badge.html for some resources, including a truly awful "description" of the protocol used to control the badge.

http://zunkworks.com/ProgrammableLEDNameBadges has information on several LED badges. The relevant badge is the last one listed on the page.

Thanks to Dave Leaver (@danzel) for getting the original serial capture from the manufacturers program that allowed the reverse engineering of the protocol. 
https://github.com/danzel/CodemaniaBadge/tree/master/Documentation has his documentation on how it was done.

## TODO

- Support for loading messages without immediately displaying the message
- Support for uploading of multiple messages at once.
- Support message order definition eg msg 2,3,4
- Support for the bold font text display
- Add documentation to methods and classes
- Add support for writing images to the badge


## Other libraries

* https://bitbucket.org/bartj/led - C# by bartj
* https://github.com/danzel/CodemaniaBadge - A C# game for four badges by danzel
* https://github.com/ghewgill/ledbadge - Python by ghewgill

If you know of any others that exist, please let me know.