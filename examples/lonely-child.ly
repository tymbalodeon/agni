\version "2.23.80"
\language "english"

\header {
  title = "Lonely Child"
  composer = "Claude Vivier"
  tagline = ##f
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
  \repeat unfold 2 {
    s1 s4
  }
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
  \repeat unfold 2 {
    s1 s4
  }
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

melody = \relative c'' {
  a1~ a4
  bf8 a bf1
  \tuplet 3/2 { a8 a4 }
  \tuplet 3/2 { bf8 bf4 }
  a8 bf4.~
  bf2.
  \tuplet 3/2 { a8 a a }
  bf1~ bf4

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
}

bass = \relative c {
  \clef "bass_8"
  g1~ g4~
  g~ g1
  g2 g~
  g1
  fs~ fs4

  fs2.~ fs2~
  fs4 fs2.
  fs~
  fs1.
  fs1.

  fs2.
  e2 e1
  e1.
  f8~ f1~
  f

  f1~ f4
  f2 f1
  f8~ f2.

  f1 ~ f2 f1.

  ef1 ~ ef2.
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
