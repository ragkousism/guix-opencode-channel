# guix-pi-channel

A Guix channel packaging [Pi Agent](https://github.com/Dicklesworthstone/pi_agent_rust),
a terminal coding agent written in Rust, and the pieces it needs that Guix
does not carry yet.

Add it with:

```scheme
(channel
  (name 'pi)
  (url "file:///home/manolis/repos/guix-pi-channel"))
```

## Why this one

Pi's dependency closure is 780 crates, 650 of which Guix already carries at
the exact version its lockfile pins.  That leaves 130 to import, against the
2416 npm packages -- with essentially no Guix coverage -- that packaging
opencode would have needed.
