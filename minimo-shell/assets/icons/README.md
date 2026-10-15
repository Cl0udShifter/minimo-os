Ícones de linha próprios do Minimo OS (24px, traço 1.75). Edite em `src/` e regenere
`dark/`, `gray/` e `white/` (apenas altera a cor do traço) com:
  for f in src/*.svg; do n=$(basename $f); cp $f dark/$n; sed 's/#0A0A0B/#6E6E73/' $f > gray/$n; sed 's/#0A0A0B/#AEAEB2/' $f > graydark/$n; sed 's/#0A0A0B/#FFFFFF/' $f > white/$n; done
