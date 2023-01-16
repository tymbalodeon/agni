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
\include "lonely-child-text.ily"

restsOne = {
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

restsTwo = {
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

restsThree = {
  \time 1/4
  R4
}

restsFour = {
 \time 5/8
 R8 * 5
 \time 5/16
 R16 * 5
 \time 5/8
 R8 * 5
 \time 9/16
 R16 * 9
 \time 2/4
 R2
 \time 7/16
 R16 * 7
 \time 3/8
 R8 * 3
 \time 5/16
 R16 * 5
 \time 2/8
 R8 * 2
 \time 3/8
 R8 * 3
 \time 2/4
 R2
}

restsFive = {
  \time 3/4
  R2.
}

restsSix = {
  \time 10/4
  R4 * 10
  \time 9/4
  R4 * 9
  \time 8/4
  R4 * 8
  \time 7/4
  R4 * 7
  \time 6/4
  R4 * 6
  \time 5/4
  R4 * 5
  \time 10/4
  R4 * 10
  \time 5/4
  R4 * 10
}

restsSeven = {
  \time 3/8
  R8 * 3
}

restsEight = {
  \time 1/8
  R8
  \time 8/4
  R \breve
  \time 5/4
  R4 * 5
  \time 3/4
  R2.
}

restsNine = {
  \time 3/4
  R2. * 2
}

restsTen = {
  \time 4/4
  R1
}

rests_eleven = {
  \time 3/4
  R2. * 8
  \time 5/4
  R4 * 5
  \time 3/4
  R2.
  \time 4/4
  R1 * 3
  \time 2/4
  R2
  \time 4/4
  R1 * 2
  \time 6/4
  R4 * 6
  \time 4/4
  R1 * 2
  \time 3/4
  R2.
  \time 5/4
  R4 * 10
  \time 3/4
  R2.
}

melody = {
  \restsOne
  <<
    \melodyOne
    \structureOne
  >>
  \restsTwo
  <<
    \melodyTwo
    \structureTwo
  >>
  \restsThree
  <<
    \melodyThree
    \structureThree
  >>
  \restsFour
  <<
    \melodyFour
    \structureFour
  >>
  \restsFive
  <<
    \melodyFive
    \structureFive
  >>
  \restsSix
  <<
    \melodySix
    \structureSix
  >>
  \restsSeven
  <<
    \melodySeven
    \structureSeven
  >>
  \restsEight
  <<
    \melodyEight
    \structureEight
  >>
  \restsNine
  <<
    \melodyNine
    \structureNine
  >>
  \restsTen
  <<
    \melodyTen
    \structureTen
  >>
  \rests_eleven

  \bar "|."
}

bass = {
  \clef "bass_8"
  \restsOne
  <<
    \bassOne
    \structureOne
  >>
  \restsTwo
  <<
    \bassTwo
    \structureTwo
  >>
  \restsThree
  <<
    \bassThree
    \structureThree
  >>
  \restsFour
  <<
    \bassFour
    \structureFour
  >>
  \restsFive
  <<
    \bassFive
    \structureFive
  >>
  \restsSix
  <<
    \bassSix
    \structureSix
  >>
  \restsSeven
  <<
    \bassSeven
    \structureSeven
  >>
  \restsEight
  <<
    \bassEight
    \structureEight
  >>
  \restsNine
  <<
    \bassNine
    \structureNine
  >>
  \restsTen
  <<
    \bassTen
    \structureTen
  >>
  \rests_eleven

  \bar "|."
}

\book {
  \bookOutputSuffix "formatted"

  \score {
    \new StaffGroup {
      \numericTimeSignature
      \compressMMRests {
        <<
          \new Staff = "melody" \with {
            instrumentName = "Soprano"
            shortInstrumentName = "S."
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
