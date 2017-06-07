# capture.vim

Show Ex command output in a buffer

# Example

* Write all defined mappings to a buffer (you can search them).

```viml
:Capture map | map! | lmap
```

* Show installed scripts in a buffer.

```viml
:Capture scriptnames
```

* Import an external command's output to a buffer (like `new | r!ls`).

```viml
:Capture !ls
```
