\version "2.24.0"
\language "english"

\header {
  title = "Lonely Child"
  composer = "Claude Vivier"
  tagline = ##f
}

intro_rests = {
  R1 * 13/4
  R2. * 3
  R1
  R2.
  R1
  R2.
  R2
  R1 * 2
  R2. * 3
  R1 * 2
  R1.
  R8
  R1
  R1 * 5/4
  R2
  R1 * 5/4
  R \breve
}

intro_space = {
  \time 13/4
  s \breve s1 s4
  \time 3/4
  s2. * 3
  \time 4/4
  s1
  \time 3/4
  s2.
  \time 4/4
  s1
  \time 3/4
  s2.
  \time 2/4
  s2
  \time 4/4
  s1 * 2
  \time 3/4
  s2. * 3
  \time 4/4
  s1 * 2
  \time 6/4
  s1.
  \time 1/8
  s8
  \time 4/4
  s1
  \time 5/4
  s1 s4
  \time 2/4
  s2
  \time 5/4
  s1 s4
  \time 8/4
  s \breve

  \bar "||"
}

structure = {
  \time 5/4
  s1 s4
  s1 s4
  \time 4/4
  s1 * 2
  \time 5/4
  s1 s4

  s1 s4
  \time 4/4
  s1
  \time 3/4
  s2.
  \time 6/4
  s1 s2
  s1 s2

  \time 3/4
  s2.
  \time 6/4
  s1 s2
  s1 s2
  \time 9/8
  s1 s8
  \time 4/4
  s1

  \time 5/4
  s1 s4
  \time 6/4
  s1 s2
  \time 7/8
  s2. s8

  \bar "||"

  \time 4/4
  s1
  \time 8/4
  s1 * 2

  \bar "||"

  \time 4/4
  s1
  \time 3/4
  s2.
  \time 4/4
  s1
  \time 5/4
  s1 s4
  \time 6/4
  s1 s2
  \time 3/4
  s2.
  \time 6/4
  s1 s2
  \time 4/4
  s1
  \time 5/4
  s1 s4
  \time 6/4
  s1 s2

  \bar "||"

  \time 4/4
  s1 |
  \time 3/4
  s2. * 2|
  \time 5/4
  s1 s4
  \time 4/4
  s1
  \time 3/4
  s2.
  \time 7/16
  s4 s16 * 3
  \time 5/8
  s2 s8
  \time 3/8
  s4 s8
  \time 9/16
  s2 s16
  \time 3/4
  s2 s4
  \time 4/4
  s1 * 2
  \time 3/4
  s2 s4
  \time 2/4
  s2
  \time 5/16
  s4 s16
  \time 5/8
  s2 s8
  \time 11/16
  s2 s16 * 3
  \time 5/16
  s4 s16
  \time 5/8
  s2 s8
  \time 9/16
  s2 s16
  \time 3/8
  s4 s8
  \time 3/4
  s2 s4
  \time 5/4
  s1 s4
  \time 3/8
  s4 s8
  \time 9/16
  s2 s16
  \time 15/16
  s2. s16 * 3
  \time 11/16
  s2 s16 * 3
  \time 7/8
  s2. s8
  \time 3/8
  s4 s8
  \time 9/16
  s2 s16
  \time 7/8
  s2. s8
  \time 5/4
  s1 s4
  \time 4/4
  s1

  \bar "||"

  \time 3/4
  s2.
  \time 4/4
  s1 * 4
  \time 3/4
  s2.
  \time 4/4
  s1 * 2
  \time 3/4
  s2.
  \time 4/4
  s1
  \time 3/4
  s2.
  \time 4/4
  s1
  \time 3/4
  s2. * 2
  \time 5/4
  s1 s4
  s1 s4
  \time 3/4
  s2. * 2
  \time 4/4
  s1 * 2
  \time 3/4
  s2. * 2
  \time 4/4
  s1 * 2
  \time 2/4
  s2
  \time 3/4
  s2. * 3

  \bar "||"

  \time 5/4
  s1 s4
  \time 3/4
  s2.
  \time 4/4
  s1 * 2
  \time 2/4
  s2
  \time 6/4
  s1.
  \time 3/4
  s2.
  \time 5/4
  s1 s4
  \time 4/4
  s1
  \time 6/4
  s1.
  \time 4/4
  s1
  \time 5/4
  s1 s4
  s1 s4
  \time 4/4
  s1 * 2
  \time 5/4
  s1 s4
  \time 3/4
  s2.
  \time 2/4
  s2
  \time 4/4
  s1 * 3
  \time 2/4
  s2
  \time 3/4
  s2.
  \time 4/4
  s1
  \time 6/4
  s1.
  \time 3/4
  s2. * 2
  \time 3/8
  s4.
  \time 3/4
  s2.
  \time 4/4
  s1
  \time 3/4
  s2.

  \bar "||"

  \time 4/4
  s1
  \time 3/4
  s2.

  \bar "||"

  \time 5/4
  s1 s4
  \time 4/4
  s1
  \time 3/4
  s2.

  \bar "||"
}

melody = \relative a' {
  a1~ a4
  bf8 a bf1
  \tuplet 3/2 { a8 a4 } \tuplet 3/2 { bf8 bf4 } a8 bf4.~
  bf2. \tuplet 3/2 { a8 a a }
  bf1 ~ bf4

  bf2. c2
  \tuplet 3/2 { bf8 c4 } df2.
  \tuplet 3/2 { df8 bf4 } c2
  df1.
  \tuplet 3/2 { df8 bf4~ } bf \tuplet 3/2 { df8 c bf~ } bf2 c4

  df2.
  d!2 d1
  d1.
  e8 b4 a b8 a4.
  b4. a8 e' ds4 e8

  b4 a8 b4. a4 b
  a8 e'4 ds8 b4 a b a
  e'8 ds2.

  b2. a4
  e'2 ds1.

  f4 gf8 bf, gf'16 bf,8.~ bf4
  gf'8. gf16 bf,2
  cf1
  bf8 cf4 bf8~ bf4 cf2
  g'1.
  bf,8 bf4 bf4.
  f'4 gf2 bf,2.
  cf1
  bf8 cf4 bf8~ bf4 cf2
  g'1.

  bf,16 b8 bf16 ~ bf8 bf ~ bf bf ~ bf8. r16
  g2.
  bf2. ~
  bf16 g8. ~ g2. bf4 ~
  bf4 ~ bf8 a ~ a2
  a2 ~ a8. a16 ~
  a4 ~ a16 a8 ~
  a8. a16 ~ a8. a
  a8 fs4 ~
  fs16 cs'2
  cs2. ~
  cs16 cs8. ~ cs2. ~
  cs4 d f,2 ~
  f2 ef'32 ef ef ef ef16 f, ~
  f2 ~
  f4 ef'16 ~
  ef16 ef8. ~ ef8 ef8. ef16 ~
  ef8. c2 ~
  c4 af32 c ~
  c4 ~ c16 af c af8. ~
  af8. af32 c16. ~ c16 ~ c8. ~
  c4 af32 c16. ~
  c2. ~
  c8 af32 c16. ~ c8 ef ~ ef4 ~ ef16 c8. ~ c4 ~
  c4 ~ c16 c ~
  c4 c8 ~ c8. ~
  c16 c c8 c16 c8. c16 c4 c8 ~
  c8. d16 ~ d4 ~ d8. ~
  d4 ~ d8 ef ~ ef4 ~ ef8 ~
  ef4 ~ ef16 ef ~
  ef4 ef8 ~ ef8. ~
  ef8. cs16 ~ cs2 ~ cs8 ~
  cs8 cs ~ cs2 cs
  d1

  as8 cs4 b8 ~ b16 ds e8
  gs8. a16 ~ a8. d,16 ef8 d ~ d16 ef8. ~
  ef16 d bf d ~ d d8. bf4 a16 bf8 c16
  g4. af8 ~ af g af16 cf bf8 ~
  bf4 ~ bf8 f'16 df ~ df8. c16 df f gf8 ~
  gf4 a,16 bf c8 ef32 ef16. c8
  as2 b8. cs16 ds e8 gs16 ~
  gs8 a ~ a16. gs32 ef8 ~ ef \tuplet 3/2 { ds ef16 } df32 cf16. ~ cf16 bf ~
  bf8 b gs'8. cs,16 ~ cs e e8
  g,2 gs8. as16 gs8 cs16 as
  gs4 ~ gs16 f' cs as gs4
  d'4 cs4. e16 d ~ d8 e16 d
  a4
  d16 ef g d ~ d4
  d16 g af8 ~ af4 bf16 a8.
  e4 d16 e8 g16 ~ g8 cs, ~ cs4 d

  d16 ef8 g16 ~ g8 d ~ d a ~ a4 bf
  fs2 g16 a8 c16
  e2.
  d8. cs16 e8 d16 g ~ g8. ef16 \tuplet 3/2 { d16 ef8 d16 ef8 }
  f2 gf4 af16 gf af8
  af16 gf8. ~ gf f16 ~ \tuplet 3/2 { f8 gf16 gf f8 }
  d4. ef8 \tuplet 3/2 { f af16 af f8 }
  ds2. e8 fs ~
  fs e ~ e4 ds16 e ds e ds4 ~
  ds16 e a fs ~ fs cs8.
  f4 gf ~ gf8 f16 gf
  b,8 gs b16 gs8. b gs16
  f'4 gf2
}

bass = \relative g, {
  \clef "bass_8"

  g1~ g4~
  g~ g1
  g2 g~
  g1
  fs~ fs4

  fs2. ~ fs2 ~
  fs4 fs2.
  fs~
  fs1.
  fs1.

  fs2.
  e2 e1
  e1.
  f8~ f1~
  f

  f1 ~ f4
  f2 f1
  f8 ~ f2.
  f1 ~
  f2 f1.

  ef1 ~
  ef2.
  ef1
  ef1 ~ ef4
  ef1.
  ef2.
  ef1.
  ef1
  ef1 ~ ef4
  ef1.

  ef2. ~ ef8. f16 ~
  f2 ~ f8 d ~
  d2 ~ d8 e ~
  e2. b2 ~
  b16 ef8. ~ ef f16 ~ f2
  f8. b,16 ~ b2 ~
  b8 d ~ d8. ~
  d4 d4.
  c4.
  d16 ~ d2
  df2. ~
  df16 e8. ~ e2 ~ e8 ef ~
  ef4 ef8. df16 ~ df2 ~
  df8. a16 ~ a4 ~ a16 g8. ~
  g2
  af4 ~ af16 ~
  af4 ~ af4.
  df8. ~ df2
  ef4 ~ ef16 ~
  ef4 ef4.
  cs8.~ cs ~ cs
  fs4.
  af2.
  g2 ~ g8. df16 ~ df2
  fs4.
  bf4. ~ bf8.
  f2. ~ f8.
  b2 ~ b8.
  g2. ~ g8
  a4.
  e4. ~ e8.
  f2. ~ f8
  bf2 ~ bf8. b16 ~ b2
  g1

  ef2. ~
  ef1 ~
  ef2. f4 ~
  f1 ~
  f1 ~
  f4 ef2
  d1 ~
  d1
  b2.
  e1 ~
  e2.
  as,1
  b2. ~
  b2. ~
  b1 ~ b4
  d1 ~ d4
  c2. ~
  c2.
  e1
  df1 ~
  df2.
  ef2.
  af1 ~
  af1
  a2
  g2. ~
  g2. ~
  g2.

  c,8. ef16 ef8 c ef2.
  c16 ef c32 ef16. ef2
  ef4
  \tuplet 3/2 { ef16 ef8 }
  \tuplet 3/2 { ef16 ef8 ~ }
  \tuplet 3/2 { ef16 ef8 ~ }
  ef8 ~ ef4
  c1
  ef2
  c4 ~ c16 ef8. ~ ef4. ef8 ~ ef2
  ef8. ef16 ~ ef c c ef ~ ef ef8.
  ef16 ef8 ef16 ~ ef8 ef ~ ef c ~ c ef ~ ef16 ef8 ef16
  c8 ef ~ ef4. ef8 ~ ef4
  d4 d2 d2.
  d1
  d1 ~ d4
  f8 f4. ~ f8 f ~ f f~ f4
  f16 gf8. ~ gf16 f f gf ~ gf4 ~ gf8 f16 f
  f gf8. ~ gf f16 ~ f f8 gf16 ~ gf4
  f1 ~ f4
  gf2.
  f16 gf bf8 gf16 bf8 gf16 ~
  gf8 f gf16 bf gf bf gf f8. gf16 bf gf bf
  gf8. gf16 bf gf f8 ~ f16 gf bf gf ~ gf8. bf16
  g16 c8 bf16 ~ bf8 gf16 f ~ f f f8 gf16 bf8 g16 ~
  g8 c ~ c4
  gf16 gf bf8 ~ bf16 g c8 r g16 bf
  g8 bf4. g8 bf g4
  d4 c2 d2.
  \tuplet 3/2 { bf8 g d' } c2
  d4. c8 ~ c d
  R4.
  d16 f8 bf16 ~ bf c d8 r4
  c2. d4
  c,16 ef ef8 \tuplet 3/2 { d f bf } c d

  e,,1
  ds2.

  e8 ds4 e4. ds2
  R1
  e4. ds4 e8
}

melody = {
  <<
    \melody
    \structure
  >>
}

bass = {
  <<
    \bass
    \structure
  >>
}

\score {
  \new StaffGroup {
    \numericTimeSignature
    <<
      \new Staff = "melody" {
        \melody
      }
      \new Staff = "bass" {
        \bass
      }
    >>
  }
}
