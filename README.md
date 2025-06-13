# Sorting com MIPS
Exercício de Programação de Organização e Arquiterura de Computadores

## Objetivo

Ler um arquivo de números de ponto flutante, ordená-los e escrever de volta no arquivo. Apresentar um código em C e outro em Assembly MIPS.

## Tarefas

- [x] Implementar funções em C
  - [x] ler arquivo
  - [x] métodos de ordenação
  - [x] string para double
  - [x] função double para string

- [ ] Implementar funções Assembly
  - [x] função _main_
  - [ ] função _ordena_
  - [ ] função _bubblesort_
  - [ ] função _quicksort_
  - [ ] função _to_string_
  - [ ] função _to_double_
  - [ ] função _count_lines_
  - [x] função _fgetc_

## Como rodar

- Código em C: Utilize o comando `make` para compilar e rodar o código em C. Verifique se o _Makefile_ está correto em caso de falha.
- Código em Assembly: Utilize o simulador _MARS_ ou o _SPIM_ para rodar o código.

## Estrutura do Projeto

- `main.c`: código do projeto em C
- `main.asm`: código do projeto em Assembly MIPS
- `script.py`: script Python para gerar arquivo de teste com números aleatórios
- `numbers.txt`: arquivo de teste
