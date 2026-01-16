
## Introduction

littlefs is a little filesystem targeting microcontrollers---small
devices with MiBs of ROM, KiBs of RAM, and, thanks to increasing storage
density, potentially GiBs of storage. With block sizes in the range
of ~128KiB-1MiB, block-based CoW algorithms are slow, and RAM-dependent
algorithms impossible. To support increasingly dense storage, we are
trying to find a flexible B-tree with the following constraints:

1. Strictly bounded-RAM, i.e. no non-tail recursion
2. RAM usage independent of block size
3. Does not rely on full block rewrites

These constraints rule out traditional array-backed B-trees, which rely
on rewriting full blocks, and log-backed B-trees such as those found in
bcachefs, which rely on reconstructing logs in-RAM.

Previous versions of littlefs avoided B-trees for these reasons, however
this has proven problematic for performance. In littlefs3, we are
exploring an alternative B-tree built on log-encoded binary trees
pioneered by the Dhara FTL. This so-called
_red-black-yellow Dhara (rbyd) B-tree_ provides a flexible incremental
B-tree in bounded-RAM, with support for both sparse keys and
order-statistic ranges.

## Design

The core idea is to replace the inner nodes of traditional B-trees with
rbyd trees---a self-balancing order-statistic variant of the Dhara tree
implemented in the Dhara FTL. The result is a flexible B-tree, with
inner nodes that can be manipulated incrementally without being read
into RAM.

The original Dhara tree implements a radix tree, and while it is
possible to extend the radix tree into a B-tree, the resulting B-tree is
relatively inflexible. Augmenting a traditional B-tree with sparse keys
and order-statistic ranges does not change the $O(b) \rightarrow O(b)$
runtime for block size $b$, but attempting the same transformation on
the emulated arrays in a Dhara B-tree increases the runtime
$O(\log b) \rightarrow O(b \log b)$.

To solve this, we need to extend the sparse and order-statistic
properties into the Dhara tree itself. Our solution is a
_red-black-yellow Dhara (rbyd) tree_, in which we use colors to emulate
the inner branches of a 2-3-4 tree, mimicking a traditional red-black
tree. This provides self-balancing and order-statistic operations, while
remaining strictly tail-recursive.

The extension of rbyds into a full B-tree is relatively straightforward.
Rbyds contain either leaf data or indirect B-tree pointers, and most
updates require only a cheap log append. When a log is full, we
_compact_ the relevant rbyd into a new block, at which point the CoW
semantics of B-trees take over. To avoid runaway compactions, we split
when a node is half-full, but only when compaction is necessary. This
amortizes compaction work, introduces hysteresis, and results in optimal
leaf distribution after sequential writes.

The main downside of rbyds is increased storage overhead, however a
tail-recursive rebalancing algorithm brings compacted cost down
$O(b \log b) \rightarrow O(b)$. In our current implementation, the
overhead of rbyds divides the branching-factor by ~1/8 over dense arrays.

## Results and Discussion

Rbyd B-trees are currently implemented as the main file data-structure
in littlefs3. They have survived significant testing with assertions
over the rbyd color-invariants, and simulated measurements show the
expected logarithmic runtimes.

Measuring simulated write throughput shows improved performance
characteristics around larger block sizes in littlefs3 when compared to
littlefs2. While littlefs2's performance degrades as block size
increases, littlefs3's performance generally improves due to reduced
metadata overhead.

However, the more complex file data-structure is not without downsides.
Static analysis shows littlefs3's code increasing from
16.9KiB $\rightarrow$ 34.5KiB, and RAM increasing from
2.0KiB $\rightarrow$ 2.8KiB. This includes unrelated changes, but we
believe the added file complexity is the main culprit.

For future work, we will be looking to better understand overall
filesystem performance---focusing on throughput and latency, comparing
against littlefs2 and other filesystems in this space---as well as a
deeper analysis into the increased code cost and possible savings.

