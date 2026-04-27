# Project Development and Management Rules

This project follows these rules to maintain consistency and ensure stability in the AutoCAD 2013 environment.

## 1. Behavioral Guidelines
- Always use the following skill: `.agents\skills\core\karpathy-guidelines\skill.md`

## 2. File Structure and Command Registration
- **Lisp Source Path**: All functional Lisp (.lsp) files must be located in the `lisp-src/` directory.
- **Shortcut Registration**: When adding new features, the `Shortcuts.lsp` file must be updated with:
    - Shortcut command (Alias) definitions.
    - Implementation of the `util:lazy-load` function for optimized loading.
    - Updates to the `APPHELP` command help list.
- **Version Management**: Follow the `vX.Y.Z (YYYY-MM-DD)` format.
    - **Major (X.0.0)**: Major project reorganization or significant architectural changes.
    - **Minor (0.Y.0)**: Adding new Lisp (.lsp) features, registering new commands, or adding major utility functions.
    - **Patch (0.0.Z)**: Modifying existing logic, bug fixes, typo corrections, performance improvements, and other minor changes.
    - **Logging Principles**:
        - Document all changes in detail within `version-history.md`.
        - **Same-Day Updates**: If multiple changes occur on the same day, group them together and increment the version only once, based on the largest scope of change. **Ensure each change is documented uniquely and avoid creating redundant or identical entries for the same content within a single update.**

## 3. Interface Guidelines (Prevention of Freezing)
- **No Pop-ups**: Exclude all UI elements that open separate windows, such as `msgbox` and `inputbox`.
- **Command-line Centric**: All user interactions (input, selection, notifications) must be performed exclusively through the AutoCAD command-line prompt.

## 4. Surveying and Geometry Standards
- **Area Sign Convention**: Area calculation logic considers clockwise (CW) direction as positive (+).
- **Object Creation Rules**: Features involving transformations (e.g., area adjustment) must preserve the original object. Results should be represented by creating a new `ref_object` in **Green (Color Index: 3)**.

## 5. Code Implementation Standards
- **Utility Modularization**: Modularize common functions (e.g., area calculation, geometric operations) using the `util:` prefix.
- **File Encoding**: Save all `.lsp` files in `EUC-KR` encoding to ensure Korean characters are displayed and processed correctly in AutoCAD 2013.
- **Lazy Loading**: Maintain the practice of loading files only when the command is actually called to optimize memory efficiency.
- **Comments**: Write detailed comments in Korean.
- **Load Messages**: Each LISP file must end with a load completion message in the format `(princ "\n{Feature Summary} 濡쒕뱶 ?꾨즺.")`. Do not include the command name in this message.
- **Check Function Existence**: Always verify that a function is either built-in to AutoLISP or has been defined before using it.
- **LSP Readability Formatting Standard**:
    - Organize files with clear section headers using the `AreaAdjust.lsp` style (`[1]`, `[2]`, `[3]`).
    - Reformat long `setq`, `cond`, and `if/progn` blocks with line breaks so control flow is easy to scan.
    - Add or improve Korean comments that explain utility functions, core engine logic, and command execution stages.
    - Keep `Shortcuts.lsp` load message standardized as:
      `(princ "\n단축 명령어 시스템 로드 완료.")`

## 6. Deployment and Version Control
- **GitHub Upload**: Code uploads (Push) are not performed automatically and are only executed upon the user's explicit request.

