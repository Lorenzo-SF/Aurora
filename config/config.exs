import Config

config :aurora, :colors,
  colors: %{
    no_color: %{name: :no_color, hex: "#F8F8F2"},
    debug: %{name: :debug, hex: "#B0B0B0"},
    primary: %{name: :primary, hex: "#A1E7FA"},
    secondary: %{name: :secondary, hex: "#3AABA3"},
    ternary: %{name: :ternary, hex: "#FF8000"},
    quaternary: %{name: :quaternary, hex: "#9B42E2"},
    success: %{name: :success, hex: "#97C53C"},
    warning: %{name: :warning, hex: "#FFCC00"},
    warn: %{name: :warning, hex: "#FFCC00"},
    error: %{name: :error, hex: "#FF5B5B"},
    info: %{name: :info, hex: "#00ffff"},
    happy: %{name: :happy, hex: "#EE80C3"},
    background: %{name: :background, hex: "#32302f"},
    menu: %{name: :menu, hex: "#abcdf1"},
    notice: %{name: :notice, hex: "#5FD7FF"},
    critical: %{name: :critical, hex: "#fbff00", inverted: true},
    alert: %{name: :alert, hex: "#fbff00", inverted: true},
    emergency: %{name: :emergency, hex: "#FF0000", inverted: true}
  },
  gradients: %{
    gradient_1: %{name: :gradient_1, hex: "#ff8000"},
    gradient_2: %{name: :gradient_2, hex: "#ff9429"},
    gradient_3: %{name: :gradient_3, hex: "#ffa952"},
    gradient_4: %{name: :gradient_4, hex: "#ffbd7a"},
    gradient_5: %{name: :gradient_5, hex: "#ffd2a3"},
    gradient_6: %{name: :gradient_6, hex: "#ffe6cc"}
  }
