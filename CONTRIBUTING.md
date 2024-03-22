# Contributing to RomWBW

> **WARNING**: The `dev` branch of RomWBW has been deprecated as of v3.4.  All Pull Requests should now target the `master` branch.

Contributions of all kinds to RomWBW are welcomed and greatly appreciated.

- Reporting bug(s) and suggesting new feature(s)
- Discussing the current state of the code
- Submitting a fixes and enhancements

## RomWBW GitHub Repository

The [RomWBW GitHub Repository](https://github.com/wwarthen/RomWBW) is the primary location for developing, supporting, and distributing RomWBW.  Although input is gladly accepted from almost any channel, the GitHub Repository is preferred.

- Use **Issues** to report bugs, request enhancements, or ask usage questions.
- Use **Discussions** to interact with others
- Use **Pull Requests** to submit content (code, documentation, etc.)

## Submitting Content

This RomWBW Project uses the standard [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow).  Submission of content changes (including code) are ideally done via Pull Requests.

- Submitters are advised to contact [Wayne Warthen](mailto:wwarthen@gmail.com) or start a GitHub Discussion prior to starting any significant work.  This is simply to ensure that submissions are consistent
  with the overall goals and intentions of RomWBW.
- All submissions should be based on the `master` branch.  To create your submission, fork the RomWBW repository and create your branch from `master`.  Make (and test) your changes in your personal fork.
- Please update relevant documentation and the `ChangeLog` found in the `Doc` folder.
- You are encouraged to comment your submissions to ensure your work is properly attributed.
- When ready, submit a Pull Request to merge your forked branch into the RomWBW master branch.

## Coding Style

Due to the nature of the project, you will find a variety of coding styles.  When making changes to existing code, please try to be consistent with the existing coding style.  You may not like the current style, but no one likes mixed styles
in one file/module.

Be careful with white space.  RomWBW is primarily assembly langauge code.  The use of tab stops at every 8 characters is pretty standard for assembler.  If you use something else, then your code will look odd when viewed by others.

In most cases, the use of `<cr><lf>` line endings is preferred.  This is standard for the operating systems of the era that RomWBW provides.  Also note that CP/M text files should end with a ctrl-Z (0x1A).  This is not magically added by the
tools that generate the disk images.

## License

RomWBW is licensed under GPLv3.  When you submit code changes, your submissions are understood to be under the same [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.html) that covers the project.
