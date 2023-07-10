from rich import print
from typer import Exit, Option, Typer

from agni import __version__

from .couleurs.main import couleurs
from .helpers import stylize
from .jeu_de_timbres.main import jeu_de_timbres

app_name = stylize("Agni", color="bright_green")
agni = Typer(
    help=(
        f"{app_name}: Use compositional techniques inspired by Claude Vivier."
    ),
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)

agni.add_typer(couleurs, name="couleurs")
agni.add_typer(jeu_de_timbres, name="jeu-de-timbres")


def display_version(version: bool):
    if version:
        print(f"agni {__version__}")
        raise Exit()


@agni.callback()
def callback(
    _: bool = Option(
        False,
        "--version",
        "-V",
        callback=display_version,
        help="Display version number.",
    ),
):
    return
