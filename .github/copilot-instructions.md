<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->
- [x] Verify that the copilot-instructions.md file in the .github directory is created.

- [x] Clarify Project Requirements
	<!-- MacBook 2015 SPI touchpad/keyboard driver for Linux kernel 6.14.0-32-generic, C language, DKMS framework -->

- [x] Scaffold the Project
	<!-- Created project structure with src/, patches/, Makefile, dkms.conf, build script, and documentation -->

- [x] Customize the Project
	<!-- Applied kernel 6.14 compatibility fixes: input-polldev removal, platform driver remove function signature changes, ACPI driver compatibility -->

- [x] Install Required Extensions
	<!-- No specific extensions required for C kernel module development -->

- [x] Compile the Project
	<!-- Compilation must be done on target Linux system with kernel 6.14. Build script and instructions provided in build.sh and INSTALL.md -->

- [x] Create and Run Task
	<!-- Build tasks handled by Makefile and build.sh script. No VS Code tasks needed for kernel module development -->

- [x] Launch the Project
	<!-- Kernel module deployment requires sudo privileges on target Linux system. See INSTALL.md for deployment instructions -->

- [x] Ensure Documentation is Complete
	<!-- README.md, INSTALL.md, SPI_TROUBLESHOOTING.md, and build.sh provide comprehensive documentation -->

<!--
## MacBook 2015 SPI Driver Development Project

### Technical Context
- Target Hardware: MacBook8,1 (2015 12-inch MacBook)
- Operating System: Ubuntu 24.04 with kernel 6.14.0-32-generic
- Primary Issue: SPI touchpad/keyboard driver compatibility with kernel 6.14
- Current Status: Built-in applespi driver loads but fails with SPI timeout errors (-110)

### Project Objectives
1. Obtain recent applespi driver source code
2. Apply kernel 6.14 API compatibility fixes
3. Resolve SPI communication timeouts
4. Create portable laptop functionality (no external USB dependencies)

### Known Technical Challenges
- IIO API changes in kernel 6.14
- Platform driver remove function signature changes
- HID report_fixup signature incompatibilities  
- ACPI driver API modifications
- SPI transfer struct changes
- EFI variable API updates
- SPI timing issues with MacBook8,1 hardware

### Development Tools Required
- C compiler toolchain
- Linux kernel headers (6.14.0-32)
- DKMS framework
- Git for source management
- Make/build tools

## Execution Guidelines
PROGRESS TRACKING:
- If any tools are available to manage the above todo list, use it to track progress through this checklist.
- After completing each step, mark it complete and add a summary.
- Read current todo list status before starting each new step.

COMMUNICATION RULES:
- Avoid verbose explanations or printing full command outputs.
- If a step is skipped, state that briefly (e.g. "No extensions needed").
- Do not explain project structure unless asked.
- Keep explanations concise and focused.

DEVELOPMENT RULES:
- Use '.' as the working directory unless user specifies otherwise.
- Avoid adding media or external links unless explicitly requested.
- Use placeholders only with a note that they should be replaced.
- Use VS Code API tool only for VS Code extension projects.
- Once the project is created, it is already opened in Visual Studio Code—do not suggest commands to open this project in Visual Studio again.
- If the project setup information has additional rules, follow them strictly.

FOLDER CREATION RULES:
- Always use the current directory as the project root.
- If you are running any terminal commands, use the '.' argument to ensure that the current working directory is used ALWAYS.
- Do not create a new folder unless the user explicitly requests it besides a .vscode folder for a tasks.json file.
- If any of the scaffolding commands mention that the folder name is not correct, let the user know to create a new folder with the correct name and then reopen it again in vscode.

EXTENSION INSTALLATION RULES:
- Only install extension specified by the get_project_setup_info tool. DO NOT INSTALL any other extensions.

PROJECT CONTENT RULES:
- If the user has not specified project details, assume they want a "Hello World" project as a starting point.
- Avoid adding links of any type (URLs, files, folders, etc.) or integrations that are not explicitly required.
- Avoid generating images, videos, or any other media files unless explicitly requested.
- If you need to use any media assets as placeholders, let the user know that these are placeholders and should be replaced with the actual assets later.
- Ensure all generated components serve a clear purpose within the user's requested workflow.
- If a feature is assumed but not confirmed, prompt the user for clarification before including it.
- If you are working on a VS Code extension, use the VS Code API tool with a query to find relevant VS Code API references and samples related to that query.

TASK COMPLETION RULES:
- Your task is complete when:
  - Project is successfully scaffolded and compiled without errors
  - copilot-instructions.md file in the .github directory exists in the project
  - README.md file exists and is up to date
  - User is provided with clear instructions to debug/launch the project

Before starting a new task in the above plan, update progress in the plan.
-->
- Work through each checklist item systematically.
- Keep communication concise and focused.
- Follow development best practices.
