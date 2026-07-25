# SourcePawn Navigation Mesh Parser

Pinned from `KitRifty/sourcepawn-navmesh` at commit `2179f82ea57410a8840cef6f85b1f66e78f54657`.

This GPL-3.0 dependency parses Valve `.nav` files in SourcePawn and exposes TF2 nav areas, adjacency, bounds, portals, grids, and path primitives without a platform-specific engine extension. The original copyright notices remain in `navmesh.sp`; the upstream license is preserved in `LICENSE`.

Local integration changes remain isolated from the vendored parser. Tactical scoring and bot decisions live in `bot_navigation.sp` and its `navigation/` modules.

## Local SourcePawn 1.12 compatibility patch

The vendored source changes only native callback typing required by SourcePawn 1.12:

- pass dynamic cost callbacks as generic `Function`
- return float native values through the native cell representation
- use `any` and explicit zero returns for output-only native callbacks

Nav parsing, graph data, and path behavior are otherwise unchanged.
