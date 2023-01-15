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

rests_three = {
  \time 1/4
  R4
}

rests_four = {
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

rests_five = {
  \time 3/4
  R2.
}

rests_six = {
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

rests_seven = {
  \time 3/8
  R8 * 3
}

rests_eight = {
  \time 1/8
  R8
  \time 8/4
  R \breve
  \time 5/4
  R4 * 5
  \time 3/4
  R2.
}

rests_nine = {
  \time 3/4
  R2. * 2
}

rests_ten = {
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
  \rests_one
  <<
    \melody_one
    \structure_one
  >>
  \rests_two
  <<
    \melody_two
    \structure_two
  >>
  \rests_three
  <<
    \melody_three
    \structure_three
  >>
  \rests_four
  <<
    \melody_four
    \structure_four
  >>
  \rests_five
  <<
    \melody_five
    \structure_five
  >>
  \rests_six
  <<
    \melody_six
    \structure_six
  >>
  \rests_seven
  <<
    \melody_seven
    \structure_seven
  >>
  \rests_eight
  <<
    \melody_eight
    \structure_eight
  >>
  \rests_nine
  <<
    \melody_nine
    \structure_nine
  >>
  \rests_ten
  <<
    \melody_ten
    \structure_ten
  >>
  \rests_eleven

  \bar "|."
}

bass = {
  \clef "bass_8"
  \rests_one
  <<
    \bass_one
    \structure_one
  >>
  \rests_two
  <<
    \bass_two
    \structure_two
  >>
  \rests_three
  <<
    \bass_three
    \structure_three
  >>
  \rests_four
  <<
    \bass_four
    \structure_four
  >>
  \rests_five
  <<
    \bass_five
    \structure_five
  >>
  \rests_six
  <<
    \bass_six
    \structure_six
  >>
  \rests_seven
  <<
    \bass_seven
    \structure_seven
  >>
  \rests_eight
  <<
    \bass_eight
    \structure_eight
  >>
  \rests_nine
  <<
    \bass_nine
    \structure_nine
  >>
  \rests_ten
  <<
    \bass_ten
    \structure_ten
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
