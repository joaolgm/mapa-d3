# export PATH=$PATH:./node_modules/.bin/

#!/bin/bash

# Cria um geojson simplificado e quantizado dos municípios da PB + dados do QEDU

# OBTER E TRANSFORMAR OS DADOS ======================

# Dados de aprendizagem do QEDU
dsv2json \
  -r ',' \
  -n \
  < indiceDesenvolvimento.csv \
  > educacao_indice.ndjson

# JOIN Geometria, Dado ======================
# organiza geometria
ndjson-split 'd.features' \
  < geo1-br_municipios_projetado.json \
  | ndjson-map 'd.cidade = d.properties.GEOCODIGO, d' \
  > br_municipios.ndjson

# organiza variável
ndjson-map 'd.cidade = Number(d.IBGE), d.meta_2015 = Number(d.meta_2015), d.nota_2015 = Number(d.nota_2015), d' \
  < educacao_indice.ndjson \
  > educacao_indice-comchave.ndjson

# o join
# 1. left join (como em SQL)
# 2. o resultado do join é um array com 2 objetos por linha
# 3. o ndjson-map volta a um objeto por linha
EXP_PROPRIEDADE='d[0].properties = Object.assign({}, d[0].properties, d[1]), d[0]'
ndjson-join --left 'd.cidade' \
  br_municipios.ndjson \
  educacao_indice-comchave.ndjson \
  | ndjson-map \
    "$EXP_PROPRIEDADE" \
  > municipios-e-educacao.ndjson

# SIMPLIFICA E QUANTIZA ======================
geo2topo -n \
  tracts=- \
< municipios-e-educacao.ndjson \
| toposimplify -p 1 -f \
| topoquantize 1e5 \
| topo2geo tracts=- \
> municipios-e-educacao-simplificado.json
