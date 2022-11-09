\version "2.23.80"
\language "english"
\pointAndClickOff

\paper {
  #(set-paper-size "letter")
  left-margin = 0.75\in
  right-margin = 0.75\in
  top-margin = 0.5\in
  bottom-margin = 0.5\in
}

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
  \time 5/8
  s2 s8
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
  e8 ds2.
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
