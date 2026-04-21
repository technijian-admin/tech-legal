---
name: volatility
description: Manually set the volatility (stable/evolving/ephemeral) of a topic. Usage — /volatility <topic-filename> <level>
---

Arguments: `$ARGUMENTS` — expected format: `<topic-filename> <stable|evolving|ephemeral>`

Steps:

1. Parse the arguments. If missing or malformed, show usage and list all topic filenames from `claude-memory/topics/`.

2. Resolve the target topic file at `C:/Users/rjain/OneDrive - Technijian, Inc/Documents/obsidian/tech-legal/claude-memory/topics/<filename>` (accept with or without `.md` suffix).

3. Read the file. Extract current `volatility` value from frontmatter.

4. If new value == current value, print "already <level>" and exit.

5. Update `volatility:` line in frontmatter. Also bump `last_updated` to today.

6. Append entry to `claude-memory/CHANGELOG.md`:
   ```
   - `[volatility]` <topic-filename>: <old> → <new>. Reason: <ask user in one line, or mark "manual classification">.
   ```

7. Commit to vault git with message `[volatility] <topic>: <old> -> <new>`.

8. Print confirmation with the new frontmatter.

No other content changes. This command is surgical.
