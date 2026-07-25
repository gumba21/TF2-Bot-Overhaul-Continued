# SourcePawn Navigation Mesh Parser

Pinned from  at commit .

This GPL-3.0 dependency parses Valve  files in SourcePawn and exposes TF2 nav areas, adjacency, bounds, portals, grids, and path primitives without a platform-specific engine extension. The original copyright notices remain in ; the upstream license is preserved in .

Local integration changes should remain isolated from the vendored parser. Tactical scoring and bot decisions live in  and its  modules.

## Local SourcePawn 1.12 compatibility patch

The vendored source changes only native callback typing required by SourcePawn 1.12:

- pass dynamic cost callbacks as generic `Function`
- return float native values through the native cell representation
- use `any` and explicit zero returns for output-only native callbacks

Nav parsing, graph data, and path behavior are otherwise unchanged.
