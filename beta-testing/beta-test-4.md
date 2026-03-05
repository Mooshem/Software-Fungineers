# CS 362 In-Class Exercise 4: Project Beta Testing
- Their name: Abram Gallup

## PART-1: Organization and Purpose (2 pts)
Q1) Does the repository provide a README explaining the purpose of the software? If
yes, based on reading that documentation, do you understand all the interesting
features provided by the software? Do you have any advice to improve that
documentation?  

The readme file does explain the purpose of the software, and I understand that it teaches the
user how to program through a video game.
This is all I can gather from the readme file. I am not sure what features the software has or
what the game looks like since it's just a brief description. More importantly I don’t know what
the genre of the video game is or the type of game it is (first person, open world, etc).
The user manual does give a more detailed description of the software and its features. From
the user manual I know it's a 3-D world with blocks you can place.
I would add a couple pictures, one of the main menu and maybe one of the gameplay to get a
better idea of what the software is and the kind of game to expect.
You could also add what coding concepts that can be explored and learned in the readme file.  

## PART-2: Installation and Setup (1 pts)
Q2) Is the documentation to install or setup the software available? (Note that for a web
application, it would be a URL to access the website and instructions to host the website
on a server). When following the instructions, do you face any difficulties while installing
the software (accessing the URL for a website)? If yes, please explicitly state what
issues you encountered, so that the project team can fix them.
NOTE: If you are testing a web application, then you do not need to set up a web
server and try hosting the web application. Just go through the documentation to
find out if it clearly explains the steps to host the website.  

Under the “How to Build and Test the System” it says to select ‘run workflow’ but I can’t find the
option to run the workflow.
I’m sure you already know this but the link https://tehlamo.itch.io/coding-cubed does not work.
So I can’t download the .zip file from it. So from here I had to deviate from the setup and run
instructions in the readme file and looked at the developer documentation.
The developer documentation is great, I was able to install the gadot engine and then correctly
imported the correct project.godot file and ran the program. This may be difficult for a user who
is just starting to code and is unfamiliar with how to find and install the gadot engine and which
file to import to the engine. Making it a little more clear with a picture of the coding cubed
directory open and an arrow pointing to the project.gadot would be good.  

## PART-3: Functional and Non-Functional Testing (2 pts)
Q3) Select a use case for the application-under-test and use your creativity to test the
application in different possible ways. For example, if you are testing a login
functionality, then test the sign up feature, sign in, adding invalid credentials, special
characters, etc. Please provide the details of the use case you tested on the software by
describing exactly what all you did and in what order? Make sure you are making notes
while doing this. If you find any issues (e.g., something that was confusing, incorrect, or
not working at all), please provide as many details as you can to replicate the issues so
that the team can fix them.  

From testing the Use case for Demo everything was able to work. I was able to do all the steps
(1 - 7).
    1. Sandbox button worked every time
    2. Hotbar worked everytime
    4. Interacting with blocks worked everytime
    5. Placing blocks worked, even when running, jumping, spinning.
    6. Breaking blocks worked everytime
    7. WASD, space, shift, ESC, all worked every time.  

One little bug I noticed was when I was walking around AND trying to look around, the view
angle would not change after a quick swipe on the track pad. When I held my finger on the
keyboard and continually tried to look around after a 1 or 2 seconds the view angle would then
change as I am moving around.  

It was hard to remember what each hotbar item was, so a label would be nice. I understand I
was in sandbox mode, but explaining the functionality of each block so I know how to use them
would be helpful.
