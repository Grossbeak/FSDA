#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <fstream>
#include <string>
#include <sstream>

#include "flutter_window.h"
#include "utils.h"

// Функция для чтения конфигурации из res.conf
struct WindowConfig {
  int width;
  int height;
  bool useCustomSize;
};

WindowConfig ReadWindowConfig() {
  WindowConfig config;
  config.useCustomSize = false;
  config.width = 450;  // Значение по умолчанию
  config.height = 900; // Значение по умолчанию
  
  std::ifstream configFile("res.conf");
  if (!configFile.is_open()) {
    return config; // Возвращаем значения по умолчанию
  }
  
  std::string line;
  while (std::getline(configFile, line)) {
    // Ищем строку с custom windows height
    if (line.find("custom windows height:") != std::string::npos) {
      // Извлекаем значение в кавычках
      size_t startQuote = line.find('"');
      size_t endQuote = line.find('"', startQuote + 1);
      
      if (startQuote != std::string::npos && endQuote != std::string::npos) {
        std::string value = line.substr(startQuote + 1, endQuote - startQuote - 1);
        
        if (value == "no") {
          // Используем размер экрана * 0.8 и * 0.4
          int screenHeight = GetSystemMetrics(SM_CYSCREEN);
          config.height = static_cast<int>(screenHeight * 0.8);
          config.width = static_cast<int>(screenHeight * 0.4);
          config.useCustomSize = true;
        } else {
          // Пытаемся распарсить число
          try {
            int customHeight = std::stoi(value);
            config.height = customHeight;
            config.width = customHeight / 2; // Соотношение 1:2
            config.useCustomSize = true;
          } catch (const std::exception&) {
            // Если не удалось распарсить, используем значения по умолчанию
          }
        }
      }
    }
  }
  
  configFile.close();
  return config;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  
  // Читаем конфигурацию окна из res.conf
  WindowConfig config = ReadWindowConfig();
  
  // Получаем размеры экрана для центрирования
  int screenWidth = GetSystemMetrics(SM_CXSCREEN);
  int screenHeight = GetSystemMetrics(SM_CYSCREEN);
  
  // Центрируем окно
  Win32Window::Point origin(
    (screenWidth - config.width) / 2,
    (screenHeight - config.height) / 2
  );
  Win32Window::Size size(config.width, config.height);
  
  if (!window.Create(L"FSDA - Steam Guard Desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  
  // Отключаем кнопку развертывания (максимизации)
  HWND hwnd = window.GetHandle();
  LONG style = GetWindowLong(hwnd, GWL_STYLE);
  style &= ~WS_MAXIMIZEBOX;  // Убираем кнопку развертывания
  SetWindowLong(hwnd, GWL_STYLE, style);
  
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
