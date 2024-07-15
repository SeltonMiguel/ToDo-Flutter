#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Cria um console para o processo e redireciona stdout e stderr para
// para o executor e para a biblioteca Flutter.
void CreateAndAttachConsole();

// Pega um wchar_t* terminado em nulo codificado em UTF-16 e retorna um std::string
// codificado em UTF-8. Retorna um std::string vazio em caso de falha.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Obtém os argumentos da linha de comando passados ​​como std::vector<std::string>,
// codificado em UTF-8. Retorna um std::vector<std::string> vazio em caso de falha.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_
