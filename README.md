# Clerk - a simple todo list tool

Clerk is a tool for managing and filtering todo lists so that you can remain
focused on what you are doing (and not what's coming next).

## How it works

- Put tasks that belong to you in `$HOME/tasks.clerk`
- Put tasks that belong to projects you're working on in `<project dir>/tasks.clerk`
- Format your `tasks.clerk` files according to the syntax below
- Running `./clerk` will display
  - All the **active** tasks in your home directory (your user tasks)
  - AND all the **active** tasks in the current directory (your project tasks)
- Active tasks are tasks that have a status of: doing, monitoring or 'unknown_or_quick'

## Clerk file format

### Task status

One line equals one task. Tasks get a status based on the first character of the line...

```
. = todo
> = doing
? = monitoring (e.g. delegated, waiting, etc)
/ = shelved (e.g. paused or delayed)
x = done (yay!)
~ = cancelled
```

If the first character doesn't match any of the above then the task gets a status of 'unknown_of_quick'.
This is typically for things that you want to jot down to categorise later or are too quick to bother
with a long term category.

### Groups

You can organise tasks into groups, a group is a line starting with `::`, any task under that line
belongs to that group.

```
This task has no group
. So does this one

:: This is a group
> This is a task in the group
. This is another tak in the group

:: Some other group
. This is a task in a different group
```

## A note on versioning

This project is currently in 'version 0', there may be breaking changes in future.

## Building

`zig build-exe ./src/todo.zig`

## Soon

A better build script, more tests... see the tasks.clerk file :)
