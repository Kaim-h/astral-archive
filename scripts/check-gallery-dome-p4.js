#!/usr/bin/env node
'use strict';
// Compatibility entry point for users who already applied Patch 4.
// Patch 4 asserted the old, disconnected near-slit marks, which Patch 5 fixes.
// Keep the old script name useful instead of reporting a false regression.
console.log('Patch 4 engraving assertions were superseded by Patch 5; checking the complete v20 lattice instead.');
require('./check-gallery-dome-p5.js');
