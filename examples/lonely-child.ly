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
}

\include "lonely-child-notes.ily"

\book {
  \bookOutputSuffix "formatted"
  \score {
    \new StaffGroup {
      \numericTimeSignature
      <<
        \new Staff = "melody" \with {
          instrumentName = "Melody"
          shortInstrumentName = "M."
        } {
          \melody
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
