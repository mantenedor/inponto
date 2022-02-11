# INponto
Shell script para bater ponto.

O algorítimo estruturado consiste em registrar entradas e saídas de ponto sem a necessidde de banco de dados ou ser executado como serviço. O algorítimo é executado apenas quando invocado, direto no bash.

Os registros são estruturados como objeto em um arquivo JSON.

## Registrando um ponto
Registrar um ponto:
```
./ponto.sh -i
```
Registrar um ponto com data e hora específica:
```
./ponto.sh -i comentário 2022-01-01 00:00:00
```
## Importando registros
Registros podem ser importados utilizando o script [inport.sh](./inport.sh).
Para isso você deve informar um arquivo CSV como parâmetro:
````
./inport.sh ../arquivo.csv
````
