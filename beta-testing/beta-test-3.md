# Beta Testing Feedback Document
- Name: Arjun Rahul Bhave

## Q1: Was the purpose of the software clear? Was installation and setup straightforward?

The purpose of the software is clearly described in the README. Coding Cubed is designed
to help users learn programming fundamentals through video game logic and puzzles using
a sandbox-style environment.  

The README provides clear instructions on how to build, test, and run the system. The
build instructions reference GitHub Actions workflows, which are appropriate for CI/CD
validation. The run instructions direct users to download the game from an external hosting
platform (itch.io) and provide OS-specific download options.
However, full installation testing could not be completed within this environment because
the downloadable files are hosted externally. The instructions themselves are structured
clearly and appear complete.  

## Q2: Was the system usable and understandable based on documentation?

The top-level README is well organized and includes sections for documentation, bug
reporting, repository layout, build instructions, and gameplay instructions.
The gameplay instructions are detailed and explain controls such as movement (WASD),
block placement, interaction keys, and hotbar usage. This makes the intended user
interaction clear even without launching the application.  

The repository structure is logical, with separate folders for source code (coding-cubed/),
reports, and documentation files. The inclusion of a user manual and developer
documentation improves clarity.  

One improvement would be adding screenshots or a short demo GIF in the README to
visually demonstrate gameplay and block interactions.  

## Q3: Which use cases are operational? Describe how you tested them.
The README lists the following demo use cases:
    1. Download the game
    2. Open Sandbox mode
    3. Place hotbar selections (blocks 1–5)
    4. Interact with blocks using 'i'
    5. Input variable values
    6. Configure if blocks and increment blocks  
    
Testing Performed:
    - Verified that the README includes clear steps for downloading and launching the
    application.
    - Confirmed that Sandbox mode and hotbar functionality are documented with control
    mappings.
    - Reviewed documentation for variable block, if block, and increment block input behavior.
    - Verified repository includes source files under coding-cubed/ directory, indicating
    implementation exists for listed features.
    Because the executable is hosted externally, runtime validation of gameplay features was
    not performed in this environment. However, based on documentation and repository
    structure, the listed use cases appear to be implemented.