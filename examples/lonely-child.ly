\version "2.23.80"
\language "english"

\header {
  title = "Lonely Child"
  composer = "Claude Vivier"
  tagline = ##f
}

structure = {
  \time 5/4
  \repeat unfold 2 {
    s1 s4 |
  }
  \time 4/4
  s1 * 2 |
  \time 5/4
  s1 s4 |
}

melody = \relative c'' {
  a1~ a4 |
  bf8 a bf1 |
  \tuplet 3/2 { a8 a4 }
  \tuplet 3/2 { bf8 bf4 }
  a8 bf4.~ |
  bf2.
  \tuplet 3/2 { a8 a a }
  bf1~ bf4 |
}

bass = \relative c, {
  \clef "bass_8"
  g1~ g4~ |
  g~ g1 |
  g2 g~ |
  g1 |
  fs~ fs4 |
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
