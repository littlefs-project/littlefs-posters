
littlefs is a little filesystem targeting microcontrollers---small
devices with MiBs of ROM, KiBs of RAM, and, thanks to increasing storage
density, potentially GiBs of storage. With block sizes in the range
of ~128KiB-1MiB, block-based CoW algorithms are slow, and RAM-dependent
algorithms impossible. To support increasingly dense storage, we are
trying to find a flexible B-tree with the following constraints:

1. Strictly bounded-RAM, i.e. no non-tail recursion
2. RAM usage independent of block size
3. Does not rely on full block rewrites

Previous versions of littlefs avoided B-trees for these reasons, however
this has proven problematic for performance. In littlefs3, we are
exploring an alternative B-tree built on log-encoded binary trees
pioneered by the Dhara FTL. This so-called red-black-yellow Dhara (rbyd)
B-tree provides a flexible incremental B-tree in bounded-RAM, with
support for both sparse keys and order-statistic ranges.

