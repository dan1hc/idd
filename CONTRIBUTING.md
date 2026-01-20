Contributing
============

* Step 1 - Create New Branch
* Step 2 - Clone Branch
* Step 3 - Make Changes
* Step 4 - Push & Create New PR
* Step 5 - Wait for Review / Approval

Commit Messages
---------------

Additionally, commit messages must adhere to [angular commit guidelines](https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#commits) (templates below).

#### _multi-line_

---

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

#### _single-line_

---

```
<type>(<scope>): <subject>
```

#### Special Rules

* `<subject>` as a pythonic `__dunder__` can be cool.
* `<subject>` must be appropriately descriptive of the change.
* If the multi-line template is used, at least one issue ref must be correctly [keyworded](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests) in the footer.


#### _regex_

---

```py
import re

pattern = re.compile(
    r'((^[mM]erge .*$)|(^((build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\(.+\))?!?: .+)((\n\n(.+)\n\n)((BREAKING CHANGE|DEPRECATED)(: )(.+)\n\n(.+))?(\n\n\nresolve[ds]? \#[A-Z0-9\-]+|fix(ed|es)? \#[A-Z0-9\-]+|close[ds]? \#[A-Z0-9\-]+)((, )(resolve[ds]? \#[A-Z0-9\-]+|fix(ed|es)? \#[A-Z0-9\-]+|close[ds]? \#[A-Z0-9\-]+))?)?)?$)|(^revert: ((build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\(.+\))?!?: .+)(\n\n(This reverts commit [a-z0-9]{40}\..*))(\n\n(fix(ed|es)? \#[A-Z0-9\-]+)((, )(fix(ed|es)? \#[A-Z0-9\-]+))?)?$)'
    )

assert bool(pattern.match('feat: __valid_example__\n\noptional body text\n\ncloses #1, resolve #2')) is True
assert bool(pattern.match('feat!: __new_stuff__\n\nbody text.\n\nBREAKING CHANGE: Breaks stuff.\n\nDetails on how stuff breaks and what to do.\n\n\nresolves #1')) is True
assert bool(pattern.match('revert: feat! __new_stuff__\n\nThis reverts commit 2c4ed28b069267f39974b5da50795c5210040e33. Because reasons.\n\nfixes #TKT-123')) is True
assert bool(pattern.match('test: __short_valid_example__')) is True

```
