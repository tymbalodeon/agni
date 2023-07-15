from typer import Typer

jeu_de_timbres = Typer(
    no_args_is_help=True,
    help="Jeu de timbres",
    context_settings={"help_option_names": ["-h", "--help"]},
    add_completion=False,
)
