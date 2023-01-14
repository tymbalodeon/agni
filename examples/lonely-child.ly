\version "2.24.0"

\pointAndClickOff

\header {
  tagline = ##f
}

\paper {
  #(set-paper-size "letter")
  left-margin = 0.75\in
  right-margin = 0.75\in
  top-margin = 0.5\in
  bottom-margin = 0.5\in
  system-system-spacing.minimum-distance = #11
}

\include "lonely-child-notes.ily"
\include "lonely-child-text.ily"

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

intro_spaces = {
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

melody = {
  <<
    \intro_rests
    \intro_spaces
  >>
  \melody
}

bass = {
  \clef "bass_8"
  <<
    \intro_rests
    \intro_spaces
  >>
  \bass
}

\book {
  \bookOutputSuffix "formatted"

  \score {
    \new StaffGroup {
      \numericTimeSignature
      \compressMMRests {
        <<
          \new Staff = "melody" \with {
            instrumentName = "Melody"
            shortInstrumentName = "M."
          } {
            \melody \addlyrics \text
          }
          \new Staff = "bass" \with {
            instrumentName = "Bass"
            shortInstrumentName = "B."
          } {
            \bass
          }
        >>
      }
    }
  }
}
