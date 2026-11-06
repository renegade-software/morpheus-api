# The consent PDF uses Prawn's built-in Helvetica, whose Windows-1252 set covers Spanish (accents, ñ, ¿, ¡);
# without this, every render warns that full UTF-8 needs an external font.
Prawn::Fonts::AFM.hide_m17n_warning = true
