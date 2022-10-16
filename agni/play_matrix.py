from agni.combination_tone_matrix import Matrix
from agni.notate_matrix import sort_frequencies
from supriya.patterns import EventPattern
from time import sleep

from supriya.patterns.patterns import SequencePattern


def play_matrix(matrix: Matrix):
    frequencies = sort_frequencies(matrix)
    pattern = EventPattern(frequency=SequencePattern(frequencies), delta=0.05)
    pattern.play()
    sleep(5)
