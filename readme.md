# ledbadge-rb

This is a basic ruby script for controlling a B1236 LED badge. These were given out at Codemania 2012 as name tags for attendees. 

Run the script like so:

    ajesler@ubuntu$ruby messages.rb "Codemania was awesome!"

By default, the message will be displayed scrolling across the badge at maximum speed.
To set a message that "snows" down at a slow speed, try the following:

    ajesler@ubuntu$ruby message.rb --action SNOW "Hi!"

It defaults to assuming the badge is connected to `"/dev/ttyUSB0"` on linux. You can override this with the `device` option like so:

    ajesler@ubuntu$ruby message.rb --port "/dev/ttyUSB1" "Connected to a different serial port."

It is possible to upload multiple messages, using the `B1236Badge.set_messages` method. Input is a 2d array, with the first cell of each nested array holding the string message, and the second holding an optional hash with message options.

eg 

    m1 = "Test 1"
    m2 = "Test 2"
    m3 = "Test 3"
    m4 = "Test 4"
    m5 = "Test 5"
    m6 = "Test 6"
    
    messages = [[m1], [m2, {:speed => 1}], [m3, {:action => LedActions::SNOW}], [m4], [m5], [m6]]
    badge.set_messages messages

This will cycle through all 6 messages, with the second message being displayed slowly, and the third displayed in the snowing action. It is not currently possible to then update only a single message, you must reset all messages if you want to change any of them. 


ledbadge-rb requires you to have `gem` installed, as the `trollop` and `serialport` gems are required.

Has not been tested on Windows or OSX yet. Windows may require the install of a driver for the device. The driver is included in the badgesoftware zip (http://codemania.co.nz/badgesoftware.zip). This has the manufacturers program for programming the badge and supports all badge funtionality.

### Example Usage

For an example program using the badge code, see `https://gist.github.com/2291504`. This integrates with Skype on Windows to display the number of missed messages, or the last missed message. 

To use, download the three files in the gist above, and then run like so `ruby display-unread-message-count.rb "COM4"` or `ruby display-last-missed-message.rb "COM4"`

## Badge Documentation 

The badges have a 12 x 36 matrix of LEDs. Messages can be up to 250 characters long.

Two images of up to 12x384 can be loaded onto the badge. They must be monochrome, with black pixels being LED off, and white pixels being LED on.
These images may be scrolled, allowing for 10 frames of animation of a scene 12x36. When using both images, 20 frames of animation of may be produced.

See http://www.codemania.co.nz/badge.html for some resources, including a truly awful "description" of the protocol used to control the badge.

http://zunkworks.com/ProgrammableLEDNameBadges has information on several LED badges. The relevant badge is the last one listed on the page.

Thanks to Dave Leaver (danzel on GitHub) for getting the original serial capture from the manufacturers program that allowed the reverse engineering of the protocol. 
https://github.com/danzel/CodemaniaBadge/tree/master/Documentation has his documentation on how it was done.

My notes on reversing the protocol are located in docs/*-protocol.txt files.


## TODO

### Features
- Add a debug mode that prints out data that is sent, etc. Remove from default code.
- Writing images to the badge
- Update a single message when multiple are being displayed. Manufacturers program does not seem able to do this, so not sure if possible. 
- Allow use of special animated characters (star,heart,left,right,phone1,phone2,smile,circle,taiji,music,question,full)
- Add documentation to methods and classes
- Update tests to reflect changes to badge.rb

### Bugs
None active

### Completed / Fixed
- ~~Feature - Support for uploading of multiple messages at once.~~
- ~~BUG - Remove the X from displaying when setting the message. The manufacturers program does not do this.~~
- ~~BUG - Issues when sending messages of length 10 to the device? - message is sent, but badge get stuck showing the X, never shows the new message. Possibly also 14.~~
- ~~Feature - Enable messages to use the bold font.~~


## Other libraries

* https://bitbucket.org/bartj/led - C# by bartj
* https://github.com/danzel/CodemaniaBadge - A C# game for four badges by danzel. Has partial support for images.
* https://github.com/ghewgill/ledbadge - Python by ghewgill

If you know of any others that exist, please let me know.