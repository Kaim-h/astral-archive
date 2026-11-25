// Batch 7 revised — first-pass sizes; tune after real Linux rendering.
var maximumPinnedBooks = 6;
var maximumRunningBooks = 6;
var minimumWorkspaces = 5;

// Click-to-open is the default. Set true to experiment with hover reveal.
// Hover mode avoids grabbing keyboard focus and uses a grace-period close.
// Its pointer behavior is unverified on native Wayland and should be tested.
var openShelvesOnHover = true;
