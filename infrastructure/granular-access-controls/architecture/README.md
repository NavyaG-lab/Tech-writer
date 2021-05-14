---
owner: "#project-granular-access-control"
---

# Architecture diagrams of GAC

## Render and save all diagrams

```bash
make
```

## Force rerender

```bash
make clean
```

## Add a githook

Make sure you don't commit without refreshing. Run in this directory:

```bash
ln -s $(realpath pre-commit.githook) ../../../.git/hooks/pre-commit
```
