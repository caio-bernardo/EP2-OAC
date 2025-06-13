.data
    input_filename: .asciiz "numbers.txt"
    output_filename: .asciiz "output.txt"

    # array de bytes; tamanho: 512
    buffer: .space 512
    # buffer de 1 byte
    bytebuf: .space 1

    LINEBREAK: .byte 10
    ZERO_CHAR: .byte '0'

.text
    .globl main

    main:
        # abre arquivo e guardar seu descriptor
        la $a0, input_filename
        li $v0, 13
        syscall
        blt $v0, $zero, exit_failed
        move $s7, $v0

        # TODO: alocar espaço para o array de doubles
        # TODO: alocar espaco para o buffer de linhas

        # TODO: iterar sobre os caracteres até EOF (-1)

        # char c = fgetc(input_file)
        move $a0, $s7
        jal fgetc
        move $t0, $v0
        # enquanto c != EOF lê o próximo char
        MAIN_WHILE_LOOP:
            blt $t0, $zero, END_MAIN_WHILE_LOOP

            move $a0, $t0
            li $v0, 1
            syscall

            # c = fgetc(input_file)
            move $a0, $s7
            jal fgetc
            move $t0, $v0

            b MAIN_WHILE_LOOP
        END_MAIN_WHILE_LOOP:

    # TODO: checar se caracter é \n ou não; se for \n fecha o buffer, converte para float, guarda no array, e reseta a contagem; senão armazena no buffer
    # TODO: ordernar o array
    # TODO: escrever no arquivo


    # TODO: limpar memória alocada (se houver)

    # Fechar os arquivos
    close_file:
        move $a0, $s7
        li $v0, 16
        syscall

    # Encerra o programa com status code 0
    exit:
        li $v0, 10
        syscall

    exit_failed:
        # Encerra com um erro
        move $a0, $v0
        li $v0, 1
        syscall
        li $v0, 10
        syscall


    # FUNÇÃO ordena
    # Recebe um array de floats e retorna um novo array ordenado utilize o método de ordenação definido em tipo
    # @param .word ($a0) tam: Tamanho do array
    # @param .word ($a1) tipo: Forma de ordenação à ser usada, 0 para Bubble Sort e 1 para QuickSort
    # @param .word ($a2) vetor: Endereço do vetor de floats
    # @return .word ($v0) Retorna o vetor de floats ordenado
    ordena:
        # TODO: alocar novo array e copiar os valores de vetor para esse novo array
        ORDENA_IF_TIPO:
            beq $a1, $zero, ORDENA_ELSE_TIPO
            # TODO: chamar Quick Sort
            b ORDENA_END_IF
        ORDENA_ELSE_TIPO:
            # TODO: chamar Bubble Sort
        ORDENA_END_IF:
        # TODO: retornar o array em $v0
        jr $ra

    # FUNÇÃO bubblesort
    # Realiza uma ordenação bubble sort
    # @param .word ($a0) vetor: Vetor a ser ordenado
    # @param .word ($a1) tam: Tamanho do vetor
    bubblesort:
        # TODO: implementar essa função
        jr $ra

    # FUNÇÃO quicksort
    # Realiza uma ordenação quick sort
    # @param .word ($a0) vetor: Vetor a ser ordenado
    # @param .word ($a1) low: Ponto mais baixo do vetor
    # @param .word ($a2) high: Ponto mais alto do vetor
    quicksort:
        # TODO: implementar essa função
        jr $ra


    # FUNÇÃO fgetc
    # Implementação própria da fgetc, lê um caracter de um arquivo
    # @param .word ($a0) File descriptor do arquivo a ser lido
    # @return .byte ($v0) Caracter lido
    fgetc:
        # Lê um caracter do arquivo
        # $a0 ja esta setado
        la $a1, bytebuf
        li $a2, 1
        li $v0, 14
        syscall

        # Retorna o caracter lido
        lb $v0, bytebuf
        jr $ra

    # FUNÇÃO count_lines
    # Conta a quantidade de linhas que o arquivo possui
    # @param .word Endereço do file descriptor
    # @return .word numero de linhas do arquivo
    count_lines:
        #TODO: implemnetar

        jr $ra

    # FUNÇÃO to_float
    # @param .word string ($a0) : Endereço para a string
    # @return .double ($v0): Valor em Double resultante
    to_float:
        # TODO: implementar

        jr $ra

    # FUNÇÃO to_string
    # @param .double number : Double a ser convertido
    # @param .word string : Endereço do buffer a ser preenchido
    # @para .word string_size : Tamanho do buffer passado
    to_string:
        #TODO: implementar

        jr $ra
