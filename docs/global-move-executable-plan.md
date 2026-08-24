# Global Move Executable Plan

## Objective

Make a Linux/macOS command moved with `mkscript -mv -g SOURCE TARGET`
executable when the global symlink is created, and support existing directory
targets by moving the source into that directory with its original basename.

## Confirmed Current Behavior

`move_script` captures the source mode and restores that exact mode after the
move. When the source file is not executable, `-g` creates a global symlink to
a non-executable target. The command therefore cannot be run through the
global symlink.

Move mode currently rejects every existing target, including directories. It
does not resolve `mkscript -mv -g myfile myscripts` to `myscripts/myfile`.

## Implementation Steps

1. Change only the Linux/macOS permission path so `-mv -g` adds user execute
   permission to the moved target before creating its global symlink.
2. Preserve current permission behavior for `-mv` without `-g`, including the
   existing exact-mode preservation contract.
3. On every platform, resolve an existing directory target to
   `TARGET/basename(SOURCE)` before validating the destination. Refuse the
   operation if that resolved path already exists or cannot be created.
4. Use the resolved destination consistently for move output, global-link or
   wrapper naming, collision checks, and source-link replacement.
5. Before moving, display the resolved source and destination and require an
   explicit affirmative confirmation. A declined confirmation must leave both
   paths and any global shortcut unchanged.
6. Add tests for a non-executable source moved with `-mv -g`, verifying the
   moved file is executable and the global symlink resolves to it; add tests
   proving a directory target retains the source basename, confirmation uses
   the resolved destination, cancellation changes nothing, and a conflicting
   file in that directory is refused.
7. Update the README, man page, and help text to document directory-target
   behavior and that `-mv -g` makes the moved Linux/macOS target executable.
8. Run the complete test suite, ShellCheck, documentation checks, metadata
   validation, and whitespace validation before committing.

## Scope Boundaries

- No change to Windows wrapper behavior or Windows file-mode semantics;
  Windows receives only the shared directory-target and confirmation behavior.
- No change to `-mv` without `-g`.
- No change to global-link behavior for newly created scripts.

## Acceptance Criteria

- A non-executable Bash source becomes executable after
  `mkscript -mv -g SOURCE TARGET` on Linux/macOS.
- The global symlink points to the moved target and can be invoked.
- `mkscript -mv -g myfile myscripts` produces `myscripts/myfile` when
  `myscripts` is an existing directory and that destination is unused.
- The global shortcut name is based on the retained `myfile` basename.
- An existing `myscripts/myfile` is refused without overwriting it.
- Every move shows its fully resolved destination and proceeds only after an
  affirmative confirmation; declining does not move, chmod, create, remove,
  or modify a global shortcut or wrapper.
- A move without `-g` retains the source mode unchanged.
- Windows directory-target moves retain the source basename, request
  confirmation, and update managed wrappers using the resolved target.
