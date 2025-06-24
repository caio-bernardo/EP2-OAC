#include <stdio.h>
#include <stdlib.h>

double *ordena(double *vetor, int tam, int tipo);
double to_float(const char *string);
int to_string(double, char *const, int);
int count_lines(FILE *f);

const char* file = "numbers2.txt";

int main(void) {
    // abra o arquivo numbers.txt
    FILE * numbers = fopen(file, "r");

    // Descobre quantos elementos o arquivo possui
    int capacity = count_lines(numbers) + 1;
    // Aloca o tamanho necessário de elementos
    double *array = malloc(sizeof(double) * capacity);
    int len = 0;

    char buffer[512];
    int buffer_pos = 0;

    for (char c = fgetc(numbers); c != EOF; c = fgetc(numbers)) {
        if (c == '\n') {
            // Reseta o buffer ao chegar no fim da linha
            buffer[buffer_pos] = '\0';
            buffer_pos = 0;

            // adiciona o conteudo do buffer no array
            array[len++] = to_float(buffer);
        } else {
            // Adiciona o caracter lido no buffer
            buffer[buffer_pos++] = c;
        }
    }

    // Ordena o array
    double * array_ord = ordena(array, len, 0);

    // Escreve o resultado
    // TODO: substituir pelo arquivo de input no modo de append
    // FILE * output = fopen("output.txt", "w");
    FILE * output = fopen(file, "a");
    for (int i = 0; i < len; i++) {
        // Converte para string
        to_string(array_ord[i], buffer, 512);
        // Escreve no arquivo
        fputs(buffer, output);
        fputc('\n', output);
    }

    // Libera memória e fecha os arquivos
    free(array);
    free(array_ord);
    fclose(numbers);
    fclose(output);
}

// Algoritmo de ordenação Bubble Sort
void bubblesort(double *vetor, int tam) {
    // BubbleSort
    for (int i = 0; i < tam - 1; i++) {
        for (int j = 0; j < tam - i - 1; j++) {
            if (vetor[j] > vetor[j + 1]) {
                double temp = vetor[j];
                vetor[j] = vetor[j + 1];
                vetor[j + 1] = temp;
            }
        }
    }
}

// Algoritmo de ordenação Quick Sort
void quicksort(double *vetor, int low, int high) {
    if (low < high) {
        // Pivot (elemento central)
        double pivot = vetor[(low + high) / 2];

        // Partition
        int i = low, j = high;
        while (i <= j) {
            while (vetor[i] < pivot) i++;
            while (vetor[j] > pivot) j--;

            if (i <= j) {
                // Swap
                double temp = vetor[i];
                vetor[i] = vetor[j];
                vetor[j] = temp;
                i++;
                j--;
            }
        }

        // Resolve recursivamente
        if (low < j) quicksort(vetor, low, j);
        if (i < high) quicksort(vetor, i, high);
    }
}

// Ordena um vetor de doubles usando o Bubble Sort (tipo = 0) ou QuickSort (tipo = 1)
double *ordena(double *vetor, int tam, int tipo) {
    double *novo_vetor = malloc(sizeof(double) * tam);
    for (int i = 0; i < tam; i++) {
        novo_vetor[i] = vetor[i];
    }
    if (tipo) {
        quicksort(novo_vetor, 0, tam - 1);
    } else {
        bubblesort(novo_vetor, tam);
    }
    return novo_vetor;
}

// Conta as linhas de um arquivo
int count_lines(FILE *file) {
    int result = 0;
    // Começa do começo do arquivo
    fseek(file, 0, SEEK_SET);

    char ch;
    while ((ch = fgetc(file)) != EOF) {
        if (ch == '\n') {
            result++;
        }
    }

    // Volta para o começo do arquivo
    fseek(file, 0, SEEK_SET);
    return result;
}

// Converte uma string para um double
double to_float(const char *string) {
    double result = 0.0;
    int i = 0;
    int sign = 1;

    // Confere se o numero é negativo
    if (string[i] == '-') {
        sign = -1;
        i++;
    }

    // Processa a parte inteira
    while (string[i] >= '0' && string[i] <= '9') {
        result = result * 10.0 + (string[i] - '0');
        i++;
    }

    // Processa a parte decimal
    if (string[i] == '.') {
        i++;
        double decimal_part = 0.1;
        while (string[i] >= '0' && string[i] <= '9') {
            result += (string[i] - '0') * decimal_part;
            decimal_part *= 0.1;
            i++;
        }
    }

    return sign * result;
}

// Converte um double para uma string modificando a string passada como parametro.
// Retorna o novo tamanho da string
int to_string(double number, char *const string, int string_size) {
    double num = number;
    int pos = 0;
    // Caso num é negativo
    if (num < 0.0) {
        string[pos++] = '-';
        num = -num;
    }

    int float_position = 0;
    while (num > 10) {
        num /= 10.0;
        float_position++;
    }
    int dot_position = float_position + pos + 1;
    string[dot_position] = '.';

    while (num != 0.0 && pos < string_size - 2) {
        int parte_inteira = (int)num;

        if (pos == dot_position) {
            pos++;
        }

        int parte_inteira = (int)num;
        string[pos++] = parte_inteira + '0';
        num -= (double)parte_inteira;
        num *= 10.0;
    }

    // Finalizar a string
    string[pos] = '\0';
    return pos;
}
