# Environment Variables
* **`$SPAM`**: Get the env var `SPAM`
* **`${...}`**: Get the entire environment (as a dict like object)
* **`${'SP'+'AM'}`**: Get the env var from an expression (eg, `SPAM`)
* **`$ARG0`, `$ARG1`, ... `$ARG9`**: Script command line argument at index n, ex:  run `xsh myscript.xsh hello world` then `$ARG1` will contain `'hello'`.
* **`$ARGS`**: List of all command line parameter arguments, ex: create `myscript.xsh` containing `print($ARGS)`, run ``xonsh myscript.xsh hello world``, and you will get `['myscript.xsh', 'hello', 'world']` as output.
* [Xonsh Environment Variables](http://xon.sh/envvars.html)

## Environment variable types
* **`$\w*PATH`**: list of strings
* **`$\w*DIRS`**: list of strings

# Subprocess

* **`$()`**: Captures output, returns stdout
* **`!()`**: Captures output, returns [CommandPipeline](http://xon.sh/api/proc.html#xonsh.proc.CommandPipeline)
  (Truthy if successful, compares to integers, iterates over lines of stdout)
* **`$[]`**: Output passed, returns `None`
* **`![]`**: Output passed, returns [CommandPipeline](http://xon.sh/api/proc.html#xonsh.proc.CommandPipeline)
* **`@()`**: Evaluate Python. `str` (not split), sequence, or callable (in the same form as callable aliases)
* **`@$()`**: Execute and split

* **`|`**: Shell-style pipe
* **`and`**, **`or`**: Logically joined commands, lazy
* **`&&`**, **`||`**: Same

* **`COMMAND &`**: Background into job (May use `jobs`, `fg`, `bg`)

## Redirection
* **`>`**: Write (stdout) to
* **`>>`**: Append (stdout) to
* **`</spam/eggs`**: Use file for stdin
* **`out`**, **`o`**
* **`err`**, **`e`**
* **`all`**, **`a`** (left-hand side only)

```
>>> COMMAND1 e>o < input.txt | COMMAND2 > output.txt e>> errors.txt
```

# Strings

* **`"foo"`**: Regular string: backslash escapes
* **`f"foo"`**: Formatted string: brace substitutions, backslash escapes
* **`r"foo"`**: Raw string: unmodified
* **`p"foo"`**: Path string: backslash escapes, envvar substitutions, returns `Path`
* **`pr"foo"`**: Raw Path string: envvar substitutions, returns `Path`
* **`pf"foo"`**: Formatted Path string: backslash escapes, brace substitutions, envvar substitutions, returns `Path`
* **`fr"foo"`**: Raw Formatted string: brace substitutions

# Globbing
* Shell-like globs: Default in subprocess
* **`` `re` ``**, **`` r`re` ``**: Glob by regular expression (Python and Subprocess)
* **``g`glob` ``**: Glob by wildcard (Python and Subprocess)
* **``@spam`egg` ``**: Glob by custom function `spam(s)` (Python and Subprocess)
* **`` pr`re` ``**: Glob by regular expression, returning `Path` instances
* **``pg`glob` ``**: Glob by wildcard, returning `Path` instances

# Help
* **`?`**: regular help, inline
* **`??`**: superhelp, inline

# Builtins
* **`compilex()`**:
* **`evalx()`**:
* **`execx()`**:

# Aliases
* **`aliases['g'] = 'git status -sb'`**
* **`aliases['gp'] = ['git', 'pull']`**
* **`aliases['gp'] = lambda ...: ...`** (See below)

## Callables
Forms:
* **`(args, stdin=None)`**: Strings, return `None`, `stdout`, or `stdout, stderr, return_value`
* **`(args, stdin, stdout, stderr)`**: file-like, return `return_value`
