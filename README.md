# capture.vim

Show Ex command output in a buffer

# Example

* Show all defined mappings in a buffer (you can search them).

```viml
:Capture map | map! | lmap
```

* Show echoed messages again in a buffer.

```viml
:Capture mes
```

* Show installed scripts in a buffer.

```viml
:Capture scriptnames
```

* Import an external command's output to a buffer (like `new | r!ls`).

```viml
:Capture !ls
```

* Show currently defined digraphs in a buffer.

```viml
:Capture digraphs
```
