#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView *view)
{
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
  
  // Проверяем переменные окружения для Wayland композиторов
  const gchar* wayland_display = g_getenv("WAYLAND_DISPLAY");
  if (wayland_display != NULL) {
    const gchar* xdg_session_type = g_getenv("XDG_SESSION_TYPE");
    if (g_strcmp0(xdg_session_type, "wayland") == 0) {
      // Список тайлинговых Wayland композиторов
      const gchar* wayland_compositors[] = {
        "Hyprland",
        "sway",
        "river", 
        "wayfire",
        "mutter", // GNOME Shell
        NULL
      };
      
      // Проверяем переменную окружения для определения композитора
      const gchar* compositor = g_getenv("XDG_CURRENT_DESKTOP");
      if (compositor == NULL) {
        compositor = g_getenv("WAYLAND_DISPLAY");
      }
      
      gboolean is_tiling_compositor = FALSE;
      for (int i = 0; wayland_compositors[i] != NULL; i++) {
        if (g_strcmp0(compositor, wayland_compositors[i]) == 0) {
          is_tiling_compositor = TRUE;
          break;
        }
      }
      
      // Отключаем header bar для тайлинговых композиторов
      if (is_tiling_compositor) {
        use_header_bar = FALSE;
      }
    }
  }
  
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    
    // Список тайлинговых оконных менеджеров
    const gchar* tiling_wms[] = {
      "Hyprland",
      "i3",
      "sway", 
      "dwm",
      "awesome",
      "bspwm",
      "herbstluftwm",
      "xmonad",
      "qtile",
      "river",
      "wayfire",
      "mutter", // GNOME Shell может быть тайлинговым
      NULL
    };
    
    // Проверяем, является ли WM тайлинговым
    gboolean is_tiling_wm = FALSE;
    for (int i = 0; tiling_wms[i] != NULL; i++) {
      if (g_strcmp0(wm_name, tiling_wms[i]) == 0) {
        is_tiling_wm = TRUE;
        break;
      }
    }
    
    // Отключаем header bar для тайлинговых WM или не-GNOME окружений
    if (is_tiling_wm || g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "fsda");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "fsda");
  }

  gtk_window_set_default_size(window, 1280, 720);

  // Устанавливаем иконку окна
  GError* icon_error = nullptr;
  GdkPixbuf* icon = nullptr;
  
  // Получаем путь к AppImage
  const gchar* appimage_path = g_getenv("APPIMAGE");
  if (appimage_path != nullptr) {
    // Если запущено из AppImage, ищем иконку рядом с AppImage
    gchar* icon_path = g_build_filename(g_path_get_dirname(appimage_path), "fsda.png", nullptr);
    icon = gdk_pixbuf_new_from_file(icon_path, &icon_error);
    g_free(icon_path);
  }
  
  // Если не нашли, пытаемся найти в стандартных местах
  if (icon == nullptr) {
    const gchar* icon_paths[] = {
      "fsda.png",
      "/usr/share/icons/hicolor/256x256/apps/fsda.png",
      "/usr/share/pixmaps/fsda.png",
      "/usr/share/icons/fsda.png",
      nullptr
    };
    
    for (int i = 0; icon_paths[i] != nullptr; i++) {
      icon = gdk_pixbuf_new_from_file(icon_paths[i], nullptr);
      if (icon != nullptr) {
        break;
      }
    }
  }
  
  if (icon != nullptr) {
    gtk_window_set_icon(window, icon);
    g_object_unref(icon);
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000 for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  MyApplication* app = MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
  
  // Пытаемся установить иконку приложения
  GError* icon_error = nullptr;
  GdkPixbuf* icon = nullptr;
  
  // Получаем путь к AppImage
  const gchar* appimage_path = g_getenv("APPIMAGE");
  if (appimage_path != nullptr) {
    // Если запущено из AppImage, ищем иконку рядом с AppImage
    gchar* icon_path = g_build_filename(g_path_get_dirname(appimage_path), "fsda.png", nullptr);
    icon = gdk_pixbuf_new_from_file(icon_path, &icon_error);
    g_free(icon_path);
  }
  
  // Если не нашли, пытаемся найти в стандартных местах
  if (icon == nullptr) {
    const gchar* icon_paths[] = {
      "fsda.png",
      "/usr/share/icons/hicolor/256x256/apps/fsda.png",
      "/usr/share/pixmaps/fsda.png",
      "/usr/share/icons/fsda.png",
      nullptr
    };
    
    for (int i = 0; icon_paths[i] != nullptr; i++) {
      icon = gdk_pixbuf_new_from_file(icon_paths[i], nullptr);
      if (icon != nullptr) {
        break;
      }
    }
  }
  
  if (icon != nullptr) {
    gtk_window_set_default_icon(icon);
    g_object_unref(icon);
  }

  return app;
}
