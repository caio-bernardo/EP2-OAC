#include <stdio.h>
#include <stdlib.h>

double *ordena(double *vetor, int tam, int tipo);
double to_float(const char *string);
void to_string(double, char *const, int);
int count_lines(FILE *f);

int main(void) {
    // abra o arquivo numbers.txt
    FILE * numbers = fopen("numbers.txt", "r");
    FILE * output = fopen("output.txt", "w+");

    // Descobre quantos elementos o arquivo possui
    int capacity = count_lines(numbers);
    // Aloca o tamanho necessário de elementos
    double *array = malloc(sizeof(float) * capacity);
    int len = 0;

    char buffer[512];
    int idx = 0;

    for (char c = fgetc(numbers); c != EOF; c = fgetc(numbers)) {
        if (c == '\n') {
            buffer[idx] = '\0';
            idx = 0;

            array[len++] = to_float(buffer);
        } else {
            buffer[idx++] = c;
        }
    }

    double * array_ord = ordena(array, len, 0);

    for (int i = 0; i < len; i++) {
        to_string(array_ord[i], buffer, 512);
        fputs(buffer, output);
        fputc('\n', output);
    }

    free(array);
    free(array_ord);
    fclose(numbers);
    fclose(output);
}

// Algoritmo de ordenação Bubble Sort
void bubblesort(float *vetor, int tam) {
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
void quicksort(float *vetor, int low, int high) {
    if (low < high) {
        // Pivot (elemento central)
        float pivot = vetor[(low + high) / 2];

        // Partition
        int i = low, j = high;
        while (i <= j) {
            while (vetor[i] < pivot) i++;
            while (vetor[j] > pivot) j--;

            if (i <= j) {
                // Swap
                float temp = vetor[i];
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

// Converte um double para uma string modificando a string passada como parametro
void to_string(double num, char *const string, int string_size) {
    int pos = 0;

    // Caso num é negativo
    if (num < 0.0) {
        string[pos++] = '-';
        num = -num;
    }

    long long parte_inteira = (long long)num;
    double parte_fracionada = num - parte_inteira;

    // Converter parte inteira para string
    if (parte_inteira == 0) {
        // Caso especial: número zero
        string[pos++] = '0';
    } else {
        // Contar quantos dígitos tem na parte inteira
        int count = 0;
        long long temp = parte_inteira;
        while (temp > 0) {
            temp /= 10;
            count++;
        }

        // Converter dígito a dígito, começando do dígito mais significativo
        temp = parte_inteira;
        int digit_pos = pos + count - 1;
        while (temp > 0) {
            string[digit_pos--] = '0' + (temp % 10);
            temp /= 10;
        }
        pos += count;
    }

    // Adicionar a parte fracionada
    if (parte_fracionada > 0.0) {
        string[pos++] = '.';
        int count_precision = 0;
        while (parte_fracionada > 0 && count_precision < 6) { // limitar para 6 casas decimais
            parte_fracionada *= 10;
            int digit = (int)parte_fracionada;
            string[pos++] = '0' + digit;
            parte_fracionada -= digit;
            count_precision++;
        }
    }

    // Finalizar a string
    string[pos] = '\0';

}
