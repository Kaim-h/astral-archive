// Native bounded appearance values. Catalogue is recovered from the public
// S11r1 reference, blob 59e8278ad6247eda2c08bd013271e55c7abfd411.
// Individual artwork remains subject to Designer review. No external assets.
// Backing fields use local top-left units, not screen pixels.
export const catalogue=Object.freeze({
 astral:[
  {"id":"stellar-seal","name":"Stellar seal","note":"The established four-point star and orbit.","legacy":true},
  {"id":"armillary","name":"Armillary","note":"Intersecting orbital rings around a central sphere.","core":["M-40 0A40 40 0 1 0 40 0A40 40 0 1 0 -40 0Z","M-36 18C-15 -18 15 -31 36 -18C15 18 -15 31 -36 18Z","M-14 -37C15 -21 29 16 14 37C-15 21 -29 -16 -14 -37Z","M-6 0A6 6 0 1 0 6 0A6 6 0 1 0 -6 0Z"],"fine":["M-46 0H-40M40 0H46M0 -46V-40M0 40V46","M28 -25l5 -4 5 4 -5 4Z"]},
  {"id":"eclipse","name":"Eclipse","note":"A luminous crescent enclosed by a restrained corona.","core":["M-31 0A31 31 0 1 0 31 0A31 31 0 1 0 -31 0Z","M0 -31C-25 -20 -25 20 0 31C-10 15 -10 -15 0 -31Z","M-43 0H-35M35 0H43M0 -43V-35M0 35V43"],"fine":["M-31 -31l6 6M31 -31l-6 6M-31 31l6 -6M31 31l-6 -6","M-38 -13l4 1M38 13l-4 -1M-13 38l1 -4M13 -38l-1 4"]},
  {"id":"constellation","name":"Constellation","note":"The Quill, from the existing Archive-original constellation catalogue; stars and connections only. Future shared constellation-maker integration.","core":["M-33.061 32.720L-21.063 18.152","M-17.692 13.561L-4.500 -6.666","M-0.437 -11.567L21.083 -32.190","M22.788 -31.200L14.356 2.525","M12.098 6.827L-8.566 30.309","M26.164 -32.136L32.384 -25.916","M-37.15 34.65a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0 -5 0Z","M-22.102 15.95a2.852 2.852 0 1 0 5.704 0a2.852 2.852 0 1 0 -5.704 0Z","M-5.954 -9.35a3.204 3.204 0 1 0 6.408 0a3.204 3.204 0 1 0 -6.408 0Z","M20.094 -34.65a3.556 3.556 0 1 0 7.112 0a3.556 3.556 0 1 0 -7.112 0Z","M11.25 4.95a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0 -5 0Z","M-13.302 32.45a2.852 2.852 0 1 0 5.704 0a2.852 2.852 0 1 0 -5.704 0Z","M31.446 -23.65a3.204 3.204 0 1 0 6.408 0a3.204 3.204 0 1 0 -6.408 0Z"],"constellationId":"quill"},
  {"id":"lunar-cycle","name":"Lunar cycle","note":"Three lunar phases arranged within an orbit.","core":["M-42 0A42 42 0 1 0 42 0A42 42 0 1 0 -42 0Z","M-11 0A11 11 0 1 0 11 0A11 11 0 1 0 -11 0Z","M-35 0A8 8 0 1 0 -19 0A8 8 0 1 0 -35 0Z M-27 -8Q-35 0 -27 8","M19 0A8 8 0 1 0 35 0A8 8 0 1 0 19 0Z M27 -8Q35 0 27 8"],"fine":["M0 -36V-29M0 29V36","M-26 -26l5 5M26 -26l-5 5M-26 26l5 -5M26 26l-5 -5"]},
  {"id":"transit","name":"Celestial transit","note":"An engraved spherical transit, with a subtle equatorial seam and offset inset disc.","core":["M-41 0A41 41 0 1 0 41 0A41 41 0 1 0 -41 0Z","M-40 4Q0 10 40 4","M10 -19A10 10 0 1 0 30 -19A10 10 0 1 0 10 -19Z"],"fine":["M-31 16Q0 21 31 16","M14 -19A6 6 0 1 0 26 -19A6 6 0 1 0 14 -19Z","M-26 -28Q-11 -38 5 -37"]},
  {"id":"solar-crown","name":"Solar crown","note":"A sun disc with alternating straight and curved rays.","core":["M-23 0A23 23 0 1 0 23 0A23 23 0 1 0 -23 0Z","M0 -27V-45M0 27V45M-27 0H-45M27 0H45","M-20 -20Q-35 -24 -32 -39M20 -20Q24 -35 39 -32M20 20Q35 24 32 39M-20 20Q-24 35 -39 32","M-14 0A14 14 0 1 0 14 0A14 14 0 1 0 -14 0Z"],"fine":["M-12 -33l-2 -7M12 33l2 7M33 -12l7 -2M-33 12l-7 2"]},
  {"id":"conjunction","name":"Conjunction","note":"Two intersecting spheres aligned on a common axis.","core":["M-43 0A29 29 0 1 0 15 0A29 29 0 1 0 -43 0Z","M-15 0A29 29 0 1 0 43 0A29 29 0 1 0 -15 0Z","M0 -37V37M-46 0H46","M0 -8L7 0 0 8 -7 0Z"],"fine":["M-33 -30l4 -4M33 30l-4 4M-33 30l4 4M33 -30l-4 -4","M-18 -39H18M-18 39H18"]}
 ],
 botanical:[
  {"id":"vine-seal","name":"Vine seal","note":"A rooted stem with paired leaves; established family emblem.","legacy":true},
  {"id":"fern-frond","name":"Fern frond","note":"Paired pinnae taper naturally toward the growing tip.","core":["M0 43Q-4 5 0 -42","M0 -29Q-12 -33 -15 -38Q-17 -28 0 -24M0 -29Q12 -33 15 -38Q17 -28 0 -24","M-1 -14Q-20 -25 -26 -24Q-24 -9 -1 -9M-1 -14Q20 -25 26 -24Q24 -9 -1 -9","M-2 3Q-24 -8 -34 -6Q-31 8 -2 9M-2 3Q24 -8 34 -6Q31 8 -2 9","M0 19Q-20 10 -39 12Q-32 23 0 25M0 19Q20 10 39 12Q32 23 0 25"],"fine":["M-2 32Q-15 29 -22 27M0 32Q15 29 22 27"]},
  {"id":"floral-rosette","name":"Floral rosette","note":"Eight petals meet at a single floral center.","radial":[8,"M0 -8Q-16 -23 0 -38Q16 -23 0 -8Z"],"core":["M-8 0A8 8 0 1 0 8 0A8 8 0 1 0 -8 0Z"],"fine":["M-43 0A43 43 0 1 0 43 0A43 43 0 1 0 -43 0Z"]},
  {"id":"olive-sprig","name":"Olive sprig","note":"Alternating lance-shaped leaves attached to a rising branch.","core":["M-29 40Q-3 5 27 -40","M-16 22Q-34 10 -33 -7Q-13 -4 -16 22Z","M-7 9Q15 -9 32 -4Q22 12 -7 9Z","M4 -8Q-18 -18 -18 -35Q1 -30 4 -8Z","M16 -25Q30 -42 43 -35Q39 -17 16 -25Z"],"fine":["M-16 22L-28 2M-7 9L24 -2M4 -8L-12 -26M16 -25L36 -32","M-23 30Q-7 30 -8 20Q-18 17 -23 30Z"]},
  {"id":"ginkgo-fan","name":"Ginkgo fan","note":"One fan-shaped leaf with radiating veins.","core":["M0 40Q-4 19 0 5Q-26 6 -42 -13Q-34 -37 -11 -39L0 -29L11 -39Q34 -37 42 -13Q26 6 0 5Z","M0 5Q-15 -5 -30 -24M0 5Q-5 -13 -13 -34M0 5Q5 -13 13 -34M0 5Q15 -5 30 -24"],"fine":["M0 5Q-25 0 -39 -13M0 5Q25 0 39 -13","M-8 34Q0 30 8 34"]},
  {"id":"lotus","name":"Lotus","note":"Overlapping upright petals above a short stem.","core":["M0 28Q-24 4 0 -40Q24 4 0 28Z","M0 28Q-40 15 -34 -19Q-10 -17 0 10Q10 -17 34 -19Q40 15 0 28Z","M0 28Q-40 36 -44 3Q-23 3 0 28Q23 3 44 3Q40 36 0 28Z","M0 28V43"],"fine":["M-23 36Q0 30 23 36M0 -27V15"]},
  {"id":"acorn","name":"Acorn","note":"A single acorn with a rounded cup, short stem and tapering nut.","core":["M-4 -28Q-5 -39 5 -43","M-29 -7Q-32 -29 0 -29Q32 -29 29 -7Q0 -2 -29 -7Z","M-24 -5Q-25 20 -4 35Q0 39 4 35Q25 20 24 -5"],"fine":["M-24 -15L-12 -26M-11 -5L10 -27M7 -5L23 -21M-18 -25L1 -5M2 -28L22 -7"]},
  {"id":"laurel-wreath","name":"Laurel wreath","note":"Two leaf-bearing stems frame an open central field.","core":["M0 40Q-39 32 -36 -6Q-33 -26 -12 -40M0 40Q39 32 36 -6Q33 -26 12 -40","M-26 26Q-43 22 -40 8Q-28 11 -26 26Z M-35 5Q-48 -5 -41 -18Q-32 -9 -35 5Z M-29 -21Q-37 -36 -21 -41Q-18 -31 -29 -21Z","M26 26Q43 22 40 8Q28 11 26 26Z M35 5Q48 -5 41 -18Q32 -9 35 5Z M29 -21Q37 -36 21 -41Q18 -31 29 -21Z","M0 40L-9 45M0 40L9 45"],"fine":["M-26 26Q-12 18 -17 8Q-29 12 -26 26Z M26 26Q12 18 17 8Q29 12 26 26Z","M-35 5Q-17 -1 -21 -12Q-34 -9 -35 5Z M35 5Q17 -1 21 -12Q34 -9 35 5Z"]}
 ],
 plain:[
  {"id":"stepped-seal","name":"Stepped seal","note":"The established cut-stone geometric medallion.","legacy":true},
  {"id":"octagram","name":"Octagram","note":"Two interlaced squares form a balanced eight-point seal.","core":["M-30 -30H30V30H-30Z","M0 -43L43 0L0 43L-43 0Z","M0 -16L16 0L0 16L-16 0Z"],"fine":["M-22 -22H22V22H-22Z","M-5 0H5M0 -5V5"]},
  {"id":"quatrefoil","name":"Quatrefoil","note":"Four lobes meet within a precise stonework frame.","core":["M0 -12C-30 -45 -45 -30 -12 0C-45 30 -30 45 0 12C30 45 45 30 12 0C45 -30 30 -45 0 -12Z","M0 -6L6 0L0 6L-6 0Z","M-35 0A35 35 0 1 0 35 0A35 35 0 1 0 -35 0Z"],"fine":["M0 -43V-35M0 35V43M-43 0H-35M35 0H43"]},
  {"id":"diamond-braid","name":"Diamond braid","note":"Overlapping rhombi with readable, simple intersections.","core":["M-43 0L0 -29L43 0L0 29Z","M0 -43L29 0L0 43L-29 0Z","M-19 0L0 -19L19 0L0 19Z"],"fine":["M-37 -18L-18 -37M37 -18L18 -37M-37 18L-18 37M37 18L18 37"]},
  {"id":"fan-medallion","name":"Fan medallion","note":"A radial masonry fan with broad, clean ribs.","core":["M-42 22A42 42 0 0 1 42 22H-42Z","M-29 22A29 29 0 0 1 29 22","M0 22L-36 1M0 22L-21 -14M0 22V-20M0 22L21 -14M0 22L36 1","M-25 33H25M-15 41H15"],"fine":["M-38 16A38 38 0 0 1 38 16"]},
  {"id":"mosaic","name":"Mosaic tile","note":"Four repeated tessellated shapes around a central diamond.","core":["M-40 -40H40V40H-40Z","M0 -40L40 0L0 40L-40 0Z","M-20 -20H20V20H-20Z","M-40 -40L-20 -20M40 -40L20 -20M-40 40L-20 20M40 40L20 20","M0 -12L12 0L0 12L-12 0Z"],"fine":["M-34 -34h10M34 -34h-10M-34 34h10M34 34h-10"]},
  {"id":"masonry-seal","name":"Masonry seal","note":"A diamond keystone set into an orderly staggered masonry register.","core":["M-40 -30H40V30H-40Z","M-40 -10H-11M11 -10H40M-40 10H-11M11 10H40","M0 -30V-20M-20 -10V10M20 -10V10M0 20V30","M0 -20L20 0L0 20L-20 0Z"],"fine":["M-45 -36H45M-45 36H45"]},
  {"id":"stone-rosette","name":"Stone rosette","note":"Six simple incised petals within a circular register.","radial":[6,"M0 -6L-12 -22L0 -40L12 -22Z"],"core":["M-6 0A6 6 0 1 0 6 0A6 6 0 1 0 -6 0Z","M-44 0A44 44 0 1 0 44 0A44 44 0 1 0 -44 0Z"],"fine":["M-35 0A35 35 0 1 0 35 0A35 35 0 1 0 -35 0Z"]}
 ],
 bestiary:[
  {"id":"paw","name":"Cat paw","note":"A quiet track: four toe pads and the characteristic three-lobed heel.","core":["M-28 4C-42 0 -44 -16 -36 -22C-26 -29 -15 -12 -17 -4Q-19 4 -28 4Z","M-12 -9C-24 -18 -21 -40 -11 -41C1 -44 6 -24 0 -14Q-4 -7 -12 -9Z","M13 -9C3 -10 1 -29 9 -39C19 -46 29 -29 23 -16Q20 -10 13 -9Z","M31 5C19 3 20 -10 29 -20C37 -28 47 -18 41 -6Q38 4 31 5Z","M0 7C-9 0 -18 11 -25 20C-36 34 -23 42 -12 37Q0 30 12 37C23 42 36 34 25 20C18 11 9 0 0 7Z"],"fine":["M-17 28Q-10 16 0 19Q10 16 17 28"]},
  {"id":"shell","name":"Turtle shell","note":"The domed outline and interlocking scutes of a carapace.","core":["M0 -45C-25 -45 -39 -27 -41 -4C-43 22 -24 43 0 44C24 43 43 22 41 -4C39 -27 25 -45 0 -45Z","M0 -34L12 -23L12 -9L0 0L-12 -9L-12 -23Z","M0 0L13 10L12 25L0 35L-12 25L-13 10Z","M0 -34V-45M12 -23L31 -32M12 -9L39 -11M13 10L37 14M12 25L23 38M0 35V44M-12 -23L-31 -32M-12 -9L-39 -11M-13 10L-37 14M-12 25L-23 38"],"fine":["M-28 -23Q-35 -12 -33 2M28 -23Q35 -12 33 2M-29 14Q-25 26 -13 33M29 14Q25 26 13 33"]},
  {"id":"feather","name":"Owl feather","note":"A single tapered feather, with barbs flowing into the quill.","core":["M-30 43Q-11 10 30 -42","M-19 23C-31 12 -28 -5 -15 -19C-1 -34 19 -40 30 -42C29 -24 23 -8 9 6Q-5 21 -19 23Z","M-16 21Q-20 7 -24 1M-8 10Q-12 -3 -18 -12M0 0Q-5 -14 -9 -22M10 -13Q6 -24 3 -30","M-16 21Q-3 16 7 9M-8 10Q7 5 17 -5M0 0Q15 -6 23 -17M10 -13Q21 -19 27 -28"],"fine":["M-11 14L-17 1M-4 5L-10 -10M5 -7L-1 -21M-11 14L2 9M-4 5L10 -1M5 -7L18 -16"]},
  {"id":"antlers","name":"Stag antlers","note":"Paired branching antlers rather than a head.","core":["M-6 42C-11 26 -12 17 -24 5C-34 -5 -40 -17 -37 -38M-24 5Q-12 -6 -16 -27M-32 -6Q-45 -12 -43 -29M-16 -12Q-4 -19 -8 -42","M6 42C11 26 12 17 24 5C34 -5 40 -17 37 -38M24 5Q12 -6 16 -27M32 -6Q45 -12 43 -29M16 -12Q4 -19 8 -42"],"fine":["M-6 42Q-2 38 0 40Q2 38 6 42M-11 29Q-14 16 -20 9M11 29Q14 16 20 9"]},
  {"id":"scallop","name":"Scallop shell","note":"A fluted shell with a natural fan silhouette.","core":["M-11 32C-23 33 -43 12 -43 -5Q-43 -18 -32 -21Q-31 -34 -15 -35Q-8 -43 0 -37Q8 -43 15 -35Q31 -34 32 -21Q43 -18 43 -5C43 12 23 33 11 32L15 39H-15Z","M0 32V-37M-4 32Q-12 -4 -15 -35M4 32Q12 -4 15 -35M-8 30Q-24 2 -32 -21M8 30Q24 2 32 -21"],"fine":["M-10 29Q-31 14 -39 -6M10 29Q31 14 39 -6M-15 36H15"]},
  {"id":"wing","name":"Raven wing","note":"Folded flight feathers, with a sweeping outer contour.","core":["M-39 31C-33 6 -24 -15 -8 -28Q12 -42 39 -40Q36 -30 23 -19L40 -24Q39 -13 16 -1L34 -6Q31 7 7 17L22 16Q5 33 -39 31Z","M-35 27Q-12 -4 26 -29M-25 29Q-4 6 25 -15M-13 29L21 2M0 26L15 18"],"fine":["M-28 8Q-20 -11 -3 -23M-24 13Q-13 -7 2 -19M-13 13L10 -9"]},
  {"id":"moth","name":"Night moth","note":"A natural wing outline with restrained eyespots and a narrow body.","core":["M-4 -10C-15 -26 -34 -39 -42 -29Q-46 -17 -34 -2Q-28 7 -15 12C-34 11 -35 31 -20 35Q-7 37 -4 14","M4 -10C15 -26 34 -39 42 -29Q46 -17 34 -2Q28 7 15 12C34 11 35 31 20 35Q7 37 4 14","M0 -16Q-6 -10 -4 9L0 32L4 9Q6 -10 0 -16Z","M-2 -14Q-4 -29 -15 -33M2 -14Q4 -29 15 -33","M-31 -17Q-23 -25 -17 -14Q-17 -4 -27 -5Q-34 -9 -31 -17ZM31 -17Q23 -25 17 -14Q17 -4 27 -5Q34 -9 31 -17Z"],"fine":["M-5 1Q-17 -6 -32 -23M5 1Q17 -6 32 -23M-5 12L-23 28M5 12L23 28"]},
  {"id":"bee","name":"Honey bee","note":"An abdomen, paired wings and small antennae.","core":["M-9 -25Q0 -35 9 -25L11 -17Q19 -10 15 8Q12 26 0 40Q-12 26 -15 8Q-19 -10 -11 -17Z","M-12 -14C-25 -32 -44 -28 -42 -12Q-39 2 -15 2M12 -14C25 -32 44 -28 42 -12Q39 2 15 2","M-15 1Q0 9 15 1M-12 15Q0 22 12 15M-6 29Q0 32 6 29","M-4 -29Q-7 -38 -14 -40M4 -29Q7 -38 14 -40"],"fine":["M-16 -6L-34 -20M16 -6L34 -20M-15 4L-26 12L-31 22M15 4L26 12L31 22"]},
  {"id":"dragonfly","name":"Dragonfly","note":"Long paired wings surrounding the segmented body.","core":["M0 -38Q-6 -38 -6 -31Q-6 -25 -3 -24L-2 35L0 43L2 35L3 -24Q6 -25 6 -31Q6 -38 0 -38Z","M-4 -19C-18 -38 -43 -32 -43 -20Q-42 -10 -4 -12M4 -19C18 -38 43 -32 43 -20Q42 -10 4 -12","M-3 -8C-25 -14 -44 0 -39 10Q-31 24 -3 -1M3 -8C25 -14 44 0 39 10Q31 24 3 -1"],"fine":["M-6 -15L-30 -24M6 -15L30 -24M-6 -4L-32 9M6 -4L32 9M-2 10H2M-2 20H2M-2 30H2"]},
  {"id":"fish","name":"Fish scales","note":"Overlapping scales as an isolated, organic heraldic mark.","core":["M-38 -30Q-38 -12 -19 -5Q0 -12 0 -30M0 -30Q0 -12 19 -5Q38 -12 38 -30","M-38 -5Q-38 13 -19 20Q0 13 0 -5M0 -5Q0 13 19 20Q38 13 38 -5","M-19 20Q-19 35 0 42Q19 35 19 20","M-38 -30Q-19 -44 0 -30Q19 -44 38 -30"],"fine":["M-29 -25Q-28 -17 -19 -13M9 -25Q10 -17 19 -13M-29 0Q-28 8 -19 12M9 0Q10 8 19 12M-10 24Q-9 32 0 35"]},
  {"id":"web","name":"Spider web","note":"An eight-spoke web, with a light asymmetric woven spiral.","core":["M0 0L0 -43M0 0L31 -31M0 0H43M0 0L31 31M0 0V43M0 0L-31 31M0 0H-43M0 0L-31 -31","M0 -35Q12 -23 25 -25Q23 -12 35 0Q23 12 25 25Q12 23 0 35Q-12 23 -25 25Q-23 12 -35 0Q-23 -12 -25 -25Q-12 -23 0 -35Z","M0 -19Q7 -11 14 -14Q11 -7 19 0Q11 7 14 14Q7 11 0 19Q-7 11 -14 14Q-11 7 -19 0Q-11 -7 -14 -14Q-7 -11 0 -19Z"],"fine":["M0 -27Q9 -17 20 -20Q17 -9 27 0Q17 9 20 20Q9 17 0 27Q-9 17 -20 20Q-17 9 -27 0Q-17 -9 -20 -20Q-9 -17 0 -27Z"]},
  {"id":"ram","name":"Ram horn","note":"A curled horn with tapered growth lines.","core":["M-32 30C-44 0 -33 -31 -8 -38C17 -45 40 -25 40 0C40 24 18 36 1 24C-12 15 -12 -6 0 -13C12 -21 25 -8 21 5Q16 16 5 10","M-32 30Q-13 29 -6 18","M-23 17Q-35 -2 -22 -22M-16 10Q-25 -8 -12 -24"],"fine":["M-7 -34L-3 -26M10 -35L8 -26M25 -27L18 -20M35 -12L27 -10M35 8L26 5"]}
 ],
 water:[
  {"id":"crest-wave","name":"Breaking wave","note":"A curling wave with a clear hollow and flowing lower edge.","core":["M-43 29C-23 29 -24 2 -10 -17C2 -34 25 -42 39 -24C49 -10 38 10 23 9C12 9 8 -1 14 -10C15 1 29 0 30 -11C31 -22 15 -24 5 -13C-6 -1 -6 16 -20 27Q-30 35 -43 35","M-43 42Q-25 34 -8 41T27 40Q36 35 43 37"],"fine":["M-18 20Q-9 10 -6 -3M7 -28Q24 -34 33 -22M36 -4Q33 4 25 5"]},
  {"id":"ripples","name":"Rain ripple","note":"A falling drop above nested elliptical ripples.","core":["M0 -43C-6 -29 -15 -17 -15 -8A15 15 0 0 0 15 -8C15 -17 6 -29 0 -43Z","M-18 13A18 6 0 1 0 18 13A18 6 0 1 0 -18 13Z","M-31 21A31 10 0 1 0 31 21A31 10 0 1 0 -31 21Z","M-44 29A44 15 0 1 0 44 29A44 15 0 1 0 -44 29Z"],"fine":["M-8 -9Q-9 -2 -3 1"]},
  {"id":"current","name":"River meander","note":"Three parallel banks of a sinuous, continuously flowing current.","core":["M-44 -32C-10 -45 29 -40 27 -21C26 -5 -18 -3 -26 14C-37 37 9 46 44 32","M-44 -23C-12 -36 19 -31 18 -20C17 -11 -25 -7 -35 13C-47 42 7 54 44 42","M-44 -41C-4 -54 38 -47 36 -21C34 2 -12 6 -17 16C-26 31 11 37 44 22"],"fine":["M-11 -35Q0 -36 10 -33M-17 27Q-7 33 5 34"]},
  {"id":"whirlpool","name":"Whirlpool","note":"Three curved streams rotating around an open center.","core":["M-43 -8C-35 -35 3 -48 28 -30C52 -12 37 23 12 28C-8 33 -23 16 -14 2C-8 -7 4 -8 10 0","M-31 31C-49 8 -29 -28 -5 -29C19 -30 33 -6 20 10C10 22 -6 16 -7 6","M30 37C6 52 -29 40 -35 16C-40 -4 -18 -20 -2 -15C13 -10 15 4 7 8"],"fine":["M-35 -15Q-25 -29 -9 -34M31 25Q39 13 39 1"]},
  {"id":"cascade","name":"Cascade","note":"Water falling from a stone lip into a shallow pool.","core":["M-43 -32H-15Q-6 -32 -6 -21V9Q-6 20 -20 26","M-28 -22H-19Q-15 -22 -15 -16V8Q-15 15 -24 20","M5 -32H21Q28 -32 28 -21V10Q28 22 41 28","M14 -23V10Q14 25 27 30","M-44 32Q-29 25 -14 32T16 32T44 31M-33 41Q-18 35 -3 41T27 41"],"fine":["M-2 -15V8M33 -28H43M-10 25L-4 21M8 25L12 19"]},
  {"id":"rain","name":"Rain shower","note":"A narrow bank of rain beneath an understated cloud.","core":["M-37 -8C-46 -14 -44 -27 -33 -31Q-22 -36 -14 -27C-8 -46 19 -46 25 -28Q44 -29 44 -14Q44 -6 31 -6H-32","M-28 2L-36 18M-11 3L-19 23M6 2L-3 20M23 3L15 25M38 2L30 18","M-26 30L-30 39M-4 29L-8 38M17 31L13 40"],"fine":["M-25 -31Q-21 -37 -13 -37"]},
  {"id":"ice","name":"Ice crystal","note":"A sixfold ice crystal with long tapered branches.","core":["M0 -43V43M-37.24 -21.5L37.24 21.5M-37.24 21.5L37.24 -21.5","M-10 -31L0 -21L10 -31M-10 31L0 21L10 31","M-32 -7L-18 -10L-22 -24M32 7L18 10L22 24","M-32 7L-18 10L-22 24M32 -7L18 -10L22 -24"],"fine":["M0 -12L10 -6V6L0 12L-10 6V-6Z"]},
  {"id":"tide","name":"Tidal terraces","note":"Long gently curving wave lines that evoke the advancing tide.","core":["M-44 -19C-28 -35 -9 -35 5 -21Q22 -5 44 -17","M-44 -4C-28 -20 -9 -20 5 -6Q22 10 44 -2","M-44 11C-28 -5 -9 -5 5 9Q22 25 44 13","M-44 26C-28 10 -9 10 5 24Q22 40 44 28"],"fine":["M-31 -34Q-22 -39 -12 -37M16 38Q27 43 36 39"]}
 ],
 air:[
  {"id":"wind","name":"Wind scroll","note":"Long flowing lines with open, tapering curls.","core":["M-44 -13H18C46 -13 43 -43 23 -42Q5 -41 8 -25","M-44 0H31C49 0 48 22 33 22Q20 22 19 10","M-34 15H-2C18 15 21 41 2 43Q-10 43 -13 32"],"fine":["M-39 -25H-8M-44 28H-26"]},
  {"id":"cloudbank","name":"Cloud bank","note":"Rounded billows above two quiet bands of drift.","core":["M-43 5C-47 -5 -38 -17 -26 -16C-29 -29 -17 -39 -5 -36Q7 -37 15 -24C27 -30 42 -20 42 -8Q42 6 27 6H-35Q-41 6 -43 5Z","M-40 19C-23 14 -17 22 -3 20Q16 15 42 19","M-27 32Q-13 27 2 32T34 32"],"fine":["M-20 -19Q-18 -29 -8 -30M17 -19Q27 -23 34 -15"]},
  {"id":"vortex","name":"Air vortex","note":"A vertical whirlwind narrowing to a single tail.","core":["M-44 -32C-13 -45 17 -44 44 -32C19 -16 -12 -19 -37 -27","M-36 -19C-15 -7 10 -9 31 -18Q38 -11 23 -5C2 5 -21 0 -29 -6","M-24 5C-9 15 5 14 18 7Q22 13 7 21Q-5 27 -12 22","M-8 25Q6 35 -3 42"],"fine":["M-20 -34Q0 -38 19 -34M-12 -15Q0 -12 12 -15"]},
  {"id":"sail","name":"Wind-filled sail","note":"A billowing triangular sail, with a restrained mast and wake.","core":["M-16 -44V37M-16 -40C11 -33 34 -6 41 23Q13 11 -16 23Z","M-20 32H37Q24 43 -13 43Q-30 41 -39 34Z","M-16 -25Q1 -18 16 -4"],"fine":["M-7 -31Q15 -21 27 0"]},
  {"id":"seed","name":"Windborne seed","note":"A single floating seed with a fine parachute of bristles.","core":["M0 15C-8 21 -7 32 0 41C7 32 8 21 0 15Z","M0 15V-4M0 -4Q-16 -10 -40 -17M0 -4Q-14 -20 -27 -36M0 -4Q0 -24 0 -43M0 -4Q14 -20 27 -36M0 -4Q16 -10 40 -17"],"fine":["M-40 -17l-3 -4M-27 -36l-4 -5M0 -43v-4M27 -36l4 -5M40 -17l3 -4M0 -4Q-21 -15 -36 -27M0 -4Q21 -15 36 -27"]},
  {"id":"gust","name":"Mountain gust","note":"A wind stream curling over a small ridge.","core":["M-44 -17C-15 -33 19 -36 35 -23Q46 -13 33 -5Q24 0 19 -10","M-44 -5Q-15 -17 8 -13","M-42 34L-17 8L-4 21L13 0L41 34Z","M-17 8L-9 19M13 0L23 19"],"fine":["M-37 41H38"]},
  {"id":"breath","name":"Breath of wind","note":"A pair of asymmetric flourishes meeting at a quiet central opening.","core":["M-44 8C-22 9 -13 -28 11 -28C31 -28 38 -13 32 -2Q26 8 16 2","M-40 21C-22 24 -11 -7 5 -8Q17 -10 18 1","M-33 34C-10 41 6 15 23 18Q35 20 43 13"],"fine":["M-22 -8Q-14 -24 -1 -28M-18 30Q-9 25 -1 18"]},
  {"id":"streamlines","name":"High currents","note":"Layered long curves that taper away like moving air.","core":["M-44 -27C-24 -14 -11 -19 2 -30Q21 -46 44 -29","M-44 -9C-24 4 -11 -1 2 -12Q21 -28 44 -11","M-44 9C-24 22 -11 17 2 6Q21 -10 44 7","M-32 28C-16 36 -6 32 7 21Q25 6 39 20"],"fine":["M-38 -41Q-25 -35 -13 -39M18 36Q29 28 42 32"]}
 ],
 earth:[
  {"id":"ridge","name":"Mountain ridge","note":"An irregular ridge with a clean snowless rock face.","core":["M-45 34L-28 5L-18 15L4 -40L20 -12L28 -20L45 34Z","M4 -40L-1 0L-18 15M4 -40L13 -5L20 -12M28 -20L33 4L45 34"],"fine":["M-36 33L-23 17M-7 34L4 5M20 34L27 16"]},
  {"id":"crystal","name":"Crystal cluster","note":"A cluster of angular crystals growing from a shared base.","core":["M-9 40L-16 -24L0 -43L16 -24L9 40Z","M-16 -24L0 -16L16 -24M0 -16V40","M-9 40L-37 20L-40 -7L-20 -17L-11 8M-40 -7L-26 0L-20 -17M-26 0L-9 40","M9 40L36 17L40 -11L22 -19L12 4M40 -11L27 -2L22 -19M27 -2L9 40"],"fine":["M-38 38H38"]},
  {"id":"strata","name":"Sedimentary strata","note":"Folded layers inside a roughly hewn stone section.","core":["M-42 -29L-11 -42L34 -30L42 -6L33 32L0 43L-38 30L-42 -29Z","M-41 -13Q-17 -3 -3 -16T38 -13M-40 4Q-17 14 -2 1T39 2M-39 21Q-16 31 -1 18T36 19"],"fine":["M-35 -23Q-18 -18 -4 -26M-16 36Q0 39 15 34"]},
  {"id":"geode","name":"Geode","note":"A crystal-lined cavity with a second tier of inward-facing spires visible behind the rim.","core":["M-39 -16C-28 -37 -7 -44 12 -38Q35 -34 42 -10C46 13 33 34 10 41C-13 47 -35 34 -42 13Q-46 -1 -39 -16Z","M-30 -13Q-17 -32 4 -30Q23 -30 31 -9Q36 10 19 25Q-2 35 -22 22Q-36 9 -30 -13Z","M-29 -11L-19 -6L-20 -23M-16 -27L-9 -13L-2 -25M4 -30L8 -15L17 -26M26 -21L20 -8L31 -9M-31 2L-22 8L-25 18M-20 24L-14 10L-6 28M-3 30L4 9L12 25M15 27L19 12L29 14","M-19 10L-17 -1L-12 -8L-7 -1L-8 10 M-6 10L-4 -5L3 -12L9 -4L8 10 M12 11L14 1L19 -5L23 3L21 12"],"fine":["M-17 -1L-12 3L-12 -8M-4 -5L3 1L3 -12M14 1L19 5L19 -5","M-12 3L-13 10M3 1L2 9M19 5L17 11","M-38 -5Q-39 11 -30 23M17 -35Q30 -29 36 -17"]},
  {"id":"cairn","name":"Stone cairn","note":"Three distinct balanced stones, rather than a geometric stack.","core":["M-37 39Q-42 27 -25 21Q-7 14 20 20Q40 25 38 39Q7 47 -37 39Z","M-28 16Q-31 5 -13 -3Q4 -9 21 0Q31 6 24 17Q-2 24 -28 16Z","M-18 -7Q-20 -25 -1 -36Q12 -39 21 -24Q27 -12 15 -7Q-1 0 -18 -7Z"],"fine":["M-28 32Q-12 27 3 30M-14 11Q-3 7 10 9M-9 -18Q-5 -25 1 -28"]},
  {"id":"dune","name":"Sand dunes","note":"Wind-shaped slopes with sparse curved strata.","core":["M-44 22Q-25 -29 0 -6Q19 12 44 4","M-44 33Q-19 6 0 13Q21 25 44 15","M-44 42Q-23 26 -6 30Q14 40 44 28","M-16 -12Q5 -42 26 -18Q35 -6 44 -8"],"fine":["M-35 18Q-26 4 -17 1M11 -13Q24 -3 31 -3"]},
  {"id":"basalt","name":"Basalt columns","note":"Uneven polygonal stone columns with long vertical joints.","core":["M-43 37V-7L-33 -16H-22L-13 -7V37M-13 37V-28L-4 -39H7L17 -28V37M17 37V-14L28 -25H38L45 -14V37H-43","M-43 -7L-28 1L-13 -7M-28 1V37M-13 -28L2 -19L17 -28M2 -19V37M17 -14L31 -5L45 -14M31 -5V37"],"fine":["M-43 42H45M-37 8V30M11 -12V24M39 2V29"]},
  {"id":"fault","name":"Fault line","note":"An uneven split through layered rock; not a map contour.","core":["M-42 -38L-6 -41L-12 -19L-4 -4L-18 16L-10 40L-42 37Z","M5 -42L42 -39V38L2 41L-6 18L8 -3L-1 -20Z","M-42 -23Q-28 -25 -13 -22M-42 -7Q-23 -11 -5 -7M-42 10Q-29 8 -16 12M-42 26Q-26 23 -15 27","M0 -28Q19 -31 42 -26M4 -13Q22 -17 42 -12M7 5Q22 1 42 5M-2 23Q22 18 42 22"],"fine":["M-37 -33L-21 -35M12 33Q26 30 36 32"]}
 ],
 fire:[
  {"id":"flame","name":"Flame","note":"One asymmetrical flame with a smaller inner tongue.","core":["M-2 43C-30 39 -40 19 -27 -5Q-21 -15 -22 -26Q-7 -21 -5 -7Q12 -20 7 -43Q34 -22 27 -6C45 14 29 40 -2 43Z","M-2 43C-16 33 -19 18 -6 7Q0 0 2 -13Q18 8 15 20Q14 35 -2 43Z"],"fine":["M-24 16Q-27 26 -17 34"]},
  {"id":"candle","name":"Candle flame","note":"A small standing flame above a single wax candle.","core":["M0 -16C-16 -17 -16 -28 0 -44C16 -28 16 -17 0 -16Z","M0 -16V-5M-13 -5Q0 -11 13 -5V36Q0 42 -13 36Z","M-13 6Q-6 9 -5 20Q-2 24 1 19L3 3M-23 39H23"],"fine":["M-8 30V35M8 -2V29"]},
  {"id":"brazier","name":"Brazier","note":"A shallow ceremonial bowl holding three tongues of flame.","core":["M-37 11Q0 45 37 11Z","M-42 11H42M-12 33V40H12V33M-22 43H22","M-25 8Q-35 -8 -18 -25Q-19 -9 -7 -5M-7 8Q-19 -7 2 -40Q-1 -19 15 -7Q25 -21 25 -27Q41 -7 26 8"],"fine":["M-23 21Q0 31 23 21"]},
  {"id":"embers","name":"Embers","note":"Three irregular glowing coals with tiny rising sparks.","core":["M-40 28L-31 10L-11 13L-5 33L-25 40Z","M-6 30L4 3L24 8L29 31L10 41Z","M25 19L37 5L44 24L35 36L29 31","M-21 -6l4 -7M7 -15l-3 -9M26 -11l5 -7M-7 -31l2 -9"],"fine":["M-30 18L-22 22L-25 32M7 13L15 18L12 32M35 17L38 23"]},
  {"id":"spark","name":"Spark burst","note":"A sharp primary spark with a few scattered smaller marks.","core":["M0 -44Q3 -16 12 -10Q20 -4 44 0Q20 4 12 10Q3 16 0 44Q-3 16 -12 10Q-20 4 -44 0Q-20 -4 -12 -10Q-3 -16 0 -44Z","M-28 -31L-20 -23M28 -31L20 -23M-28 31L-20 23M28 31L20 23"],"fine":["M-39 -19l4 2M39 19l-4 -2"]},
  {"id":"torch","name":"Torch","note":"A hand-held torch with wrapped shaft and rising flame.","core":["M-10 6H10L7 42H-7Z","M-17 6H17V-1H-17Z","M-13 -1C-33 -14 -17 -28 -11 -40Q-12 -19 0 -16Q8 -27 7 -44C31 -24 32 -9 13 -1"],"fine":["M-9 13L8 23M-8 25L7 35M0 -16Q-7 -7 0 -3"]},
  {"id":"hearth","name":"Hearth","note":"A small pair of crossed fuel logs and a rising flame.","core":["M-3 14C-25 4 -22 -13 -12 -24Q-11 -12 -4 -9Q9 -23 5 -42C28 -24 34 0 14 14","M-1 14Q-10 6 1 -7Q3 4 9 14","M-39 23L29 41L40 31L-28 13Z","M-38 32L-26 42L-5 36M7 27L39 21L28 11L-2 20"],"fine":["M-20 20L-9 23M15 31L25 34M-13 36L-8 34M20 20L28 18"]},
  {"id":"flare","name":"Rising flare","note":"Three tapering tongues and a few sparks, without a surrounding seal.","core":["M-40 38C-20 28 -23 12 -27 3Q-32 -12 -19 -24Q-21 -8 -10 4Q3 21 -13 38","M-9 38C7 18 -6 4 -8 -9Q-12 -25 4 -43Q1 -24 16 -8Q32 14 12 38","M16 38C33 24 30 12 26 3Q20 -10 33 -22Q30 -10 41 5Q49 23 35 38"],"fine":["M-31 -32L-28 -39M23 -32L26 -39M40 -25L44 -31"]}
 ],
 horological:[
  {"id":"hourglass","name":"Hourglass","note":"A traditional sandglass with curved glass and narrow waist.","core":["M-28 -42H28V-35H-28Z M-28 35H28V42H-28Z","M-22 -35C-22 -13 -8 -8 0 0C8 8 22 13 22 35M22 -35C22 -13 8 -8 0 0C-8 8 -22 13 -22 35","M-18 -21Q0 -17 18 -21M-17 32L0 16L17 32Z"],"fine":["M0 4V11"]},
  {"id":"sundial","name":"Sundial","note":"An inclined gnomon within a gently marked dial.","core":["M-43 26A43 34 0 0 1 43 26Z","M-24 26L0 -28L14 26Z","M-35 13L-28 17M-25 -1L-20 7M-10 -7L-7 3M25 -1L20 7M35 13L28 17"],"fine":["M-43 33H43"]},
  {"id":"pendulum","name":"Pendulum","note":"A suspended bob with a restrained arc of travel.","core":["M-15 -40H15M0 -40V-31L-17 21","M-17 21A10 10 0 1 0 -17 41A10 10 0 1 0 -17 21Z","M-36 17A40 40 0 0 0 36 17"],"fine":["M0 -31L17 21M-31 29l-4 4M0 40v4M31 29l4 4"]},
  {"id":"balance","name":"Balance wheel","note":"A small spiral spring within a balanced wheel.","core":["M-42 0A42 42 0 1 0 42 0A42 42 0 1 0 -42 0Z","M-33 0A33 33 0 1 0 33 0A33 33 0 1 0 -33 0Z","M0 -33V-22M0 22V33M-33 0H-22M22 0H33","M0 0C-7 -7 -14 4 -8 12C5 26 28 10 23 -9C18 -29 -11 -31 -25 -12"],"fine":["M0 -42V-37M42 0H37M0 42V37M-42 0H-37"]},
  {"id":"bell","name":"Hour bell","note":"A cast bell with crown, lip and suspended clapper.","core":["M-8 -32Q-8 -41 0 -42Q8 -41 8 -32","M-21 23C-15 13 -14 5 -14 -9Q-14 -24 0 -32Q14 -24 14 -9C14 5 15 13 21 23L28 29H-28Z","M-28 29H28V35H-28Z","M0 35V38M-4 40A4 4 0 1 0 4 40A4 4 0 1 0 -4 40Z"],"fine":["M-13 -4Q0 0 13 -4M-17 21H17"]},
  {"id":"watch","name":"Pocket watch","note":"A clean dial suspended from its winding crown.","core":["M-35 4A35 35 0 1 0 35 4A35 35 0 1 0 -35 4Z","M-28 4A28 28 0 1 0 28 4A28 28 0 1 0 -28 4Z","M-7 -31V-38H7V-31M0 -38A6 6 0 1 0 0 -50A6 6 0 1 0 0 -38Z","M0 4V-15M0 4L15 13M0 -24V-20M0 32V28M-28 4H-24M28 4H24"],"fine":["M-20 -16L-17 -13M20 -16L17 -13M-20 24L-17 21M20 24L17 21"]},
  {"id":"clepsydra","name":"Water clock","note":"A vessel with a controlled drip and a graduated receiving bowl.","core":["M-25 -40H25L17 -15Q0 -7 -17 -15Z","M0 -10V-4Q-8 5 0 9Q8 5 0 -4","M-28 15H28L20 40H-20Z","M-24 25H24M-20 33H-13M-20 29H-13M-21 21H-14"],"fine":["M-17 -28H17M12 -22H18"]},
  {"id":"gear","name":"Clock wheel","note":"A restrained toothed wheel with four open spokes.","core":["M-32 -12L-42 -12V-4H-34L-34 4H-42V12H-32L-26 26L-31 34L-24 41L-17 33L-8 36V44H8V36L17 33L24 41L31 34L26 26L32 12H42V4H34V-4H42V-12H32L26 -26L31 -34L24 -41L17 -33L8 -36V-44H-8V-36L-17 -33L-24 -41L-31 -34L-26 -26Z","M-25 0A25 25 0 1 0 25 0A25 25 0 1 0 -25 0Z","M-6 0A6 6 0 1 0 6 0A6 6 0 1 0 -6 0Z","M-6 -6L-18 -18M6 -6L18 -18M6 6L18 18M-6 6L-18 18"],"fine":[]}
 ]
});
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const plain=v=>!!v&&typeof v==='object'&&!Array.isArray(v);
const keys=(o,allowed)=>plain(o)&&Object.keys(o).every(k=>allowed.includes(k));
const choice=(v,values)=>v===undefined||v===null||values.includes(v);
const families=Object.freeze({"Architectural":"plain","Astral":"astral","Botanical":"botanical","Bestiary":"bestiary","Elemental · Water":"water","Elemental · Air":"air","Elemental · Earth":"earth","Elemental · Fire":"fire","Horological":"horological"});
export function familyKey(f){return f==='None'?'':own(families,f)?families[f]:'plain';}
export function emblems(f){return catalogue[familyKey(f)]||[];}
export function emblem(f,key){const entries=emblems(f);return entries.find(e=>e.id===key)||entries[0]||null;}
const emblemIds=Object.values(catalogue).reduce((ids,entries)=>ids.concat(entries.map(e=>e.id)),[]);
export const borderStyles=Object.freeze(['none','ornate','rails','register','inset']);
export const centerStyles=Object.freeze(['none','seal','axis','span']);
export const glazingStyles=Object.freeze(['linework','subtle','moderate','clearer','graded','combined']);
export const materialRoles=Object.freeze(['panel','background','metal','engraving']);
export const containerKeys=Object.freeze(['emblem','border','center','fields','frame','backing','glazing','glazingDefault']);
function fieldError(fields,w,h){
 if(fields===undefined||fields===null)return null;
 if(!Array.isArray(fields)||fields.length>16)return 'Backing field budget exceeded';
 const ids=new Set();
 for(const f of fields){
  if(!keys(f,['id','x','y','w','h','opacity','family','emblem','border','center'])||
     typeof f.id!=='string'||!/^field-[0-9]{1,6}$/.test(f.id)||ids.has(f.id)||
     ![f.x,f.y,f.w,f.h].every(Number.isSafeInteger)||f.x<0||f.y<0||f.w<60||f.h<60||
     f.x+f.w>w||f.y+f.h>h||!Number.isFinite(f.opacity)||f.opacity<0||f.opacity>1||
     !choice(f.family,['None',...Object.keys(families)])||!choice(f.emblem,emblemIds)||
     !choice(f.border,borderStyles)||!choice(f.center,centerStyles))return 'Invalid backing field or bounds';
  ids.add(f.id);
 }
 for(let i=0;i<fields.length;i++)for(let j=i+1;j<fields.length;j++){
  const a=fields[i],b=fields[j];if(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y)return 'Backing engraving fields overlap';
 }
 return null;
}
export function containerError(a,c,isShelf){
 if(a===undefined)return null;
 if(!plain(a)||!choice(a.emblem,emblemIds)||!choice(a.border,borderStyles)||!choice(a.center,centerStyles)||
    !choice(a.frame,materialRoles)||!choice(a.backing,materialRoles)||!choice(a.glazing,glazingStyles)||
    !choice(a.glazingDefault,glazingStyles)||isShelf&&a.glazing!==undefined&&a.glazing!==null||
    !isShelf&&a.glazingDefault!==undefined&&a.glazingDefault!==null)return 'Invalid local appearance reference';
 return fieldError(a.fields,c.w,c.h);
}
// Default family glyphs use existing local SVGs. Non-default choices use
// only recovered static paths and theme ink; no arbitrary XML or URLs.
export function emblemSvg(f,key,ink){
 const e=emblem(f,key);
 if(!e||e.legacy||typeof ink!=='string'||!/^#[0-9a-fA-F]{6}$/.test(ink))return '';
 const path=(d,w)=>'<path d="'+d+'" fill="none" stroke="'+ink+'" stroke-width="'+w+'" stroke-linejoin="round" stroke-linecap="round"/>';
 let body=e.core.map(d=>path(d,1.5)).join('');
 if(e.radial)for(let i=0;i<e.radial[0];i++)body+='<g transform="rotate('+(360*i/e.radial[0])+')">'+path(e.radial[1],1.5)+'</g>';
 body+=(e.fine||[]).map(d=>path(d,.9)).join('');
 return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-55 -55 110 110" width="110" height="110">'+body+'</svg>';
}
export function suggestField(fields,w,h){
 const list=Array.isArray(fields)?fields:[];
 if(list.length>=16)return null;
 let id=1;while(list.some(f=>f.id==='field-'+id))id++;
 for(const size of [180,120,60])for(let y=0;y+size<=h;y+=20)for(let x=0;x+size<=w;x+=20){
  const field={id:'field-'+id,x,y,w:size,h:size,opacity:1};
  if(!fieldError(list.concat([field]),w,h))return field;
 }
 return null;
}

// Bounded themed corner linework adapted from S11r1 familyBorder. The
// geometry stays in the decorative field, separate from frame structure.
const corners={
 astral:'M0 40V0H40 M5 31V5H31 M0 26Q26 26 26 0 M0 18Q18 18 18 0',
 botanical:'M0 40Q14 30 9 19Q5 6 19 7Q30 10 40 0 M4 28Q20 22 10 12Q1 12 4 28Z M20 7Q19 21 33 14Q32 8 20 7Z M3 37Q12 42 20 30Q10 29 3 37Z',
 plain:'M0 40V0H40 M5 32V5H32 M10 25V10H25 M0 17H17V0',
 bestiary:'M0 40Q5 12 38 0 M3 28Q19 8 36 7 M9 19L6 7M15 14L15 3M20 10L28 16M6 27L16 29',
 water:'M0 40Q17 32 12 20Q7 7 22 7Q32 7 40 0 M0 29Q9 23 5 14Q1 4 14 0 M13 20Q28 19 25 8',
 air:'M0 40Q4 24 20 20Q36 16 40 0 M0 26Q1 13 12 10Q20 7 26 0 M14 32Q24 26 24 17',
 earth:'M0 40V0H40 M5 30V5H30 M10 22L18 10L30 10 M10 22L23 22L23 10',
 fire:'M0 40Q14 28 6 17Q1 9 10 0 M7 31Q28 22 21 11Q30 12 40 0 M13 24Q18 18 15 12',
 horological:'M0 40V0H40 M4 27Q27 27 27 4 M4 19Q19 19 19 4 M8 0V5M16 0V4M32 0V5M0 8H5M0 16H4M0 32H5'
};
export function borderSvg(f,style,w,h,ink){
 const corner=corners[familyKey(f)];
 if(!corner||!borderStyles.includes(style)||style==='none'||![w,h].every(Number.isFinite)||w<1||h<1||!/^#[0-9a-fA-F]{6}$/.test(ink))return '';
 const margin=Math.min(8,w*.04,h*.04),x=margin,y=margin,W=w-2*margin,H=h-2*margin;
 const d=Math.min(40,W*.24,H*.20),scale=d/40;
 const path=(d,extra='')=>'<path d="'+d+'" '+extra+'/>';
 let art='';
 for(const [xx,yy,sx,sy] of [[x,y,1,1],[x+W,y,-1,1],[x,y+H,1,-1],[x+W,y+H,-1,-1]])art+='<g transform="translate('+xx+' '+yy+') scale('+sx*scale+' '+sy*scale+')">'+path(corner)+'</g>';
 for(const [xx,yy,angle,len] of [[x,y,0,W],[x+W,y+H,180,W],[x+W,y,90,H],[x,y+H,-90,H]]){
  if(style==='rails'&&angle%180!==0)continue;
  const a=d+4,b=len-d-4;if(b<=a)continue;
  let edge='';
  if(style==='rails'||style==='inset')edge=path('M'+d+' 0H'+(len-d));
  if(style==='ornate')edge=path('M'+a+' 0h'+Math.min(14,(b-a)*.24)+' M'+(b-Math.min(14,(b-a)*.24))+' 0H'+b);
  if(style==='register')for(let i=0,n=Math.min(32,Math.max(1,Math.floor((b-a)/36)));i<n;i++){
   const at=a+(i+.5)*(b-a)/n,r=Math.min(12,(b-a)/n*.36);
   edge+=path('M'+(at-r)+' 0Q'+at+' '+Math.min(6,r)+' '+(at+r)+' 0 M'+at+' 0v'+Math.min(3,r));
  }
  art+='<g transform="translate('+xx+' '+yy+') rotate('+angle+')">'+edge+'</g>';
 }
 return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 '+w+' '+h+'" width="'+Math.ceil(w)+'" height="'+Math.ceil(h)+'"><g fill="none" stroke="'+ink+'" stroke-width="1.1" stroke-linejoin="round" stroke-linecap="round">'+art+'</g></svg>';
}

// S14r5 stone surface references, bounded local Room policy. Absent values
// retain the previous plain native surface; no implicit migration.
export const floorStyles=Object.freeze(['plain','slabs','bond','diagonal','octagon','hex','herringbone','basket','ashlar']);
export const wallStyles=Object.freeze(['plain','panel','masonry','rubble','pilaster','arcade','wainscot','ribbed']);
export const roomDefaults=Object.freeze({floor:'plain',wall:'plain',floorBorder:false,wallMarks:false,detail:55,floorScale:80,floorAngle:0,grout:.5,variation:30,borderStyle:'double',wallScale:150});
export const roomKeys=Object.freeze(Object.keys(roomDefaults));
export function extended(s){return Object.values(s.cubbies||{}).some(c=>plain(c.appearance)&&containerKeys.some(k=>own(c.appearance,k)))||!!(s.spatial&&own(s.spatial,'mapAppearance'))||Object.values(s.spatial&&s.spatial.rooms||{}).some(r=>own(r,'mapAppearance')||plain(r.appearance)&&roomKeys.some(k=>own(r.appearance,k)));}
export function roomError(a){
 if(a===undefined)return null;
 if(!keys(a,['family','palette',...roomKeys]))return 'Invalid Room appearance reference';
 const num=(v,min,max,integer)=>v===undefined||v===null||Number.isFinite(v)&&v>=min&&v<=max&&(!integer||Number.isInteger(v));
 const bool=v=>v===undefined||v===null||typeof v==='boolean';
 if(!choice(a.floor,floorStyles)||!choice(a.wall,wallStyles)||!choice(a.floorAngle,[0,45,90])||!choice(a.borderStyle,['single','double','band','diamond'])||
 !bool(a.floorBorder)||!bool(a.wallMarks)||!num(a.detail,0,100,true)||!num(a.floorScale,24,160,true)||!num(a.grout,.5,4,false)||!num(a.variation,0,100,true)||!num(a.wallScale,75,250,true))return 'Invalid Room surface policy';
 return null;
}
export function roomPolicy(a){const out=Object.assign({},roomDefaults);for(const k of roomKeys)if(a&&a[k]!==undefined&&a[k]!==null)out[k]=a[k];return out;}


// S19r3/r4 atlas appearance is document metadata, not camera state or
// interior surface policy. Local map overrides inherit chart defaults.
export const mapDefaults=Object.freeze({title:'The Map Room',subtitle:'',family:'Astral',ornament:'compass',contours:'subtle',density:55,frame:'engraved',labels:'both',marks:'detail'});
export const mapKeys=Object.freeze(Object.keys(mapDefaults));
export const mapRoomKeys=Object.freeze(['subtitle','frame','labels','marks']);
export function mapError(a,local=false){
 if(a===undefined)return null;
 if(!keys(a,local?mapRoomKeys:mapKeys))return 'Invalid atlas appearance keys';
 const str=(v,max)=>v===undefined||typeof v==='string'&&v.length<=max;
 const pick=(v,values)=>v===undefined||local&&v===null||values.includes(v);
 if(!str(a.subtitle,local?160:120)||!pick(a.frame,['plain','inset','engraved'])||!pick(a.labels,['title','both'])||!pick(a.marks,['none','detail','all']))return 'Invalid atlas inscription or representation';
 if(!local&&(!str(a.title,80)||!pick(a.family,['None',...Object.keys(families)])||!pick(a.ornament,['none','family','compass'])||!pick(a.contours,['none','subtle','engraved'])||a.density!==undefined&&(!Number.isInteger(a.density)||a.density<0||a.density>100)))return 'Invalid chart appearance';
 return null;
}
export function mapPolicy(s){return Object.assign({},mapDefaults,s.spatial&&s.spatial.mapAppearance||{});}
export function mapRoomPolicy(s,id){const a=mapPolicy(s),r=s.spatial.rooms[id],v=r&&r.mapAppearance||{};return {subtitle:v.subtitle||'',frame:v.frame||a.frame,labels:v.labels||a.labels,marks:v.marks||a.marks};}

