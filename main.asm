.data
    .align 3
    # Para função to_float
    ZERO_DOUBLE:       .double 0.0
    ONE_DOUBLE:        .double 1.0
    TEN_DOUBLE:        .double 10.0
    ONE_TENTH_DOUBLE:  .double 0.1
    DOT_CHAR:          .byte '.'
    NINE_CHAR:         .byte '9'
    MINUS_CHAR:        .byte '-'
    .align 3
    NEG_ONE_DOUBLE:    .double -1.0
    .align 3
    digit_doubles:     .double 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0
    .align 3
    temp_double_space: .space 8

    .align 2
    buffer_pos: .word 0 # tamanho sendo utilizado no buffer

    .align 2
    SIZE_OF_DOUBLE: .word 8

    input_filename: .asciiz "dadosEP2.txt"

    # buffer para armazenar uma linha
    buffer: .space 512

    bytebuf: .space 1 # buffer de 1 byte

    LINEBREAK: .byte 10 # caracter \n
    ZERO_CHAR: .byte '0'
    EOF: .byte -1 # Representa o final de um arquivo
    NULL_CHAR: .byte 0

    .align 2
    BUBBLE_SORT:       .word 0
    QUICK_SORT:        .word 1

.text
    .globl main

    main:
    # $s7: FILE * para input_file
    # $s6: Array de doubles no heap
    # $s5: Tamanho utilizado do array
    # $s4: Novo array de doubles ordenado
    _open_file: # abre arquivo e guardar seu descriptor
        la $a0, input_filename
        li $a1, 0
        jal openfile
        blt $v0, $zero, _exit
        move $s7, $v0 # $s7 = file descriptor

    _count_file_lines: # conta quantas linhas o arquivo possui, pois qnt de linhas == qnt de numeros
        move $a0, $s7
        jal count_lines
        move $t7, $v0

        # Coloca o ponteiro do arquivo de volta na posicao inicial
        move $a0, $s7
        jal closefile
        la $a0, input_filename
        li $a1, 0
        jal openfile
        blt $v0, $zero, _exit
        move $s7, $v0

    _alloc_array: #aloca espaço para o array de doubles

        # calcula o tamanho do array
        lw $t1, SIZE_OF_DOUBLE
        mul $t0, $t7, $t1 # $t0 = nr de linhas * SIZE_OF_DOUBLE

        # alloca um array no heap de tamanho $t0 e armazena em $s6
        move $a0, $t0
        li $v0, 9
        syscall
        move $s6, $v0
        li $s5, 0 # Tamanho atual do array. $s5 = 0

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
                sll $t0, $s5, 3 # offset = index * 8 bytes
                add $s0, $s6, $t0 # endereço + offset

                # chama to_float(buffer)
                la $a0, buffer
                jal to_float # $f0 = to_float(buffer)
                # coloca o resultado em array[len]
                s.d $f0, ($s0)

                #len++
                addi $s5, $s5, 1

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
    # lw $a2, QUICK_SORT
    lw $a2, BUBBLE_SORT
    jal ordena
    move $s4, $v0

    # Fechar o arquivo
    move $a0, $s7
    jal closefile

    _open_file_output:
        la $a0, input_filename
        li $a1, 9 # append + escrita no final do arquivo
        jal openfile
        blt $v0, $zero, _exit
        move $s7, $v0

    _loop_over_array: # Itera sobre o array e escreve no arquivo
        move $s0, $zero
        _OVER_ARRAY_FOR_LOOP:
            bge $s0, $s5, _OVER_ARRAY_END_FOR_LOOP
            sll $t1, $s0, 3
            add $t1, $t1, $s4
            l.d $f12, ($t1)

            la $a1, buffer
            li $a2, 10
            jal to_string
            move $t0, $v0

            # fwrite("\n", 1, $s7)
            move $a0, $s7
            la $a1, LINEBREAK
            li $a2, 1
            li $v0, 15
            syscall

            # fwrite(buffer, $f0, $s7)
            move $a0, $s7
            la $a1, buffer
            move $a2, $t0
            li $v0, 15
            syscall

            addi $s0, $s0, 1
            b _OVER_ARRAY_FOR_LOOP
        _OVER_ARRAY_END_FOR_LOOP:

    move $a0, $s7
    jal closefile
    _exit:
        li $v0, 10
        syscall

    # FUNÇÃO ordena
    # Recebe um array de doubles e retorna um novo array ordenado utilize o método de ordenação definido em tipo
    # $a0: Endereço do vetor de floats
    # $a1: Tamanho do array
    # $a2: Forma de ordenação à ser usada, 0 para Bubble Sort e 1 para QuickSort
    # $v0: Retorna o vetor de doubles ordenado
    ordena:
        addi $sp, $sp, -20
        sw $ra, 16($sp)
        sw $s0, 12($sp)
        sw $s1, 8($sp)
        sw $s2, 4($sp)
        sw $s3, 0($sp)

        move $s0, $a0 # $s0 = vetor (original)
        move $s1, $a1 # $s1 = tam
        move $s2, $a2 # $s2 = tipo

        # Alocando o novo array
        lw $t0, SIZE_OF_DOUBLE
        mul $a0, $s1, $t0 # $a0 = tam * 8 (argumento para a syscall de alocação)
        li $v0, 9 # syscall 9: sbrk (malloc)
        syscall
        move $s3, $v0 # $s3 guarda o ponteiro para o novo_vetor

        # Copiando os valores do vetor original para o novo
        li $t0, 0 # i = 0 (contador de loop)
        _copy_loop:
            beq $t0, $s1, _end_copy_loop # se i == tam, encerra o loop
            # Calcula o offset (deslocamento) no array: i * 8
            sll $t1, $t0, 3
            # Calcula endereço da fonte: &vetor_original[i]
            add $t2, $s0, $t1
            # Calcula endereço do destino: &novo_vetor[i]
            add $t3, $s3, $t1

            # Copia o double
            l.d $f0, 0($t2)
            s.d $f0, 0($t3)

            addi $t0, $t0, 1 # i++
            j _copy_loop
        _end_copy_loop:

        # Se tipo == 0, chama o bubblesort
        beq $s2, $zero, _ordena_bubblesort

        # TODO: alocar novo array e copiar os valores de vetor para esse novo array
        _ordena_quicksort:
            move $a0, $s3     # 1º arg: novo vetor
            li $a1, 0         # 2º arg: low = 0
            addi $a2, $s1, -1 # 3º arg: high = tam - 1
            jal quicksort
            j _ordena_end_if # Pula para o final da seleção
        _ordena_bubblesort:
            move $a0, $s3 # 1º arg: novo vetor
            move $a1, $s1 # 2º arg: tam
            jal bubblesort
        _ordena_end_if:
        # O ponteiro para o novo array ordenado está em $s3
        move $v0, $s3
        # Restaura os registradores da pilha
        lw $ra, 16($sp)
        lw $s0, 12($sp)
        lw $s1, 8($sp)
        lw $s2, 4($sp)
        lw $s3, 0($sp)
        addi $sp, $sp, 20
        # Retorna
        jr $ra

    # FUNÇÃO bubblesort
    # Realiza uma ordenação bubble sort
    # $a0: Vetor de double a ser ordenado
    # $a1: Tamanho do vetor
    bubblesort:
        # Salvando os registradores que serão usados
        addi $sp, $sp, -20
        sw $ra, 0($sp)    # Salva endereço de retorno
        sw $s0, 4($sp)    # Salva $s0 (usado para vetor)
        sw $s1, 8($sp)    # Salva $s1 (usado para tamanho)
        sw $s2, 12($sp)   # Salva $s2 (contador i)
        sw $s3, 16($sp)   # Salva $s3 (contador j)

        # Inicializa registradores com argumentos
        addu $s0, $a0, $zero    # $s0 = vetor
        addu $s1, $a1, $zero     # $s1 = tamanho
        slt $t4, $zero, $s1     # $t4 = 1 se $s1 > 0
        beq $t4, $zero, _Bubble_END_FOR_I # if ($s1 <= 0) pula tudo

        # Loop externo: for (int i = 0; i < tam - 1; i++)
        addu $s2, $zero, $zero  # i = 0

        _Bubble_FOR_I:
        addi $t0, $s1, -1                  # t0 = tam - 1
        slt $t4, $s2, $t0                 # $t4 = 1 se i < tam - 1
        beq $t4, $zero, _Bubble_END_FOR_I # if (i >= tam - 1) break

        # Loop interno: for (int j = 0; j < tam - i - 1; j++)
        addu $s3, $zero, $zero  # j = 0

        _Bubble_FOR_J:
        sub $t0, $s1, $s2        # t0 = tam - i
        addi $t0, $t0, -1        # t0 = tam - i - 1
        slt $t4, $s3, $t0         # $t4 = 1 se j < tam - i - 1
        beq $t4, $zero, _Bubble_END_FOR_J # if (j >= tam - i - 1) break

        # Comparação: if (vetor[j] > vetor[j+1])
        sll $t1, $s3, 3            # t1 = j * 8 (doubles têm 8 bytes)
        add $t1, $s0, $t1          # t1 = &vetor[j]
        add $t2, $t1, 8           # t2 = &vetor[j+1]

        l.d $f2, 0($t1)          # f2 = vetor[j]
        l.d $f4, 0($t2)          # f4 = vetor[j+1]

        c.lt.d $f4, $f2          # CC = 1 se vetor[j] > vetor[j+1]
        bc1f _Bubble_NO_SWAP    # Pula se CC==0 -> vetor[j] <= vetor[j+1]

        # Swap vetor[j] e vetor[j+1]
        s.d $f4, 0($t1)          # vetor[j] = vetor[j+1]
        s.d $f2, 0($t2)          # vetor[j+1] = vetor[j]

        _Bubble_NO_SWAP:
        addi $s3, $s3, 1        # j++
        beq $zero, $zero, _Bubble_FOR_J

        _Bubble_END_FOR_J:
        addi $s2, $s2, 1        # i++
        beq $zero, $zero, _Bubble_FOR_I

        _Bubble_END_FOR_I:
        # Restaurando registradores e retorna
        addu $v0, $s0, $zero
        lw $ra, 0($sp)
        lw $s0, 4($sp)
        lw $s1, 8($sp)
        lw $s2, 12($sp)
        lw $s3, 16($sp)
        addi $sp, $sp, 20
        jr $ra

    # FUNÇÃO quicksort
    # Realiza uma ordenação quick sort
    # $a0: Vetor de double a ser ordenado
    # $a1: Ponto mais baixo do vetor
    # $a2: Ponto mais alto do vetor
    quicksort:
        addi $sp, $sp, -28
        sw $ra, 24($sp)
        sw $s0, 20($sp) # Usaremos para o ponteiro do vetor
        sw $s1, 16($sp) # Usaremos para 'low'
        sw $s2, 12($sp) # Usaremos para 'high'
        sw $s3, 8($sp)  # Usaremos para 'i'
        sw $s4, 4($sp)  # Usaremos para 'j'
        # Posição 0($sp) será usada para salvar 'high' para a 2ª chamada

        move $s0, $a0 # $s0 = vetor
        move $s1, $a1 # $s1 = low
        move $s2, $a2 # $s2 = high

        # Condição base da recursão: if (low < high)
        slt $t0, $s1, $s2 # $t0 = 1 se low < high, senão 0
        beq $t0, $zero, _quicksort_epilogo # Se low >= high, a partição está ordenada. Pula para o fim.

        # Escolhendo o pivô: double pivot = vetor[(low + high) / 2];
        add $t0, $s1, $s2 # $t0 = low + high
        sra $t0, $t0, 1   # $t0 /= 2
        sll $t1, $t0, 3   # Calcula o offset: índice * 8 (bytes por double)
        add $t1, $s0, $t1 # $t1 = endereço de vetor[índice_pivo]
        l.d $f4, 0($t1)   # $f4 (pivô) = vetor[índice_pivo]

        # Inicializando i e j: int i = low, j = high;
        move $s3, $s1 # i = low
        move $s4, $s2 # j = high

        _partition_loop:
            # Loop principal de particionamento: while (i <= j)
            slt $t0, $s4, $s3 # $t0 = 1 se j < i
            bne $t0, $zero, _end_partition_loop # Se j < i, sai do loop de particionamento

            # Loop interno para 'i': while (vetor[i] < pivot) i++;
            _inner_loop_i:
                sll $t0, $s3, 3       # offset de i = i * 8
                add $t0, $s0, $t0     # endereço de vetor[i]
                l.d $f6, 0($t0)       # $f6 = vetor[i]
                c.lt.d $f6, $f4       # vetor[i] < pivot
                bc1f _end_inner_loop_i # Se não for menor (ou seja, >=), sai do loop
                addi $s3, $s3, 1      # i++
                j _inner_loop_i
            _end_inner_loop_i:

            # Loop interno para 'j': while (vetor[j] > pivot) j--;
            _inner_loop_j:
                sll $t0, $s4, 3       # offset de j = j * 8
                add $t0, $s0, $t0     # endereço de vetor[j]
                l.d $f6, 0($t0)       # $f6 = vetor[j]
                c.le.d $f6, $f4       # Compara: vetor[j] <= pivot
                bc1t _end_inner_loop_j # Se for verdadeiro (<=), sai do loop
                addi $s4, $s4, -1     # j--
                j _inner_loop_j
            _end_inner_loop_j:

            # Condição para troca: if (i <= j)
            slt $t0, $s4, $s3 # $t0 = 1 se j < i
            bne $t0, $zero, _post_swap # Se j < i, não faz a troca

            # Swap
            sll $t0, $s3, 3   # t0 = &vetor[i] (offset)
            add $t0, $s0, $t0
            sll $t1, $s4, 3   # t1 = &vetor[j] (offset)
            add $t1, $s0, $t1

            l.d $f6, 0($t0) # f6 = vetor[i]
            l.d $f8, 0($t1) # f8 = vetor[j]

            s.d $f8, 0($t0) # vetor[i] = vetor[j]
            s.d $f6, 0($t1) # vetor[j] = vetor[i]

            addi $s3, $s3, 1
            addi $s4, $s4, -1

        _post_swap:
            j _partition_loop
        _end_partition_loop:
            # Primeira chamada recursiva: quicksort(vetor, low, j)
            # if (low < j)
            slt $t0, $s1, $s4 # $t0 = 1 se low < j
            beq $t0, $zero, _call_second # Se não, pula para a segunda chamada

            # Salva os argumentos da segunda chamada (i, high) na pilha
            sw $s3, 8($sp) # Reutilizando o espaço de $s3 para salvar 'i'
            sw $s2, 0($sp) # Salva 'high' original

            move $a0, $s0 # 1º arg: vetor
            move $a1, $s1 # 2º arg: low
            move $a2, $s4 # 3º arg: j
            jal quicksort

        _call_second:
            # Segunda chamada recursiva: quicksort(vetor, i, high)
            # Restaura os argumentos salvos
            lw $s3, 8($sp) # Recupera 'i'
            lw $s2, 0($sp) # Recupera 'high' original

            # if (i < high)
            slt $t0, $s3, $s2 # $t0 = 1 se i < high
            beq $t0, $zero, _quicksort_epilogo # Se não, pula para o fim

            move $a0, $s0 # 1º arg: vetor
            move $a1, $s3 # 2º arg: i
            move $a2, $s2 # 3º arg: high
            jal quicksort

        _quicksort_epilogo:
            lw $ra, 24($sp)
            lw $s0, 20($sp)
            lw $s1, 16($sp)
            lw $s2, 12($sp)
            lw $s3, 8($sp)
            lw $s4, 4($sp)
            addi $sp, $sp, 28

            jr $ra


    # FUNÇÃO openfile
    # Abre o arquivo $a0, no modo $a1 e retorna seu descriptor
    # $a0: nome do arquivo a ser aberto
    # $a1: modo de abertura
    openfile:
        li $v0, 13
        syscall
        jr $ra

    # FUNÇÃO closefile
    # Fecha o arquivo passado como argumento
    # $a0: File descriptor do arquivo a ser fechado
    closefile:
        li $v0, 16
        syscall
        jr $ra

    # FUNÇÃO fgetc
    # Implementação própria da fgetc, lê um caracter de um arquivo
    # $a0: File descriptor do arquivo a ser lido
    # $v0: Caracter lido, retornar EOF (-1) se nada foi lido
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
        # Inicializando o contador em $t5
        li $t5, 0 # int result = 0
        la $a1, buffer # Aponta para um local temporário para guardar o byte lido
        li $a2, 1 # Argumento de syscall para ler 1 byte de cada vez

        _count_loop:
            # O descritor do arquivo já está em $a0 (passado como argumento)
            li $v0, 14 # syscall: read from file
            syscall    # Após a syscall, $v0 contém o número de bytes lidos
            # Verificando se a leitura falhou ou chegou ao fim do arquivo
            blez $v0, _end_count_loop

            lb $t6, ($a1) # Carrega o byte que foi lido do buffer para um registrador
            lb $t4, LINEBREAK
            bne $t6, $t4, _count_loop # Se não for uma nova linha, volta ao início
            addi $t5, $t5, 1 # Se for uma nova linha, incrementa o contador

            j _count_loop

        _end_count_loop:
            move $v0, $t5 # Bota o resultado no registrador de retorno
            jr $ra

    # FUNÇÃO to_float
    # @param .word string ($a0) : Endereço para a string
    # @return .double ($f0): Valor em Double resultante
    to_float:
    # $t4: temporário para resultado de comparações (slt)
        # Inicialização
        l.d $f0, ZERO_DOUBLE          # result = 0.0
        l.d $f8, ONE_DOUBLE            # Usado para o sinal
        addu $t0, $a0, $zero          # $t0 aponta para o início da string

        # Carrega constantes
        l.d $f4, TEN_DOUBLE             # f4 = 10.0

        # Confere sinal
        lb $t1, 0($t0)                   # t1 = string[0]
        lb $t3, MINUS_CHAR
        bne $t1, $t3, _TF_Parte_Inteira_LOOP    # if (char != '-') pula

        # É negativo
        addi $t0, $t0, 1                 # i++ (pula o caractere '-')
        l.d  $f8, NEG_ONE_DOUBLE        # $f8 = –1.0

        _TF_Parte_Inteira_LOOP:
            lb $t1, 0($t0)
            beq $t1, $zero, _TF_Aplica_Sinal   # detecta o fim da string ($t1 == 0)
            lb $t3, ZERO_CHAR
            slt $t4, $t1, $t3
            bne $t4, $zero, _TF_Checar_Ponto       # Se (char < '0') sai do loop
            lb $t3, NINE_CHAR
            slt $t4, $t3, $t1
            bne $t4, $zero, _TF_Checar_Ponto      # if (char > '9') sai do loop

            # result = result * 10.0
            mul.d $f0, $f0, $f4

            # Converte char para int, depois busca o double correspondente na tabela
            lb $t3, ZERO_CHAR     # '0' em $t3
            sub $t1, $t1, $t3     # Converte o char do dígito para seu valor inteiro (0-9)

            # Usa o valor do dígito como índice para a tabela 'digit_doubles'
            sll $t2, $t1, 3        # Calcula o deslocamento: índice * 8 (bytes por double)
            la $t3, digit_doubles   # Carrega o endereço base da tabela de doubles
            add $t2, $t3, $t2       # Calcula o endereço de digit_doubles[índice]
            l.d $f2, 0($t2)       # Coloca o valor double do dígito para $f2

            # result += (double)digit
            add.d $f0, $f0, $f2    # Adiciona ao resultado

            addi $t0, $t0, 1 # i++
            j _TF_Parte_Inteira_LOOP

        _TF_Checar_Ponto:
            lb $t1, 0($t0)               # Recarrega caractere
            lb $t3, DOT_CHAR               # Pega '.'
            bne $t1, $t3, _TF_Aplica_Sinal # if (char != '.') pula parte decimal

            # Processa parte decimal
            addi $t0, $t0, 1
            l.d $f6, ONE_TENTH_DOUBLE

        _TF_Parte_Decimal_LOOP:
            lb $t1, 0($t0)
            beq $t1, $zero, _TF_Aplica_Sinal    # detecta o fim da string ($t1 == 0)
            lb $t3, ZERO_CHAR
            slt $t4, $t1, $t3
            bne $t4, $zero, _TF_Aplica_Sinal      # if (char < '0') sai do loop
            lb $t3, NINE_CHAR
            slt $t4, $t3, $t1
            bne $t4, $zero, _TF_Aplica_Sinal     # Se (char > '9') sai do loop

            # Converte char para int, depois para double
            lb $t3, ZERO_CHAR
            sub $t1, $t1, $t3

            # Agora, usa esse valor inteiro como um índice para buscar o double na tabela
            sll $t2, $t1, 3
            la $t3, digit_doubles
            add $t2, $t3, $t2
            l.d $f2, 0($t2)

            mul.d $f2, $f2, $f6
            add.d $f0, $f0, $f2

            div.d $f6, $f6, $f4

            addi $t0, $t0, 1
            j _TF_Parte_Decimal_LOOP

        _TF_Aplica_Sinal:
            mul.d $f0, $f0, $f8
        jr $ra

    # FUNÇÃO to_string
    # Converte um double para uma string, armazenando na string passada como parametro
    # $f12: Double a ser convertido
    # $a1: Endereço do buffer a ser preenchido
    # $a2: Tamanho do buffer passado
    # $v0: O tamanho da string
    to_string:
    	addi $sp, $sp, -24
    	sw $s5, 20($sp)
        sw $s0, 16($sp)
        sw $s1, 12($sp)
        sw $s2, 8($sp)
        sw $s3, 4($sp)
        sw $s4, 0($sp)

        move $t0, $zero
        mov.d $f0, $f12
        l.d $f2, ZERO_DOUBLE

        c.lt.d $f2, $f0
        bc1t _numPositivo

        #Se o double for negativo, colocaremos na próxima posição da string passada
        #como argumento o char '-' e, depois, deixaremos positivo o número
        lb $t2, MINUS_CHAR
        add $t8, $a1, $t0
    	sb  $t2, 0($t8)
        addi $t0, $t0, 1

        neg.d $f0, $f0

        _numPositivo:

        move $t1, $zero
        l.d $f2, TEN_DOUBLE

        #Primeiro while, para ir dividindo por 10 (avançar com a vírgula pelo número) e,
        #ao mesmo tempo, computar o número de posições de float
        primeiroWhile:

        	c.lt.d $f0, $f2
        	bc1t saidaPrimeiroWhile

        	div.d  $f0, $f0, $f2
        	addi $t1, $t1, 1

        	j primeiroWhile

        saidaPrimeiroWhile:


        addi $t1, $t1, 1
        add $t1, $t1, $t0

        #Atribuir o char '.' em sua devida posição
        lb $t2, DOT_CHAR
        add $t8, $a1, $t1
    	sb  $t2, 0($t8)

        #Atribuindo a $t2 o tamanho da string subtraído por 2 que representa os caracteres de sinal e de ponto flutuante
        move $t2, $a2
        subi $t2, $t2, 2

        l.d $f2, ZERO_DOUBLE

        segundoWhile:
    		c.eq.d $f0, $f2
    		bc1t saidaSegundoWhile
    		bgt $t0, $t2, saidaSegundoWhile

    		l.d $f4, ONE_DOUBLE
    		l.d $f6, ONE_DOUBLE
    		move $s4, $zero

    		loopConverteDoubleInt:
    			c.le.d $f0, $f4
    			bc1t fimConversaoDoubleInt

    			add.d $f4, $f4, $f6
    			addi $s4, $s4, 1

    			j loopConverteDoubleInt
    		fimConversaoDoubleInt:

    		# Pula o ponto se a posição atual for a do ponto
    		bne $t1, $t0, diferentePosDot
    		addi $t0, $t0, 1

    		diferentePosDot:
    		# Converte o dígito para char e armazena
    		lb $t8, ZERO_CHAR
    		add $t8, $s4, $t8
    		add $t9, $t0, $a1
    		sb $t8, 0($t9)
    		addi $t0, $t0, 1

    		move $t6, $zero
    		l.d $f4, ZERO_DOUBLE
    		l.d $f6, ONE_DOUBLE

    		loopConverteIntDouble:
    			beq $t6, $s4, fimConversaoIntDouble

    			addi $t6, $t6, 1
    			add.d $f4, $f4, $f6

    			j loopConverteIntDouble
    		fimConversaoIntDouble:

    		sub.d $f0, $f0, $f4
    		l.d $f4, TEN_DOUBLE
    		mul.d $f0, $f0, $f4

    		j segundoWhile
        saidaSegundoWhile:

		#Atribuição de '\0' na última posição, para finalizar a string
		lb $t6, NULL_CHAR
       	add $t8, $a1, $t0
       	sb $t6, 0($t8)

       	move $v0, $t0

        lw $s4, 0($sp)
        lw $s3, 4($sp)
        lw $s2, 8($sp)
        lw $s1, 12($sp)
        lw $s0, 16($sp)
        lw $s5, 20($sp)
        addi $sp, $sp, 24

        jr $ra
