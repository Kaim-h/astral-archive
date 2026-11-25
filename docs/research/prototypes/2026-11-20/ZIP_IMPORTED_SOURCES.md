# November 20 prototype source import

This index accompanies the completed additive source import from the verified November 20 ZIP. All 29 new source blobs were checked against the original Git blob identities and sizes; five byte-identical existing versions remain at their original locations. See [source audit and checksum inventory](ZIP_SOURCE_INVENTORY.md) for the exact source digest, deduplication, review limits and exclusions. These are historical browser experiments and notes, not production implementation or evidence of native validation. The original B6 is known to have severe reflow/resize hazards; do not exercise invalid-radius paths in an important browser tab. B6r12b3 remains the later accepted scroll-interaction reference.

## Imported originals

| Source | SHA-256 |
|---|---|
| [cubby-studies/Astral_Archive_Cubby_Study_A1.html](cubby-studies/Astral_Archive_Cubby_Study_A1.html) | `45e06fe5c767bd41725378d5c1d1c9616b5680a65778e466ebf1547cfe7da69f` |
| [cubby-studies/Astral_Archive_Cubby_Study_A2.html](cubby-studies/Astral_Archive_Cubby_Study_A2.html) | `b683dcd3452575187da4247b798be065f3da0aa566aa2a426602e931a6c28e98` |
| [cubby-studies/Astral_Archive_Cubby_Study_A3.html](cubby-studies/Astral_Archive_Cubby_Study_A3.html) | `d318c481e6e01540f086c7ba0c68c2e6017bd0e19d3e5d3c7318f070605c3027` |
| [cubby-studies/Astral_Archive_Cubby_Study_A4.html](cubby-studies/Astral_Archive_Cubby_Study_A4.html) | `ebb118a73c5b4b9d9e6a69471a28af7ff09ffa84579edbf1e653a9e72510c4a2` |
| [cubby-studies/Astral_Archive_Cubby_Study_A5.html](cubby-studies/Astral_Archive_Cubby_Study_A5.html) | `fb389ca0fd906c51cd30ebbfafe5ea931c973dafe3966249ef3bd44214d24b08` |
| [cubby-studies/Astral_Archive_Cubby_Study_A6.html](cubby-studies/Astral_Archive_Cubby_Study_A6.html) | `1a2fc0e94392239c5775f8de743ff7695ea72d6ae1c626247fd47d4dc05e9846` |
| [cubby-studies/Astral_Archive_Cubby_Study_B1.html](cubby-studies/Astral_Archive_Cubby_Study_B1.html) | `dd464961444f119223d31797428c877d9f61ba1d207106b38e9b250116c5165a` |
| [cubby-studies/Astral_Archive_Cubby_Study_B2.html](cubby-studies/Astral_Archive_Cubby_Study_B2.html) | `103ce6e4adef8fe29ff4b652ebe0956c969edb1b3716f513066e24d58191a051` |
| [cubby-studies/Astral_Archive_Cubby_Study_B3.html](cubby-studies/Astral_Archive_Cubby_Study_B3.html) | `8e437dfeffc521f39d1069dd31a8432773bd177adea0ec6bc2684c13040f52e8` |
| [cubby-studies/Astral_Archive_Cubby_Study_B3_Bookmark_Revision.html](cubby-studies/Astral_Archive_Cubby_Study_B3_Bookmark_Revision.html) | `dbbfc940b8cfadb44796fa8a1aa9615fb3005f9ad396917294481699261751c1` |
| [cubby-studies/Astral_Archive_Cubby_Study_B4.html](cubby-studies/Astral_Archive_Cubby_Study_B4.html) | `675e066014c0323864a38b4403773986d4d43a730d12c2410f138fc2f71c8a6b` |
| [cubby-studies/Astral_Archive_Cubby_Study_B4r.html](cubby-studies/Astral_Archive_Cubby_Study_B4r.html) | `ac2ca51cd7610f7db02e83352d391b47aa458ec344780472b9d71183be3c7791` |
| [cubby-studies/Astral_Archive_Cubby_Study_B5.html](cubby-studies/Astral_Archive_Cubby_Study_B5.html) | `041ceabfb7edcfa6e1dd3d8cbcbb680cb18cebcac7278f9c0c0481e8512995c7` |
| [cubby-studies/Astral_Archive_Cubby_Study_B6.html](cubby-studies/Astral_Archive_Cubby_Study_B6.html) | `33a173c6f118c36b7c90d73c28e80c3fbefac6c9a77b4190ebc2e9ddc45d0841` |
| [map-room/Astral_Archive_Map_Room_v3.html](map-room/Astral_Archive_Map_Room_v3.html) | `ad7e52f2b99800bbfe1b0712f80cb97a2216e7216bed72a2f230ba61401be258` |
| [notes/Astral_Archive_B6_Rack_and_Holder_Design_Notes.md](notes/Astral_Archive_B6_Rack_and_Holder_Design_Notes.md) | `fc352ce356cf7809cc8c50fa228edb0a3a7bbac668c710d0d312c19b990fc7e3` |
| [notes/Astral_Archive_Cubby_Study_B4_Notes.md](notes/Astral_Archive_Cubby_Study_B4_Notes.md) | `371af2d4627eb0672f19472ad46ea020c96279c593df333bc2f4f3246c755a72` |
| [notes/Astral_Archive_Cubby_Study_B4r_Notes.md](notes/Astral_Archive_Cubby_Study_B4r_Notes.md) | `c2a832483f6b792000a67107b17f67c204b66a577dc9a1eeb51ac9359a757c0f` |
| [notes/Astral_Archive_Cubby_Study_B6_Notes.md](notes/Astral_Archive_Cubby_Study_B6_Notes.md) | `ad9b2c530d3076863b9d14ec64fe7b8d818bac5fa41508e049137b9fdbf6a28c` |
| [scroll-physics/Astral_Archive_Scroll_Physics_Study_P1.html](scroll-physics/Astral_Archive_Scroll_Physics_Study_P1.html) | `9422b0979a00e3c4f19d89b8e36379e4c13df24e4283dbd99f4f2be6eb65f150` |
| [scroll-physics/Astral_Archive_Scroll_Physics_Study_P2.html](scroll-physics/Astral_Archive_Scroll_Physics_Study_P2.html) | `b41da1d2d3ddd02b9a02760d63aabf7508a1d11d154561a46da33f258843b4f4` |
| [scroll-physics/Astral_Archive_Scroll_Physics_Study_P2R.html](scroll-physics/Astral_Archive_Scroll_Physics_Study_P2R.html) | `ff103440935c2c4948b4d9984440a33e1d6c25a161666417bcd4d051f180ec30` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_10.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_10.html) | `905a2010b3f82acfcdfc188493a907e93924bd9c9e6f328531a5457c9a5437eb` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_11.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_11.html) | `c7c4408587b9fbb76df6083111d24c4e2fa74c0ce38bf45ecaeeea39dadeb1a6` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_5.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_5.html) | `50c70d2c6578ed5abb6f4840ac947db3b6f313386dbad68d80080454fa2b1d83` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_6.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_6.html) | `ce62c83e20af9f7c4fd6fe169e91e1d86931c02d8275870e2b1733ad7a66ecc1` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_7.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_7.html) | `d153d6b7fcd8ae62ad2f8cd5490db310c489ced874e295abfbc9637ec6786083` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_8.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_8.html) | `d6e908639fab8cb8733c4f333209340bbab8942d3734ec29e389b3edf718f6bd` |
| [storage-workshops/Astral_Archive_Storage_Workshop_v5_9.html](storage-workshops/Astral_Archive_Storage_Workshop_v5_9.html) | `72bb704e840523e9a32ea8d3e22262b14b0c817060fb9907a3060de3614394f1` |

## Byte-identical files already preserved

| Existing location | SHA-256 |
|---|---|
| [Astral_Archive_Storage_Workshop_v5_1.html](../../handoffs/2026-11-17/prototypes/Astral_Archive_Storage_Workshop_v5_1.html) | `966b78c398f76e41a8bf0c0605a40be924f06a2f9ae54b016d098921bbe7e940` |
| [Astral_Archive_Storage_Workshop_v5_12.html](../../handoffs/2026-11-17/prototypes/Astral_Archive_Storage_Workshop_v5_12.html) | `a5bbf2f80e9e53ce06e8e310eecfcdf2103cb5481bd0b29b1ffbf70d27f0504e` |
| [Astral_Archive_Storage_Workshop_v5_2.html](../../handoffs/2026-11-17/prototypes/Astral_Archive_Storage_Workshop_v5_2.html) | `fd9ee122b336c0fb17e1f9c01419c3c20f2d3cae54980d10f52317257cbd028c` |
| [Astral_Archive_Storage_Workshop_v5_3.html](../../handoffs/2026-11-17/prototypes/Astral_Archive_Storage_Workshop_v5_3.html) | `86afb27cd23d5f80787af157a2accc5fd4b20bb35cbcc8f3be50dcceee511cb1` |
| [Astral_Archive_Storage_Workshop_v5_4.html](../../handoffs/2026-11-17/prototypes/Astral_Archive_Storage_Workshop_v5_4.html) | `63e5dc45480b8c8491b75401a251cbfbc12944480ded37d5a2fc2492f12a237d` |

No diagnostic PNGs, whole archive, obsolete documentation overlays, runtime, tests or CI changes belong to this import. Initial-view inspection is not an exhaustive interaction, rights or privacy audit. See [publication preflight](../../../PUBLICATION_PREFLIGHT.md) and [licensing scope](../../../../LICENSING.md).
