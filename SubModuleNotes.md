## Using a submodule

It seems normal to be confused by git submodules.

### Updating already-establish submodule

Via [Vogella][Vogella]:

```bash
git pull --recurse-submodules
```

### Cloning a repo with submodules

Via [Vogella][Vogella]:

```bash
## Not yet cloned at all:
git clone --recursive git@github.com:USERNAME/REPONAME.git

## Cloned the 'parent', but forgot the --recursive flag:
git submodule update --init --recursive
```

### First time usage

Via [@VonC on StackOverflow][FirstTime] (git >= 1.8.2):

```bash
cd /my/parent/repo
## Add (this) submodule *AND* track Master:
git submodule add -b master git@github.com:VCF/installers.git
# update
git submodule update --remote 
```

### Advanced

There are options to have a submodule track specific branches or commits

[FirstTime]: https://stackoverflow.com/a/9189815
[Vogella]: http://www.vogella.com/tutorials/GitSubmodules/article.html
