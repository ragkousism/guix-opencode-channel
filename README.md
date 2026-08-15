# guix-llm

A Guix channel for programs built on large language models -- coding agents
for now, and the pieces they need that Guix does not carry yet.

```scheme
(channel
  (name 'llm)
  (url "file:///home/manolis/repos/guix-llm"))
```

## Packages

| Package | What it is |
| --- | --- |
| `pi` | Pi Agent, built from source: all 780 crates, no prebuilt binaries |
| `opencode` | opencode, built from source as far as packaging can reach |
| `opencode-bin` | opencode's upstream release binary, unmodified |
| `rust-1.95` | one link past the rust-1.94 Guix carries; pi needs it |
| `bun-from-source` | bun, built from source through a bootstrap chain |
| `emscripten`, `web-tree-sitter-wasm`, `tree-sitter-wasm-grammars` | native artefacts opencode would otherwise download prebuilt |
| `libopentui`, `librust-pty`, `parcel-watcher-node`, `solid-js-from-source` | the same, for opencode's JavaScript dependencies |

## Which opencode

`opencode` is built from source and `opencode-bin` is not, and the difference
is not only principle.  Building from source needs a node_modules tree this
machine happens to have: opencode's dependency closure is 2416 npm packages,
Guix carries almost none of them, and 63 are packaged here.  So `opencode`
builds here and nowhere else.  `opencode-bin` builds anywhere, at the cost of
being someone else's build.

`pi` has no such caveat.  Its closure is 780 crates, Guix already carried 650
of them, and the remaining 130 are in this channel -- so it builds from source
on any machine.  That difference is why it is here.

## Notes

`opencode-bin` is patched only to point at this channel's libc.  It is a bun
single-file executable, which carries its payload appended to the ELF image,
so `--set-rpath` or `--remove-needed` shifts that payload and segfaults the
result; setting the interpreter alone leaves it intact.
