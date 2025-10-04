#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
      
    case WM_GETMINMAXINFO: {
      // Ограничиваем минимальный и максимальный размер окна
      MINMAXINFO* pMMI = (MINMAXINFO*)lparam;
      pMMI->ptMinTrackSize.x = 300;  // Минимальная ширина
      pMMI->ptMinTrackSize.y = 600;  // Минимальная высота (соотношение 1:2)
      pMMI->ptMaxTrackSize.x = 600;  // Максимальная ширина
      pMMI->ptMaxTrackSize.y = 1200; // Максимальная высота (соотношение 1:2)
      return 0;
    }
    
    case WM_SIZING: {
      // Сохраняем соотношение сторон 1:2 при изменении размера
      RECT* pRect = (RECT*)lparam;
      int width = pRect->right - pRect->left;
      
      // Вычисляем новую высоту на основе ширины (соотношение 1:2)
      int newHeight = width * 2;
      
      // Корректируем размер в зависимости от того, какой край перетаскивается
      UINT edge = static_cast<UINT>(wparam);
      switch (edge) {
        case WMSZ_LEFT:
        case WMSZ_RIGHT:
        case WMSZ_LEFT + WMSZ_BOTTOM:
        case WMSZ_RIGHT + WMSZ_BOTTOM:
          // Изменяем высоту снизу
          pRect->bottom = pRect->top + newHeight;
          break;
        case WMSZ_TOP:
        case WMSZ_BOTTOM:
        case WMSZ_TOP + WMSZ_LEFT:
        case WMSZ_TOP + WMSZ_RIGHT:
          // Изменяем высоту сверху
          pRect->top = pRect->bottom - newHeight;
          break;
      }
      return TRUE;
    }
    
    case WM_SYSCOMMAND: {
      // Блокируем команды развертывания
      switch (wparam & 0xFFF0) {
        case SC_MAXIMIZE:
          // Блокируем развертывание
          return 0;
        case SC_RESTORE:
          // Блокируем восстановление (если окно было развернуто)
          return 0;
      }
      break;
    }
    
    case WM_NCLBUTTONDBLCLK: {
      // Блокируем двойной клик по заголовку для развертывания
      if (wparam == HTCAPTION) {
        return 0;  // Блокируем развертывание
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
