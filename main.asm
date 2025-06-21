.data
    input_filename: .asciiz "numbers2.txt"
    output_filename: .asciiz "output.txt"

    buffer: .space 512 # array de bytes; tamanho: 512a
    .align 2
    buffer_pos: .word 0 # tamanho sendo utilizado no buffer
    bytebuf: .space 1 # buffer de 1 byte

    LINEBREAK: .byte 10 # caracter \n
    ZERO_CHAR: .byte '0'
    EOF: .byte -1 # Representa o final de um arquivo
    NULL_CHAR: .byte 0
    .align 2
    SIZE_OF_DOUBLE: .word 8 # Tamanho em bytes de um double
    temp_double_space: .space 8

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
    digit_doubles:     .double 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0

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
        li $a1, 0 # Read-only
        jal openfile
        blt $v0, $zero, _exit
        move $s7, $v0 # $s7 = file descriptor

    _count_file_lines: # conta quantas linhas o arquivo possui, pois qnt de linhas == qnt de numeros
        # $t7 = count_lines($s7)
        move $a0, $s7
        jal count_lines
        move $t7, $v0

        # Coloca o ponteiro do arquivo de volta na posicao inicial
        # Equivalente a fseek($s7, 0, SEEK_SET)
        move $a0, $s7
        jal closefile
        la $a0, input_filename
        li $a1, 0
        jal openfile
        blt $v0, $zero, _exit
        move $s7, $v0
        # qnt de numeros armazenado em $t7

    _alloc_array: #aloca espaço para o array de doubles
       	# Nota de esclarecimento: a memória do heap alocada precisa ser manualmente alinhada para accessar a memória de doubles
        # Será usada a seguinte formula: (endereço + 7) & -8

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
    li $a2, 0
    jal ordena
    move $s4, $v0

    # Fechar o arquivo
    move $a0, $s7
    jal closefile

    # TODO: abrir arquivo de input no modo de append
    _open_file_output: # abre arquivo e guardar seu descriptor
        la $a0, output_filename # la $a0, input_filename
        li $a1, 1 # li $a1, 8
        jal openfile
        blt $v0, $zero, _exit
        move $s7, $v0 # Armazena descriptor em $s7

    _loop_over_array: # Itera sobre o array e escreve no arquivo
        move $s0, $zero
        _OVER_ARRAY_FOR_LOOP:
            bge $s0, $s5, _OVER_ARRAY_END_FOR_LOOP
            # acessa a posição $t0 do array ($s4)
            sll $t1, $s0, 3
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

            addi $s0, $s0, 1
            b _OVER_ARRAY_FOR_LOOP
        _OVER_ARRAY_END_FOR_LOOP:

    # Fechar o arquivos
    move $a0, $s7
    jal closefile
    # Encerra o programa com status code 0
    _exit:
        li $v0, 10
        syscall


    # ---

    # FUNÇÃO ordena
    # Recebe um array de doubles e retorna um novo array ordenado utilize o método de ordenação definido em tipo
    # @param .word ($a0) vetor: Endereço do vetor de floats
    # @param .word ($a1) tam: Tamanho do array
    # @param .word ($a2) tipo: Forma de ordenação à ser usada, 0 para Bubble Sort e 1 para QuickSort
    # @return .word ($v0) Retorna o vetor de doubles ordenado
    ordena:
        # Salva na pilha os registradores que precisam ser preservados entre chamadas de função.
        addi $sp, $sp, -20
        sw $ra, 16($sp) # Salva o endereço de retorno
        sw $s0, 12($sp) # Usaremos para o ponteiro do vetor original
        sw $s1, 8($sp)  # Usaremos para o tamanho (tam)
        sw $s2, 4($sp)  # Usaremos para o tipo de ordenação
        sw $s3, 0($sp)  # Usaremos para o ponteiro do novo vetor

        # Copia os argumentos para registradores salvos, para não os perdermos
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
            l.d $f0, 0($t2) # Carrega o valor da fonte
            s.d $f0, 0($t3) # Armazena o valor no destino

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
        addu $s0, $a0, $zero    # $s0 = vetor
        slt $at, $zero, $s1     # $at = 1 se $s1 > 0
        beq $at, $zero, _BUBBLE_END_FOR_I # if ($s1 <= 0) pula tudo

        # --- Loop externo: for (int i = 0; i < tam - 1; i++) ---
        addu $s2, $zero, $zero  # i = 0

        _BUBBLE_FOR_I:
        addi $t0, $s1, -1                 # t0 = tam - 1
        slt $at, $s2, $t0                 # $at = 1 se i < tam - 1
        beq $at, $zero, _BUBBLE_END_FOR_I # if (i >= tam - 1) break

        # --- Loop interno: for (int j = 0; j < tam - i - 1; j++) ---
        addu $s3, $zero, $zero  # j = 0

        _BUBBLE_FOR_J:
        sub $t0, $s1, $s2       # t0 = tam - i
        addi $t0, $t0, -1       # t0 = tam - i - 1
        slt $at, $s3, $t0       # $at = 1 se j < tam - i - 1
        beq $at, $zero, _BUBBLE_END_FOR_J # if (j >= tam - i - 1) break

        # --- Comparação: if (vetor[j] > vetor[j+1]) ---
        sll $t1, $s3, 3         # t1 = j * 8 (doubles têm 8 bytes)
        add $t1, $s0, $t1       # t1 = &vetor[j]
        add $t2, $t1, 8         # t2 = &vetor[j+1]

        l.d $f2, 0($t1)         # f2 = vetor[j]
        l.d $f4, 0($t2)         # f4 = vetor[j+1]

        c.lt.d $f4, $f2         # CC = 1 se vetor[j] > vetor[j+1]
        bc1f _BUBBLE_NO_SWAP    # branch se CC==0 ⇔ vetor[j] <= vetor[j+1]

        # --- Swap vetor[j] e vetor[j+1] ---
        s.d $f4, 0($t1)         # vetor[j] = vetor[j+1]
        s.d $f2, 0($t2)         # vetor[j+1] = vetor[j]

        _BUBBLE_NO_SWAP:
        addi $s3, $s3, 1        # j++
        beq $zero, $zero, _BUBBLE_FOR_J

        _BUBBLE_END_FOR_J:
        addi $s2, $s2, 1        # i++
        beq $zero, $zero, _BUBBLE_FOR_I

        _BUBBLE_END_FOR_I:
        # --- restaura registradores e retorna ---
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
    # @param .word ($a0) vetor: Vetor de double a ser ordenado
    # @param .word ($a1) low: Ponto mais baixo do vetor
    # @param .word ($a2) high: Ponto mais alto do vetor
    quicksort:
        # Aloca espaço no stack para salvar variáveis essenciais.
        addi $sp, $sp, -28
        sw $ra, 24($sp) # Salva o endereço de retorno
        sw $s0, 20($sp) # Usaremos para o ponteiro do vetor
        sw $s1, 16($sp) # Usaremos para 'low'
        sw $s2, 12($sp) # Usaremos para 'high'
        sw $s3, 8($sp)  # Usaremos para 'i'
        sw $s4, 4($sp)  # Usaremos para 'j'
        # Posição 0($sp) será usada para salvar 'high' para a 2ª chamada

        # Copia os argumentos para registradores salvos para não perdê-los
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

            addi $s3, $s3, 1  # i++
            addi $s4, $s4, -1 # j--

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
            # Restaura os registradores da pilha na ordem inversa
            lw $ra, 24($sp)
            lw $s0, 20($sp)
            lw $s1, 16($sp)
            lw $s2, 12($sp)
            lw $s3, 8($sp)
            lw $s4, 4($sp)
            addi $sp, $sp, 28 # Libera o espaço alocado na pilha

            jr $ra


    # FUNÇÃO openfile
    # Abre o arquivo $a0, no modo $a1 e retorna seu descriptor
    # @param .word ($a0) nome do arquivo a ser aberto
    # @param .word ($a1) modo de abertura (ler: 0/escrever: 1)
    openfile:
        li $v0, 13
        syscall
        jr $ra

    # FUNÇÃO closefile
    # Fecha o arquivo passado como argumento
    # @param .word ($a0) File descriptor do arquivo a ser fechado
    closefile:
        li $v0, 16
        syscall
        jr $ra

    # FUNÇÃO fgetc
    # Implementação própria da fgetc, lê um caracter de um arquivo
    # @param .word ($a0) File descriptor do arquivo a ser lido
    # @return .byte ($v0) Caracter lido, retornar EOF (-1) se nada foi lido
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
        # Registradores:
        # $a0: endereço da string
        # $f0: resultado (result)
        # $f2: valor do dígito convertido para double
        # $f4: 10.0
        # $f6: parte_decimal
        # $f8: sinal (1.0 ou -1.0)
        # $t0: ponteiro para o char atual na string
        # $t1: char atual
        # $t2: temporário para cálculo de endereço
        # $t3: temporário para carregar constantes ou endereço base

        # Inicialização
        l.d $f0, ZERO_DOUBLE            # result = 0.0
        l.d $f8, ONE_DOUBLE             # Usado para o sinal
        addu $t0, $a0, $zero            # $t0 aponta para o início da string

        # Carrega constantes
        l.d $f4, TEN_DOUBLE             # f4 = 10.0

        # Confere sinal
        lb $t1, 0($t0)                  # t1 = string[0]
        lb $t3, MINUS_CHAR
        bne $t1, $t3, _TF_Parte_Inteira_LOOP    # if (char != '-') pula

        # É negativo
        addi $t0, $t0, 1                # i++ (pula o caractere '-')
        l.d  $f8, NEG_ONE_DOUBLE        # $f8 = –1.0

        _TF_Parte_Inteira_LOOP:
            lb $t1, 0($t0)
            beq $t1, $zero, _TF_APPLY_SIGN      # detecta o fim da string ($t1 == 0)
            lb $t3, ZERO_CHAR
            slt $at, $t1, $t3
            bne $at, $zero, _TF_CHECK_DOT       # if (char < '0') sai do loop
            lb $t3, NINE_CHAR
            slt $at, $t3, $t1
            bne $at, $zero, _TF_CHECK_DOT       # if (char > '9') sai do loop

            # result = result * 10.0
            mul.d $f0, $f0, $f4

            # Converte char para int, depois busca o double correspondente na tabela
            lb $t3, ZERO_CHAR     # Carrega o valor do caractere '0' em $t3
            sub $t1, $t1, $t3     # Converte o char do dígito para seu valor inteiro (0-9)
            # Usa o valor do dígito como índice para a tabela 'digit_doubles'
            sll $t2, $t1, 3       # Calcula o deslocamento: índice * 8 (bytes por double)
            la $t3, digit_doubles # Carrega o endereço base da tabela de doubles
            add $t2, $t3, $t2     # Calcula o endereço de digit_doubles[índice]
            l.d $f2, 0($t2)       # Carrega o valor double do dígito para $f2

            # result += (double)digit
            add.d $f0, $f0, $f2   # Adiciona ao resultado

            addi $t0, $t0, 1 # i++
            j _TF_Parte_Inteira_LOOP

        _TF_CHECK_DOT:
            lb $t1, 0($t0)    # Recarrega caractere
            lb $t3, DOT_CHAR  # Pega '.'
            bne $t1, $t3, _TF_APPLY_SIGN # if (char != '.') pula parte decimal

            # Processa parte decimal
            addi $t0, $t0, 1             # i++ (pula o '.')
            l.d $f6, ONE_TENTH_DOUBLE    # parte_decimal = 0.1

        _TF_Parte_Decimal_LOOP:
            lb $t1, 0($t0)
            beq $t1, $zero, _TF_APPLY_SIGN      # detecta o fim da string ($t1 == 0)
            lb $t3, ZERO_CHAR
            slt $at, $t1, $t3
            bne $at, $zero, _TF_APPLY_SIGN      # if (char < '0') sai do loop
            lb $t3, NINE_CHAR
            slt $at, $t3, $t1
            bne $at, $zero, _TF_APPLY_SIGN      # if (char > '9') sai do loop

            # Converte char para int, depois para double
            lb $t3, ZERO_CHAR     # Carrega o valor do caractere '0' em $t3
            sub $t1, $t1, $t3     # Converte o char do dígito para seu valor inteiro (0-9)
            # Agora, usa esse valor inteiro como um índice para buscar o double na tabela
            sll $t2, $t1, 3       # Calcula o deslocamento na tabela (índice * 8 bytes)
            la $t3, digit_doubles # Carrega o endereço base da tabela 'digit_doubles'
            add $t2, $t3, $t2     # Calcula o endereço final do elemento: base + deslocamento
            l.d $f2, 0($t2)       # Carrega o valor double do endereço calculado para $f2

            # result += (double)digit * parte_decimal
            mul.d $f2, $f2, $f6
            add.d $f0, $f0, $f2

            # parte_decimal *= 0.1 (ou parte_decimal /= 10.0)
            div.d $f6, $f6, $f4

            addi $t0, $t0, 1 # i++
            j _TF_Parte_Decimal_LOOP

        _TF_APPLY_SIGN:
            mul.d $f0, $f0, $f8  # result = result * sinal
        jr $ra

    # FUNÇÃO to_string
    # Converte um double para uma string, armazenando na string passada como parametro
    # @param .double ($f12): Double a ser convertido
    # @param .word ($a1): Endereço do buffer a ser preenchido
    # @param .word ($a2): Tamanho do buffer passado
    # @return .word ($v0): O tamanho da string
    to_string:
        addi $sp, $sp, -20
        sw $s0, 16($sp)
        sw $s1, 12($sp)
        sw $s2, 8($sp)
        sw $s3, 4($sp)
        sw $s4, 0($sp)

        #Variáveis iniciais
        move $t0, $zero #posição
        mov.d $f0, $f12 #número double
        l.d $f2, ZERO_DOUBLE #carregando $f2 com o valor 0.0

        c.lt.d $f2, $f0 #Verificando se o número é positivo
        bc1t _numPositivo

        #Se o double for negativo, colocaremos na próxima posição da string passada
        #como argumento o char '-' e, depois, deixaremos positivo o número

        lb $t2, MINUS_CHAR #Carregando registrador com '-'
        add $t8, $a1, $t0  # Calcula o endereço final em $t8 ($a1 + $t0)
    	sb  $t2, 0($t8)      # Salva o byte no endereço calculado (aqui a fonte é $t2)
        addi $t0, $t0, 1 #Incrementando a posição

        neg.d $f0, $f0 #Inverte o sinal do double em $f0

        _numPositivo:

        move $t1, $zero #Posição de float
        l.d $f2, TEN_DOUBLE #Definindo o valor de $f2 como sendo 10

        #Primeiro while, para ir dividindo por 10 (avançar com a vírgula pelo número) e,
        #ao mesmo tempo, computar o número de posições de float
        primeiroWhile:

        	c.lt.d $f0, $f2 #Verificando se o número double é menor do que 10.0
        	bc1t saidaPrimeiroWhile

        	div.d  $f0, $f0, $f2 #Dividindo o valor atual do número por 10
        	addi $t1, $t1, 1 #Incrementando a posição de float

        	j primeiroWhile

        saidaPrimeiroWhile:

        #Obtendo a posição do ponto
        addi $t1, $t1, 1
        add $t1, $t1, $t0 #Agora, $t1 diz respeito à posição do ponto

        #Atribuir o char '.' em sua devida posição
        lb $t2, DOT_CHAR #Atribuindo a $t2 o '.'
        add $t8, $a1, $t1  # Calcula o endereço final em $t8 ($a1 + $t1)
    	sb  $t2, 0($t8)      # Salva o byte no endereço calculado

        #Atribuindo a $t2 o tamanho da string subtraído por 2
        move $t2, $a2
        subi $t2, $t2, 2

        l.d $f2, ZERO_DOUBLE

        segundoWhile:

        	c.eq.d $f0, $f2 #Verificando se o número é igual a zero
        	bc1t saidaSegundoWhile
        	bgt $t0, $t2, saidaSegundoWhile #Verificando se a posição é maior do que $t2

        	#Pegar a parte inteira do número double

        	# Etapa 1: Mover os bits do double ($f0) para registradores de inteiro.
        	#Carregando o double de 64 bits na forma de duas palavras separadas de 32 bits
        	s.d $f0, temp_double_space # Salva o double da FPU para a memória
        	lw $s1, temp_double_space # Carrega a palavra alta (sinal, expoente, mantissa_alta)
        	lw $s2, temp_double_space + 4 # Carrega a palavra baixa (mantissa_baixa)

        	# Etapa 2: Isolando o expoente
        	#O expoente está nos bits 20-30 da $s1
        	srl $t3, $s1, 20
        	andi $t3, $t3, 0x7FF # Isola os 11 bits do expoente
        	addi $s3, $t3, -1023 # Remove o bias para obter o expoente real ($s3)

        	# Etapa 3: Tratar os casos com base no expoente.
    		# A parte inteira ($s4) depende da magnitude do número.

        	bltz $s3, _caso_menor_que_um     # Se expoente < 0, o número é < 1.0.
    		bgt $s3, 20, _caso_grande_demais # Se expoente > 20, a parte inteira pode usar a mantissa baixa.

    		# CASO NORMAL: 0 <= expoente <= 20
    		# A parte inteira está contida apenas na mantissa alta.
    		andi $t4, $s1, 0xFFFFF # Pega os 20 bits da mantissa alta
    		ori $t4, $t4, 0x100000 # Adiciona o '1' implícito (total de 21 bits)
    		li $t5, 20
    		subu $t5, $t5, $s3 # Calcula o quanto precisamos deslocar para a direita
    		srlv $s4, $t4, $t5 # Desloca para obter a parte inteira em $s4
           	j _fim_da_extracao

           	_caso_menor_que_um:
          		# Se o expoente é negativo, a parte inteira é sempre 0.
          		li $s4, 0
          		j _fim_da_extracao

           	_caso_grande_demais:
          		# Se o expoente é > 20, a parte inteira usa bits da mantissa alta E da baixa.
          		# (Limitado a expoentes até 51, pois um maior estouraria um inteiro de 32 bits)
          		andi $t4, $s1, 0xFFFFF # Mantissa alta (20 bits)
          		ori $t4, $t4, 0x100000 # Adiciona o '1' implícito (21 bits)

          		# Vamos mover os bits da mantissa alta para a esquerda e abrir espaço
          		# para os bits da mantissa baixa.
          		subu $t5, $s3, 20 # Quanto precisamos da mantissa baixa = exp - 20
          		sllv $t6, $t4, $t5 # Desloca a mantissa alta para a esquerda

          		# Agora, pegamos os bits que precisamos da mantissa baixa
          		li $t7, 32
          		subu $t5, $t7, $t5 #Calcula o deslocamento para a direita da mantissa baixa
          		srlv $t7, $s2, $t5

          		or $s4, $t6, $t7 # Combina as duas partes para formar o inteiro final em $s4

    		_fim_da_extracao:
               	bne $t1, $t0, diferentePosDot #Verificando se a posição ($t0) é diferente da posição do ponto ($t1)

          		#Se for igual, vamos incrementar a posição
          		addi $t0, $t0, 1

               	diferentePosDot: #Se for diferente, pulamos para cá

               	#Vamos atribuir na posição correta a parte inteira incrementada com o char '0'
               	lb $t6, ZERO_CHAR
               	add $t6, $s4, $t6 #Valor a ser atribuído

               	#Salva o byte e DEPOIS incrementa a posição
               	add $t8, $a1, $t0  # Calcula o endereço final em $t8 ($a1 + $t0)
                sb  $t6, 0($t8)    # Salva o byte no endereço calculado
               	addi $t0, $t0, 1 #Incrementando

           	#Salvar o estado atual dos registradores que serão usados para converter de int para double
           	subu $sp, $sp, 32

    		sw $t0, 0($sp)
    		sw $t1, 4($sp)
    		sw $t2, 8($sp)
    		sw $t3, 12($sp)
    		sw $t4, 16($sp)
    		sw $s4, 20($sp)
    		sw $s5, 24($sp)
    		sw $s6, 28($sp)

    		lw $s4, 20($sp) # Recarrega o valor original de $s4 para ser convertido.

           	#Converter a parte inteira ($s4) para double para a subtração

           	#Lidar com o caso especial do inteiro ser 0.
           	beq $s4, $zero, _conv_int_zero

           	#Tratar o sinal.
           	li $s5, 0 # $s5 guardará a palavra alta do double.
           	bltz $s4, _conv_int_negativo
           	# Se for positivo, o bit de sinal já é 0.
           	j _conv_int_find_msb

           	_conv_int_negativo:
          		li $s5, 0x80000000 # Coloca '1' no bit de sinal da palavra alta.
          		negu $s4, $s4 #Nega o inteiro para trabalhar com o valor absoluto.
           	_conv_int_find_msb:
          		#Encontrar a posição do bit mais significativo (MSB).
          		# Isso nos dará o expoente real.
          		li $t0, 31 # Começa a procurar do bit 31.
          		li $t1, 1
           	_conv_int_msb_loop:
          		sllv $t2, $t1, $t0 # Cria uma máscara para o bit na posição $t0.
          		and $t3, $s4, $t2
          		bne $t3, $zero, _conv_int_msb_found # Se o resultado não for zero, achamos o MSB.
          		subi $t0, $t0, 1
          		bnez $t0, _conv_int_msb_loop
          		# Se $t0 chegar a zero e não achou, algo está errado (só para int=0, já tratado).
          		j _conv_int_msb_found

    		_conv_int_msb_found:
    			# $t0 agora contém a posição do MSB (0-31), que é o expoente real.
    			#Calcular o expoente a ser armazenado (com bias).
    			addi $t1, $t0, 1023 # Expoente + bias.
    			sll $t1, $t1, 20 # Desloca o expoente para sua posição na palavra alta.
    			or $s5, $s5, $t1 # Combina com o bit de sinal.

    			#Calcular a mantissa.
    			#Remove o MSB do nosso inteiro para ficar apenas com os bits da mantissa.
    			li $t1, 1
    			sllv $t2, $t1, $t0
    			subu $t3, $s4, $t2 # $t3 agora tem os bits da mantissa.

    			# Agora, precisamos alinhar esses bits no campo de 52 bits da mantissa.
    			# A mantissa ocupa os 20 bits inferiores da palavra alta e toda a palavra baixa.
    			li $t1, 20
    			subu $t2, $t0, $t1 # $t2 = quanto precisamos deslocar (pode ser negativo).

    			li $s6, 0 # $s6 guardará a palavra baixa do double.
    			bgtz $t2, _conv_mantissa_shift_right #Se $t0 > 20, shift right.


    			#Se $t0 <= 20, shift left.
    			negu $t2, $t2 #Inverte para $t2 ser a quantidade de shift left.
    			sllv $t4, $t3, $t2
    			or $s5, $s5, $t4 # Adiciona a mantissa à palavra alta.
    			j _conv_int_assemble

    		_conv_mantissa_shift_right:
    			# A mantissa é grande demais para caber só nos 20 bits da palavra alta.
    			srlv $t4, $t3, $t2
    			or $s5, $s5, $t4 # Parte da mantissa vai para a palavra alta.

    			sllv $t4, $t3, $t2 # Pega os bits restantes
    			srlv $t4, $t4, $t2
    			sllv $s6, $t4, $t2
    			sll $s6, $s6, 12 # Alinha na palavra baixa.

    		_conv_int_assemble:
    			#Juntar as partes e carregar no registrador de float.

    			sw $s6, temp_double_space + 4 #Salva a palavra baixa.
    			l.d $f2, temp_double_space #Carrega o double montado para $f2.
    			j _conv_int_fim

    		_conv_int_zero:
    			# Se o inteiro for 0, o double é 0.0.
    			l.d $f2, ZERO_DOUBLE # Supondo que ZERO_DOUBLE (0.0) já foi definido.

    		_conv_int_fim:

    		#Restaurar os registradores para seus valores originais de antes do bloco.
    		lw $t0, 0($sp)
    		lw $t1, 4($sp)
    		lw $t2, 8($sp)
    		lw $t3, 12($sp)
    		lw $t4, 16($sp)
    		lw $s4, 20($sp)
    		lw $s5, 24($sp)
    		lw $s6, 28($sp)
    		addu $sp, $sp, 32 # Libera o espaço da pilha.

           	#Atualizando o número para a próxima iteração
           	sub.d $f0, $f0, $f2 #Decrementando o número double pela parte inteira
           	l.d $f2, TEN_DOUBLE
           	mul.d $f0, $f0, $f2

           	j segundoWhile

        saidaSegundoWhile:

        	lb $t6, NULL_CHAR
        	add $t8, $a1, $t0
        	sb $t6, 0($t8)

        lw $s4, 0($sp)
        lw $s3, 4($sp)
        lw $s2, 8($sp)
        lw $s1, 12($sp)
        lw $s0, 16($sp)
        addi $sp, $sp, 20

       	move $v0, $t0
        jr $ra
