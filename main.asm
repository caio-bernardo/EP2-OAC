.data
    input_filename: .asciiz "numbers.txt"
    output_filename: .asciiz "output.txt"

    buffer: .space 512 # array de bytes; tamanho: 512
    buffer_pos: .word 0 # tamanho sendo utilizado no buffer
    bytebuf: .space 1 # buffer de 1 byte

    LINEBREAK: .byte 10 # caracter \n
    ZERO_CHAR: .byte '0'
    EOF: .byte -1 # Representa o final de um arquivo
    NULL_CHAR: .byte 0
    SIZE_OF_DOUBLE: .word 8 # Tamanho em bytes de um double

    # Para função to_float 
    TEN_DOUBLE:        .double 10.0
    ONE_TENTH_DOUBLE:  .double 0.1
    DOT_CHAR:          .byte '.'
    NINE_CHAR:         .byte '9'
    MINUS_CHAR:        .byte '-'

.text
    .globl main

    main:

    _open_file: # abre arquivo e guardar seu descriptor
        la $a0, input_filename
        li $a1, 0 # Read-only
        li $v0, 13
        syscall
        move $s7, $v0 # $s7 = file descriptor

    _alloc_array: #aloca espaço para o array de doubles
        # conta a quantidade de linhas do arquivo
        move $a0, $s7
        jal count_lines
        move $t7, $v0 # $t7 = nr de linhas no arquivo

        # calcula o tamanho do array
        lw $t1, SIZE_OF_DOUBLE
        mul $t0, $t7, $t1 # $t0 = nr de linhas * SIZE_OF_DOUBLE

        # alloca um array no heap de tamanho $t0 e armazena em $s6
        move $a0, $t0
        li $v0, 9
        syscall
        move $s6, $v0
        li $s5, 0 # Tamanho atual do array. $s5 = 0
        # NOTA: No MARS não é preciso desalocar a memória alocada no heap

    _loop_over_file: # loop sobre os bytes do arquivo
        # char c = fgetc(input_file)
        move $a0, $s7
        jal fgetc
        move $s0, $v0 # $s0 = fgetc(file_descriptor)
        # enquanto c != EOF lê o próximo char
        _MAIN_WHILE_LOOP:
            lb $t1, EOF
            beq $s0, $t1, _END_MAIN_WHILE_LOOP

            # Corpo do loop #
            _MAIN_CHECK_BYTE_IF:
                # Se c != '\n'
                lb $t1, LINEBREAK
                beq $s0, $t1, _MAIN_CHECK_BYTE_ELSE

                # buffer[buffer_pos] = c
                la $t0, buffer
                lw $t1, buffer_pos
                add $t0, $t0, $t1
                sb $s0, ($t0) # *$t0 = $s0
                addi $t1, $t1, 1 # buffer_pos++
                sw $t1, buffer_pos # *buffer_pos = $t1

                b _MAIN_CHECK_BYTE_END_IF
            _MAIN_CHECK_BYTE_ELSE:
                # Se c == '\n'
                # buffer[buffer_pos] = '\0'
                la $t0, buffer
                lw $t1, buffer_pos
                add $t0, $t0, $t1
                lb $t2, NULL_CHAR
                sb $t2, ($t0) # $t0 = '\0'
                # buffer_pos = 0
                move $t1, $zero
                sw $t1, buffer_pos

                # array[len] = to_float(buffer)
                # Calcula index to array
                lb $t0, SIZE_OF_DOUBLE
                mul $t0, $s5, $t0
                add $t0, $s6, $t0

                # chama to_float(buffer)
                la $a0, buffer
                jal to_float # $f0 = to_float(buffer)
                # coloca o resultado em array[len]
                s.d $f0, ($t0)

                #len++
                add $s5, $s5, 1

            _MAIN_CHECK_BYTE_END_IF:
            # Fim do corpo do Loop #

            # c = fgetc(input_file)
            move $a0, $s7
            jal fgetc
            move $s0, $v0

            b _MAIN_WHILE_LOOP
        _END_MAIN_WHILE_LOOP:

    # $s4 = ordena($s6, $s5, BubbleSort)
    move $a0, $s6
    move $a1, $s5
    li $a2, 0
    jal ordena
    move $s4, $v0

    # Fechar o arquivos
    _close_file:
        move $a0, $s7
        li $v0, 16
        syscall

    # TODO: abrir arquivo de input no modo de append
    _open_file_output: # abre arquivo e guardar seu descriptor
        la $a0, output_filename
        li $a1, 9 # Write-only
        li $v0, 13
        syscall
        move $s7, $v0 # Armazena descriptor em $s7

    _loop_over_array: # Itera sobre o array e escreve no arquivo
        move $t0, $zero
        _OVER_ARRAY_FOR_LOOP:
            bge $t0, $s5, _OVER_ARRAY_END_FOR_LOOP
            # acessa a posição $t0 do array ($s4)
            lb $t2, SIZE_OF_DOUBLE
            mul $t1, $t0, $t2
            add $t1, $t1, $s4
            # $v0 = to_string($s4[$t1], buffer, 512)
            l.d $f12, ($t1)
            la $a1, buffer
            li $a2, 512
            jal to_string

            # fwrite(buffer, $f0, $s7)
            move $a0, $s7
            la $a1, buffer
            move $a2, $v0
            li $v0, 15
            syscall
            # fwrite("\n", 1, $s7)
            move $a0, $s7
            la $a1, LINEBREAK
            li $a2, 1
            li $v0, 15
            syscall

            addi $t0, $t0, 1
            b _OVER_ARRAY_FOR_LOOP
        _OVER_ARRAY_END_FOR_LOOP:

    # Fechar o arquivos
    _close_file_output:
        move $a0, $s7
        li $v0, 16
        syscall
    # Encerra o programa com status code 0
    _exit:
        li $v0, 10
        syscall


    # ---

    # FUNÇÃO ordena
    # Recebe um array de doubles e retorna um novo array ordenado utilize o método de ordenação definido em tipo
    # @param .word ($a0) tam: Tamanho do array
    # @param .word ($a1) tipo: Forma de ordenação à ser usada, 0 para Bubble Sort e 1 para QuickSort
    # @param .word ($a2) vetor: Endereço do vetor de floats
    # @return .word ($v0) Retorna o vetor de doubles ordenado
    ordena:
        # TODO: alocar novo array e copiar os valores de vetor para esse novo array
        _ORDENA_IF_TIPO:
            beq $a1, $zero, _ORDENA_ELSE_TIPO
            # TODO: chamar Quick Sort
            b _ORDENA_END_IF
        _ORDENA_ELSE_TIPO:
            # TODO: chamar Bubble Sort
        _ORDENA_END_IF:
        # TODO: retornar o array em $v0
        jr $ra

    # FUNÇÃO bubblesort
    # Realiza uma ordenação bubble sort
    # @param .word ($a0) vetor: Vetor de double a ser ordenado
    # @param .word ($a1) tam: Tamanho do vetor
    bubblesort:
    # --- salva registradores que serão usados ---
    addi $sp, $sp, -20
    sw $ra, 0($sp)    # Salva endereço de retorno
    sw $s0, 4($sp)    # Salva $s0 (usado para vetor)
    sw $s1, 8($sp)    # Salva $s1 (usado para tamanho)
    sw $s2, 12($sp)   # Salva $s2 (contador i)
    sw $s3, 16($sp)   # Salva $s3 (contador j)

    # Inicializa registradores com argumentos
    move $s0, $a0     # $s0 = vetor
    move $s1, $a1     # $s1 = tamanho
    blez $s1, BUBBLE_END_FOR_I   # ignora vetor vazio ou de 1 elemento

    # --- Loop externo: for (int i = 0; i < tam - 1; i++) ---
    li $s2, 0         # i = 0

    BUBBLE_FOR_I:
    addi $t0, $s1, -1     # t0 = tam - 1
    bge $s2, $t0, BUBBLE_END_FOR_I  # if (i >= tam - 1) break

    # --- Loop interno: for (int j = 0; j < tam - i - 1; j++) ---
    li $s3, 0         # j = 0

    BUBBLE_FOR_J:
    sub $t0, $s1, $s2     # t0 = tam - i
    addi $t0, $t0, -1     # t0 = tam - i - 1
    bge $s3, $t0, BUBBLE_END_FOR_J  # if (j >= tam - i - 1) break

    # --- Comparação: if (vetor[j] > vetor[j+1]) ---
    sll $t1, $s3, 3       # t1 = j * 8 (doubles têm 8 bytes)
    add $t1, $s0, $t1     # t1 = &vetor[j]

    add $t2, $t1, 8       # t2 = &vetor[j+1]

    l.d $f2, 0($t1)       # f2 = vetor[j]
    l.d $f4, 0($t2)       # f4 = vetor[j+1]

    c.le.d $f2, $f4       # if (f2 <= f4) pular swap
    bc1t BUBBLE_NO_SWAP

    # --- Swap vetor[j] e vetor[j+1] ---
    s.d $f4, 0($t1)       # vetor[j] = vetor[j+1]
    s.d $f2, 0($t2)       # vetor[j+1] = vetor[j]

    BUBBLE_NO_SWAP:
    addi $s3, $s3, 1      # j++
    b BUBBLE_FOR_J

    BUBBLE_END_FOR_J:
    addi $s2, $s2, 1      # i++
    b BUBBLE_FOR_I

    BUBBLE_END_FOR_I:
    # --- restaura registradores e retorna ---
    move $v0, $s0 # retorna o ponteiro do vetor em $v0
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

    # FUNÇÃO quicksort
    # Realiza uma ordenação quick sort
    # @param .word ($a0) vetor: Vetor de double a ser ordenado
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

        _FGETC_IF:
            beq $v0, $zero, _FGETC_ELSE
            # se $v0 for 1 então leu caracter e retorna o byte lido
            lb $v0, bytebuf
            b _FGETC_END_IF
        _FGETC_ELSE:
            # se $v0 for 0 então chegou no fim do arquivo e retorna EOF
            lb $v0, EOF
        _FGETC_END_IF:
        jr $ra

    # FUNÇÃO count_lines
    # Conta a quantidade de linhas que o arquivo possui
    # @param .word ($a0) Endereço do file descriptor
    # @return .word ($v0) numero de linhas do arquivo
    count_lines:
        #TODO: implemnetar
        li $v0, 1001
        jr $ra

    # FUNÇÃO to_float
    # @param .word string ($a0) : Endereço para a string
    # @return .double ($f0): Valor em Double resultante
    to_float:
        # Registradores:
        # $a0: endereço da string
        # $f0: resultado (result)
        # $f2: valor do dígito convertido para double
        # $f4: 10.0
        # $f6: parte_decimal
        # $t0: ponteiro para o char atual na string
        # $t1: char atual
        # $t2: sinal (1.0 ou -1.0)
        
        # Inicialização
        l.d $f0, 0.0 # result = 0.0
        l.d $f8, 1.0 # Usado para o sinal
        move $t0, $a0 # $t0 aponta para o início da string

        # Carrega constantes
        l.d $f4, TEN_DOUBLE # f4 = 10.0
        
        # Confere sinal
        lb $t1, 0($t0) # t1 = string[0]
        lb $t3, MINUS_CHAR
        bne $t1, $t3, TF_Parte_Inteira_LOOP # if (char != '-') pula
        
        # É negativo
        li $t8, -1        # Se for '-', define o sinal como -1
        mtc1 $t8, $f8
        cvt.d.w $f8, $f8  # $f8 = -1.0 (covertido para double)
        addi $t0, $t0, 1  # i++

    TF_Parte_Inteira_LOOP:
        lb $t1, 0($t0)
        beqz $t1, TF_APPLY_SIGN    # detecta o fim da string ($t1 == 0)
        lb $t3, ZERO_CHAR
        blt $t1, $t3, TF_CHECK_DOT # if (char < '0') sai do loop
        lb $t3, NINE_CHAR
        bgt $t1, $t3, TF_CHECK_DOT # if (char > '9') sai do loop

        # result = result * 10.0
        mul.d $f0, $f0, $f4
        
        # Converte char para int, depois para double
        sub $t1, $t1, ZERO_CHAR
        mtc1 $t1, $f2
        cvt.d.w $f2, $f2    # converteu para double
        
        # result += (double)digit
        add.d $f0, $f0, $f2  # Adiciona ao resultado
        
        addi $t0, $t0, 1 # i++
        b TF_Parte_Inteira_LOOP

    TF_CHECK_DOT:
        lb $t1, 0($t0)    # Recarrega caractere
        lb $t3, DOT_CHAR  # Pega '.'
        bne $t1, $t3, TF_APPLY_SIGN # if (char != '.') pula parte decimal

        # Processa parte decimal
        addi $t0, $t0, 1 # i++ (pula o '.')
        l.d $f6, ONE_TENTH_DOUBLE # parte_decimal = 0.1

    TF_Parte_Decimal_LOOP:
        lb $t1, 0($t0)
        beqz $t1, TF_APPLY_SIGN     # detecta o fim da string ($t1 == 0)
        lb $t3, ZERO_CHAR
        blt $t1, $t3, TF_APPLY_SIGN # if (char < '0') sai do loop
        lb $t3, NINE_CHAR
        bgt $t1, $t3, TF_APPLY_SIGN # if (char > '9') sai do loop
        
        # Converte char para int, depois para double
        sub $t1, $t1, ZERO_CHAR
        mtc1 $t1, $f2
        cvt.d.w $f2, $f2

        # result += (double)digit * parte_decimal
        mul.d $f2, $f2, $f6
        add.d $f0, $f0, $f2

        # parte_decimal *= 0.1 (ou parte_decimal /= 10.0)
        div.d $f6, $f6, $f4

        addi $t0, $t0, 1 # i++
        b TF_Parte_Decimal_LOOP

    TF_APPLY_SIGN:
        mul.d $f0, $f0, $f8 # result = result * sinal
        jr $ra

    # FUNÇÃO to_string
    # Converte um double para uma string, armazenando na string passada como parametro
    # @param .double ($f12): Double a ser convertido
    # @param .word ($a1): Endereço do buffer a ser preenchido
    # @param .word ($a2): Tamanho do buffer passado
    # @return .word ($v0): O tamanho da string
    to_string:
        #TODO: implementar
        move $v0, $zero
        jr $ra
