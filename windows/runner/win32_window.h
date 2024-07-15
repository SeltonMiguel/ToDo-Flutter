#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// Uma abstração de classe para uma janela Win32 com alto reconhecimento de DPI. Pretendido ser
// herdado por classes que desejam se especializar com customização
// renderização e tratamento de entrada
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Cria e mostra uma janela win32 com |title| e posição e tamanho usando
  // |origem| e |tamanho|. Novas janelas são criadas no monitor padrão. Janela
  // os tamanhos são especificados para o sistema operacional em pixels físicos, portanto, para garantir uma
  // tamanho consistente para tratará a largura altura passada para esta função
  // como pixels lógicos e dimensionados de acordo com o monitor padrão. Devoluções
  // verdadeiro se a janela foi criada com sucesso.
  bool CreateAndShow(const std::wstring& title,
                     const Point& origin,
                     const Size& size);

  // Libera recursos do SO associados à janela.
  void Destroy();

  // Insere |conteúdo| na árvore da janela.
  void SetChildContent(HWND content);

  // Retorna o identificador da janela de apoio para permitir que os clientes definam o ícone e outros
  //propriedades da janela. Retorna nullptr se a janela tiver sido destruída.
  HWND GetHandle();

  // Se for true, fechar esta janela encerrará o aplicativo.
  void SetQuitOnClose(bool quit_on_close);

  // Retorna um RECT representando os limites da área do cliente atual.
  RECT GetClientArea();

 protected:
  // Processa e roteia mensagens de janela importantes para manipulação do mouse,
  // mudança de tamanho e DPI. Delega o tratamento destes para sobrecargas de membros que
  // classes herdadas podem ser tratadas.
  virtual LRESULT MessageHandler(HWND window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Chamado quando CreateAndShow é chamado, permitindo subclasse relacionada à janela
  // configurar. As subclasses deverão retornar false se a configuração falhar.
  virtual bool OnCreate();

  // Chamado quando Destroy é chamado.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // Retorno de chamada do SO chamado pela bomba de mensagem. Lida com a mensagem WM_NCCREATE que
  // é passado quando a área não cliente está sendo criada e habilita o automático
  // escalonamento de DPI não cliente para que a área não cliente seja automaticamente
  // responde às mudanças no DPI. Todas as outras mensagens são tratadas por
  //MensagemHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Recupera um ponteiro de instância de classe para |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  bool quit_on_close_ = false;

  // identificador de janela para janela de nível superior.
  HWND window_handle_ = nullptr;

  // identificador de janela para conteúdo hospedado.
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
