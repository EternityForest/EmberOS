# EmberOS FS Binding Engine

## Purpose

To manage a large number of bindings and ensure they are ordered correctly.


### Simple and complex

#### Simple

There are two types of binding. A simple binding is a just a string entry:

```
/foo/somewhere: bar
```

Which uses a bind mound to make foo available at bar. 

The one advanced thing that does happen, is that if the source happens to be under
the source of a Complex binding, it is remapped.

Say another binding made /foo/ available at /baz, the binding would become:

/baz/somewhere:bar

This is because we consider the remapped location to be a "better" version,
that has the correct permissions we wish to apply.


#### Complex
A complex binding is a parameterized BindFS or Overlayfs mount, always represented as a dict.

```
/source:
    bindat: /place/to/bind
    user: pi 
    mode: 0755
    bindfiles:
        foo: /blah
```

Makes /source available at /place/to/bind, and /place/to/bind/foo available at /blah.


### File structure

You can have multiple bindings per file. You can even represent one binding in multiple different files.

They all get merged before anything happens.  However, only bindfiles may be duplicated.

All other keys can only occur in one file, or there would be a conflict.

### Overlayfs

The special source __tmpfsoverlay__SomeUniqueName can be used as a binding source.

It will put a ramdisk overlayFS on top of the target.


## Ordering

Complex bindings happen first, then simple and bindfiles.

Bindings are always ordered by the length of the target, such that outer directory targets are
bound before inner, so that the outer ones don't cover up the inner.

It doesn't matter what file a binding comes from, they are merged, sorted, and done all at once.