# CS 362 In-Class Exercise 4: Project Beta Testing
- Their name: Charles Weber
- Project team number that you are testing (e.g., team 1): 3

## PART-1: Organization and Purpose (2 pts)
Q1) Does the repository provide a README explaining the purpose of the software? If
yes, based on reading that documentation, do you understand all the interesting
features provided by the software? Do you have any advice to improve that
documentation?  

Yes, The Team GitHub does provide a README.md.
I have read through the readme and I understand how the software works. The features are well
explained. Both the controls of the game and the features are listed and work as described. The
Game is intuitive and I don’t have any feedback for how to use it.  

## PART-2: Installation and Setup (1 pts)
Q2) Is the documentation to install or setup the software available? (Note that for a web
application, it would be a URL to access the website and instructions to host the website
on a server). When following the instructions, do you face any difficulties while installing
the software (accessing the URL for a website)? If yes, please explicitly state what
issues you encountered, so that the project team can fix them.
NOTE: If you are testing a web application, then you do not need to set up a web
server and try hosting the web application. Just go through the documentation to
find out if it clearly explains the steps to host the website.  

It should be noted that I am on ubuntu linux (Mint) and this project says it only works on
Windows and MacOS. It worked for me anyway.
I followed the install documentation and got the game running on my computer.
I installed the correct version of Godot and managed to open the file on my computer the same
way one would run it on Windows or MacOS
The installation and usage instructions are found in user-manual.txt.  

## PART-3: Functional and Non-Functional Testing (2 pts)
Q3) Select a use case for the application-under-test and use your creativity to test the
application in different possible ways. For example, if you are testing a login
functionality, then test the sign up feature, sign in, adding invalid credentials, special
characters, etc. Please provide the details of the use case you tested on the software by
describing exactly what all you did and in what order? Make sure you are making notes
while doing this. If you find any issues (e.g., something that was confusing, incorrect, or
not working at all), please provide as many details as you can to replicate the issues so
that the team can fix them.  

For my experimentation I will be selecting use case 1. I will experiment with the game in
sandbox mode and try to find bugs / break the game.
Please Note: My OS is not listed as supported so some of my issues may be problems that are
not specific to this project.  

- Error #1:
    An error I encountered was that I can’t move my camera while walking. When I start sprinting,
    the camera unfreezes and I can move it even after I stop sprinting.
    The error about not being able to rotate the camera while moving is consistent. When you are
    moving the camera and then press a movement key, the camera always freezes up.
    However, the camera is not frozen by sprinting. If you press the sprint key before pressing a
    movement key the camera can move freely. If you are moving with a frozen camera, sprinting
    will not unfreeze it.
- Error #2: –Kinda–
    When placing an “activator” (hotkey 4) and an incrementor (hotkey 5) along the same wire, they
    immediately crash the game. One of my group mates on an appropriate operating system was
    not able to recreate this, so this might be an OS incompatibility. I can’t consistently re-create this
    error myself so I don't know if this is worth investigating.
    Error message: E 0:01:21:609 _rotate_t: Invalid type in function '_get_grid_dir_to' in base
    'Area3D (wire.gd)'. The Object-derived class of argument 1 (previously freed) is not a subclass
    of the expected argument class.
    <GDScript Source>wire.gd:236 @ _rotate_t()
    <Stack Trace> wire.gd:236 @ _rotate_t()
    wire.gd:175 @ update_visuals()
    wire.gd:68 @ initialize_connections()
    flow_block.gd:31 @ _notify_adjacent_wires()
