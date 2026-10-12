Iconos de línea propios de Minimo OS (24px, trazo 1.75). Editar en `src/` y regenerar
`dark/`, `gray/` y `white/` (solo cambia el color del trazo) con:
  for f in src/*.svg; do n=$(basename $f); cp $f dark/$n; sed 's/#0A0A0B/#6E6E73/' $f > gray/$n; sed 's/#0A0A0B/#AEAEB2/' $f > graydark/$n; sed 's/#0A0A0B/#FFFFFF/' $f > white/$n; done
