from agni.combination_tone_matrix import display_matrix, get_matrix
from typer import Typer

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)


@agni.command()
def test():
    matrix = get_matrix("a1", "b2")
    display_matrix(matrix)
