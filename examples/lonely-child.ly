\version "2.24.1"

\include "lonely-child-notes.ily"
\include "lonely-child-text.ily"

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

            \bar "|."
          }
          \new Staff = "bass" \with {
            instrumentName = "Bass"
            shortInstrumentName = "B."
          } {
            \clef "bass_8"

            \bass

            \bar "|."
          }
        >>
      }
    }
  }
}
