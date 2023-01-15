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

rests_one = {
  \time 13/4
  R1 * 13/4
  \time 3/4
  R2. * 3
  \time 4/4
  R1
  \time 3/4
  R2.
  \time 4/4
  R1
  \time 3/4
  R2.
  \time 2/4
  R2
  \time 4/4
  R1 * 2
  \time 3/4
  R2. * 3
  \time 4/4
  R1 * 2
  \time 6/4
  R1.
  \time 1/8
  R8
  \time 4/4
  R1
  \time 5/4
  R1 * 5/4
  \time 2/4
  R2
  \time 5/4
  R1 * 5/4
  \time 8/4
  R \breve
}

rests_two = {
  \time 5/8
  R1 * 10/8
  \time 3/4
  R2.
  \time 5/8
  R1 * 5/8
  \time 4/4
  R1
  \time 3/8
  R8 * 3
  \time 2/4
  R2
  \time 5/8
  R1 * 5/8
  \time 2/4
  R2
  \time 3/4
  R2.
  \time 5/8
  R1 * 5/8
  \time 2/4
  R2
}

melody = {
  \rests_one
  <<
    \melody_one
    \structure_one
  >>
  \rests_two
}

bass = {
  \clef "bass_8"
  \rests_one
  <<
    \bass_one
    \structure_one
  >>
  \rests_two
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
