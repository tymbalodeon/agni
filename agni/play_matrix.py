from time import sleep

from supriya.patterns import EventPattern, SequencePattern

from .matrix import Matrix
from .notate_matrix import sort_frequencies


def play_matrix(matrix: Matrix):
    frequencies = sort_frequencies(matrix)
    pattern = EventPattern(frequency=SequencePattern(frequencies), delta=0.05)
    pattern.play()
    sleep(5)
