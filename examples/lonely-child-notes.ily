\header {
  title = "Lonely Child"
  composer = "Claude Vivier"
}

restsOne = {
  \time 13/4

  | R1 * 13/4

  \time 3/4

  | R2. * 3

  \time 4/4

  | R1

  \time 3/4

  | R2.

  \time 4/4

  | R1

  \time 3/4

  | R2.

  \time 2/4

  | R2

  \time 4/4

  | R1 * 2

  \time 3/4

  | R2. * 3

  \time 4/4

  | R1 * 2

  \time 6/4

  | R1.

  \time 1/8

  | R8

  \time 4/4

  | R1

  \time 5/4

  | R1 * 5/4

  \time 2/4

  | R2

  \time 5/4

  | R1 * 5/4

  \time 8/4

  | R \breve
}

restsTwo = {
  \time 5/8

  | R1 * 10/8

  \time 3/4

  | R2.

  \time 5/8

  | R1 * 5/8

  \time 4/4

  | R1

  \time 3/8

  | R8 * 3

  \time 2/4

  | R2

  \time 5/8

  | R1 * 5/8

  \time 2/4

  | R2

  \time 3/4

  | R2.

  \time 5/8

  | R1 * 5/8

  \time 2/4

  | R2
}

restsThree = {
  \time 1/4

  | R4
}

restsFour = {
  \time 5/8

  | R8 * 5

  \time 5/16

  | R16 * 5

  \time 5/8

  | R8 * 5

  \time 9/16

  | R16 * 9

  \time 2/4

  | R2

  \time 7/16

  | R16 * 7

  \time 3/8

  | R8 * 3

  \time 5/16

  | R16 * 5

  \time 2/8

  | R8 * 2

  \time 3/8

  | R8 * 3

  \time 2/4

  | R2
}

restsFive = {
  \time 3/4

  | R2.
}

restsSix = {
  \time 10/4

  | R4 * 10

  \time 9/4

  | R4 * 9

  \time 8/4

  | R4 * 8

  \time 7/4

  | R4 * 7

  \time 6/4

  | R4 * 6

  \time 5/4

  | R4 * 5

  \time 10/4

  | R4 * 10

  \time 5/4

  | R4 * 10
}

restsSeven = {
  \time 3/8

  | R8 * 3
}

restsEight = {
  \time 1/8

  | R8

  \time 8/4

  | R \breve

  \time 5/4

  | R4 * 5

  \time 3/4

  | R2.
}

restsNine = {
  \time 3/4

  | R2. * 2
}

restsTen = {
  \time 4/4

  | R1
}

restsEleven = {
  \time 3/4

  | R2. * 8

  \time 5/4

  | R4 * 5

  \time 3/4

  | R2.

  \time 4/4

  | R1 * 3

  \time 2/4

  | R2

  \time 4/4

  | R1 * 2

  \time 6/4

  | R4 * 6

  \time 4/4

  | R1 * 2

  \time 3/4

  | R2.

  \time 5/4

  | R4 * 10

  \time 3/4

  | R2.
}

melodyOne = \relative a' {
  \time 5/4

  | a1 ~ a4
  | bf8 a bf1

  \tuplet 3/2 {

    \time 4/4

    | a8 a4
  }

  \tuplet 3/2 { bf8 bf4 } a8 bf4. ~
  | bf2. \tuplet 3/2 { a8 a a }

  \time 5/4

  | bf1 ~ bf4
  | bf2. c2

  \tuplet 3/2 {

    \time 4/4

    | bf8 c4
  } df2.


  \tuplet 3/2 {

    \time 3/4

    | df8 bf4
  } c2

  \time 6/4

  | df1.
  \tuplet 3/2 { df8 bf4 ~ } bf \tuplet 3/2 { df8 c bf ~ } bf2 c4

  \time 3/4

  | df2.

  \time 6/4

  | d!2 d1
  | d1.

  \time 9/8

  | e8 b4 a b8 a4.

  \time 4/4

  | b4. a8 e' ds4 e8

  \time 5/4

  | b4 a8 b4. a4 b

  \time 6/4

  | a8 e'4 ds8 b4 a b a

  \time 7/8

  | e'8 ds2.
}

melodyTwo = \relative b' {
  \time 4/4

  | b2. a4

  \time 8/4

  | e'2 ds1.
}

melodyThree = \relative f'' {
  \time 4/4

  | f4 gf8 bf, gf'16 bf,8.~ bf4

  \time 3/4

  | gf'8. gf16 bf,2

  \time 4/4

  | cf1

  \time 5/4

  | bf8 cf4 bf8~ bf4 cf2

  \time 6/4

  | g'1.

  \time 3/4

  | bf,8 bf4 bf4.

  \time 6/4

  | f'4 gf2 bf,2.

  \time 4/4

  | cf1

  \time 5/4

  | bf8 cf4 bf8~ bf4 cf2

  \time 6/4

  | g'1.
}

melodyFour = \relative bf' {
  \time 4/4

  | bf16 b8 bf16 ~ bf8 bf ~ bf bf ~ bf8. r16

  \time 3/4

  | g2.
  | bf2. ~

  \time 5/4

  | bf16 g8. ~ g2. bf4 ~

  \time 4/4

  | bf4 ~ bf8 a ~ a2

  \time 3/4

  | a2 ~ a8. a16 ~

  \time 7/16

  | a4 ~ a16 a8 ~

  \time 5/8

  | a8. a16 ~ a8. a

  \time 3/8

  | a8 fs4 ~

  \time 9/16

  | fs16 cs'2

  \time 3/4

  | cs2. ~

  \time 4/4

  | cs16 cs8. ~ cs2. ~
  | cs4 d f,2 ~

  \time 3/4

  | f2 ef'32 ef ef ef ef16 f, ~

  \time 2/4

  | f2 ~

  \time 5/16

  | f4 ef'16 ~

  \time 5/8

  | ef16 ef8. ~ ef8 ef8. ef16 ~

  \time 11/16

  | ef8. c2 ~

  \time 5/16

  | c4 af32 c ~

  \time 5/8

  | c4 ~ c16 af c af8. ~

  \time 9/16

  | af8. af32 c16. ~ c16 ~ c8. ~

  \time 3/8

  | c4 af32 c16. ~

  \time 3/4

  | c2. ~

  \time 5/4

  | c8 af32 c16. ~ c8 ef ~ ef4 ~ ef16 c8. ~ c4 ~

  \time 3/8

  | c4 ~ c16 c ~

  \time 9/16

  | c4 c8 ~ c8. ~

  \time 15/16

  | c16 c c8 c16 c8. c16 c4 c8 ~

  \time 11/16

  | c8. d16 ~ d4 ~ d8. ~

  \time 7/8

  | d4 ~ d8 ef ~ ef4 ~ ef8 ~

  \time 3/8

  | ef4 ~ ef16 ef ~

  \time 9/16

  | ef4 ef8 ~ ef8. ~

  \time 7/8

  | ef8. cs16 ~ cs2 ~ cs8 ~

  \time 5/4

  | cs8 cs ~ cs2 cs

  \time 4/4

  | d1
}

melodyFive = \relative as' {
  \time 3/4

  | as8 cs4 b8 ~ b16 ds e8

  \time 4/4

  | gs8. a16 ~ a8. d,16 ef8 d ~ d16 ef8. ~
  | ef16 d bf d ~ d d8. bf4 a16 bf8 c16
  | g4. af8 ~ af g af16 cf bf8 ~
  | bf4 ~ bf8 f'16 df ~ df8. c16 df f gf8 ~

  \time 3/4

  | gf4 a,16 bf c8 ef32 ef16. c8

  \time 4/4

  | as2 b8. cs16 ds e8 gs16 ~
  | gs8 a ~ a16. gs32 ef8 ~ ef \tuplet 3/2 { ds ef16 }
  df32 cf16. ~ cf16 bf ~

  \time 3/4

  | bf8 b gs'8. cs,16 ~ cs e e8

  \time 4/4

  | g,2 gs8. as16 gs8 cs16 as

  \time 3/4

  | gs4 ~ gs16 f' cs as gs4

  \time 4/4

  | d'4 cs4. e16 d ~ d8 e16 d

  \time 3/4

  | a4 d16 ef g d ~ d4
  | d16 g af8 ~ af4 bf16 a8.

  \time 5/4

  | e4 d16 e8 g16 ~ g8 cs, ~ cs4 d
  | d16 ef8 g16 ~ g8 d ~ d a ~ a4 bf

  \time 3/4

  | fs2 g16 a8 c16
  | e2.

  \time 4/4

  | d8. cs16 e8 d16 g ~ g8. ef16 \tuplet 3/2 { d16 ef8 d16 ef8 }
  | f2 gf4 af16 gf af8

  \time 3/4

  | af16 gf8. ~ gf f16 ~ \tuplet 3/2 { f8 gf16 gf f8 }
  | d4. ef8 \tuplet 3/2 { f af16 af f8 }

  \time 4/4

  | ds2. e8 fs ~
  | fs e ~ e4 ds16 e ds e ds4 ~

  \time 2/4

  | ds16 e a fs ~ fs cs8.

  \time 3/4

  | f4 gf ~ gf8 f16 gf
  | b,8 gs b16 gs8. b gs16
  | f'4 gf2
}

melodySix = \relative e' {
  \time 5/4

  | e8. g16 g8 e g2.

  \time 3/4

  | e16 g e32 g16. af2

  \time 4/4
  | g4 \tuplet 3/2 { af16 g8 } \tuplet 3/2 { af16 g8 ~ }
  g \tuplet 3/2 { af16 g8 ~ } g4
  | e1

  \time 2/4

  | g2

  \time 6/4

  | e4 ~ e16 g8. ~ g4. af8 ~ af2

  \time 3/4

  | af8. g16 ~ g e e g ~ g af8.

  \time 5/4

  | af16 g8 af16 ~ af8 g ~ g e ~ e g ~ g16 af8 g16

  \time 4/4

  | e8 g ~ g4. af8 ~ af4

  \time 6/4

  | b4 b 2 b2.

  \time 4/4

  | b1

  \time 5/4

  | b1 ~ b4
  | c8 c4. ~ c8 c ~ c c ~ c4

  \time 4/4

  | c16 d8. ~ d16 c c d ~ d4 ~ d8 c16 c
  | c16 d8. ~ d c16 ~ c c8 d16 ~ d4

  \time 5/4

  | c1 ~ c4

  \time 3/4

  | d2.

  \time 2/4

  | c16 d ef8 d16 ef8 d16 ~

  \time 4/4

  | d8 c d16 ef d ef d c8. d16 ef d ef
  | d8. d16 ef d c8 ~ c16 d ef d ~ d8. ef16
  | e16 e8 ef16 ~ ef8 d16 c ~ c c c8 d16 ef8 e16 ~

  \time 2/4

  | e8 e ~ e4

  \time 3/4

  | d16 d ef8 ~ ef16 e e8 r e16 ef

  \time 4/4

  | e8 ef4. e8 ef e4

  \time 6/4

  | g4 af2 g2.

  \tuplet 3/2 {

    \time 3/4

    | ds8 e g
  } af2
  | g4. af8 ~ af g
}

melodySeven = \relative b' {
  \time 3/4

  | b16 c8 ds16 ~ ds e g8 r4

  \time 4/4

  | af2. g4

  \time 3/4

  | e,16 g af8 \tuplet 3/2 { b c ds } e g
}

melodyEight = \relative e'' {
  \time 4/4

  | e1

  \time 3/4

  | ds2.
}

melodyNine = \relative e'' {
  \time 5/4

  | e8 ds4 e4. ds2
}

melodyTen = \relative e'' {
  \time 3/4

  | e4. ds4 e8
}

bassOne = \relative g, {
  \clef "bass_8"

  \time 5/4

  | g1 ~ g4 ~
  | g ~ g1

  \time 4/4

  | g2 g ~
  | g1

  \time 5/4

  | fs ~ fs4
  | fs2. ~ fs2 ~

  \time 4/4

  | fs4 fs2.

  \time 3/4

  | fs2. ~

  \time 6/4

  | fs1.
  | fs1.

  \time 3/4

  | fs2.

  \time 6/4

  | e2 e1
  | e1.

  \time 9/8

  | f8 ~ f1 ~

  \time 4/4

  | f1

  \time 5/4

  | f1 ~ f4

  \time 6/4

  | f2 f1

  \time 7/8

  | f8 ~ f2.
}


bassTwo = \relative f, {
  \time 4/4

  | f1 ~

  \time 8/4

  | f2 f1.
}

bassThree = \relative ef, {
  \time 4/4

  | ef1 ~

  \time 3/4

  | ef2.

  \time 4/4

  | ef1

  \time 5/4

  | ef1 ~ ef4

  \time 6/4

  | ef1.

  \time 3/4

  | ef2.

  \time 6/4

  | ef1.

  \time 4/4

  | ef1

  \time 5/4

  | ef1 ~ ef4

  \time 6/4

  | ef1.
}

bassFour = \relative ef, {
  \time 4/4

  | ef2. ~ ef8. f16 ~

  \time 3/4

  | f2 ~ f8 d ~
  | d2 ~ d8 e ~

  \time 5/4

  | e2. b2 ~

  \time 4/4

  | b16 ef8. ~ ef f16 ~ f2

  \time 3/4

  | f8. b,16 ~ b2 ~

  \time 7/16

  | b8 d ~ d8. ~

  \time 5/8

  | d4 d4.

  \time 3/8

  | c4.

  \time 9/16

  | d16 ~ d2

  \time 3/4

  | df2. ~

  \time 4/4

  | df16 e8. ~ e2 ~ e8 ef ~
  | ef4 ef8. df16 ~ df2 ~

  \time 3/4

  | df8. a16 ~ a4 ~ a16 g8. ~

  \time 2/4

  | g2

  \time 5/16

  | af4 ~ af16 ~

  \time 5/8

  | af4 ~ af4.

  \time 11/16

  | df8. ~ df2

  \time 5/16

  | ef4 ~ ef16 ~

  \time 5/8

  | ef4 ef4.

  \time 9/16

  | cs8.~ cs ~ cs

  \time 3/8

  | fs4.

  \time 3/4

  | af2.

  \time 5/4

  | g2 ~ g8. df16 ~ df2

  \time 3/8

  | fs4.

  \time 9/16

  | bf4. ~ bf8.

  \time 15/16

  | f2. ~ f8.

  \time 11/16

  | b2 ~ b8.

  \time 7/8

  | g2. ~ g8

  \time 3/8

  | a4.

  \time 9/16

  | e4. ~ e8.

  \time 7/8

  | f2. ~ f8

  \time 5/4

  | bf2 ~ bf8. b16 ~ b2

  \time 4/4

  | g1
}

bassFive = \relative ef, {
  \time 3/4

  | ef2. ~

  \time 4/4

  | ef1 ~
  | ef2. f4 ~
  | f1 ~
  | f1 ~

  \time 3/4

  | f4 ef2

  \time 4/4

  | d1 ~
  | d1

  \time 3/4

  | b2.

  \time 4/4

  | e1 ~

  \time 3/4

  | e2.

  \time 4/4

  | as,1

  \time 3/4

  | b2. ~
  | b2. ~

  \time 5/4

  | b1 ~ b4
  | d1 ~ d4

  \time 3/4

  | c2. ~
  | c2.

  \time 4/4

  | e1
  | df1 ~

  \time 3/4

  | df2.
  | ef2.

  \time 4/4

  | af1 ~
  | af1

  \time 2/4

  | a2

  \time 3/4

  | g2. ~
  | g2. ~
  | g2.
}

bassSix = \relative c, {
  \time 5/4

  | c8. ef16 ef8 c ef2.

  \time 3/4

  | c16 ef c32 ef16. ef2

  \time 4/4

  | ef4
  \tuplet 3/2 { ef16 ef8 }
  \tuplet 3/2 { ef16 ef8 ~ }
  \tuplet 3/2 { ef16 ef8 ~ }
  ef8 ~ ef4
  | c1

  \time 2/4

  | ef2

  \time 6/4

  | c4 ~ c16 ef8. ~ ef4. ef8 ~ ef2

  \time 3/4

  | ef8. ef16 ~ ef c c ef ~ ef ef8.

  \time 5/4

  | ef16 ef8 ef16 ~ ef8 ef ~ ef c ~ c ef ~ ef16 ef8 ef16

  \time 4/4

  | c8 ef ~ ef4. ef8 ~ ef4

  \time 6/4

  | d4 d2 d2.

  \time 4/4

  | d1

  \time 5/4

  | d1 ~ d4
  | f8 f4. ~ f8 f ~ f f~ f4

  \time 4/4

  | f16 gf8. ~ gf16 f f gf ~ gf4 ~ gf8 f16 f
  | f gf8. ~ gf f16 ~ f f8 gf16 ~ gf4

  \time 5/4

  | f1 ~ f4

  \time 3/4

  | gf2.

  \time 2/4

  | f16 gf bf8 gf16 bf8 gf16 ~

  \time 4/4

  | gf8 f gf16 bf gf bf gf f8. gf16 bf gf bf
  | gf8. gf16 bf gf f8 ~ f16 gf bf gf ~ gf8. bf16
  | g16 c8 bf16 ~ bf8 gf16 f ~ f f f8 gf16 bf8 g16 ~

  \time 2/4

  | g8 c ~ c4

  \time 3/4

  | gf16 gf bf8 ~ bf16 g c8 r g16 bf

  \time 4/4

  | g8 bf4. g8 bf g4

  \time 6/4

  | d4 c2 d2.

  \tuplet 3/2 {

    |   \time 3/4

    |   | bf8 g d'
  } c2
  | d4. c8 ~ c d
}

bassSeven = \relative d, {
  \time 3/4

  | d16 f8 bf16 ~ bf c d8 r4

  \time 4/4

  | c2. d4

  \time 3/4

  | c,16 ef ef8 \tuplet 3/2 { d f bf } c d
}

bassEight = \relative e,, {
  \time 4/4

  | e1

  \time 3/4

  | ds2.
}

bassNine = \relative e,, {
  \time 5/4

  | e8 ds4 e4. ds2
}

bassTen = \relative e,, {
  \time 3/4

  | e4. ds4 e8
}

melody = {
  \restsOne
  \melodyOne
  \restsTwo
  \melodyTwo
  \restsThree
  \melodyThree
  \restsFour
  \melodyFour
  \restsFive
  \melodyFive
  \restsSix
  \melodySix
  \restsSeven
  \melodySeven
  \restsEight
  \melodyEight
  \restsNine
  \melodyNine
  \restsTen
  \melodyTen
  \restsEleven
}

bass = {
  \restsOne
  \bassOne
  \restsTwo
  \bassTwo
  \restsThree
  \bassThree
  \restsFour
  \bassFour
  \restsFive
  \bassFive
  \restsSix
  \bassSix
  \restsSeven
  \bassSeven
  \restsEight
  \bassEight
  \restsNine
  \bassNine
  \restsTen
  \bassTen
  \restsEleven
}

\score {
  \new StaffGroup {
    \numericTimeSignature
    <<
      \new Staff = "melody" { \melody }
      \new Staff = "bass" { \bass }
    >>
  }
}
