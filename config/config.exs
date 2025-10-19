import Config

config :aurora, :colors,
  colors: %{
    no_color: %{
      name: :no_color,
      hex: "#F8F8F2",
      rgb: {248, 248, 242},
      argb: {255, 248, 248, 242},
      hsv: {60.0, 0.024, 0.972},
      hsl: {60.0, 0.286, 0.961},
      cmyk: {0.0, 0.0, 0.024, 0.028},
      inverted: false
    },
    debug: %{
      name: :debug,
      hex: "#B0B0B0",
      rgb: {176, 176, 176},
      argb: {255, 176, 176, 176},
      hsv: {0.0, 0.0, 0.690},
      hsl: {0.0, 0.0, 0.690},
      cmyk: {0.0, 0.0, 0.0, 0.310},
      inverted: false
    },
    primary: %{
      name: :primary,
      hex: "#A1E7FA",
      rgb: {161, 231, 250},
      argb: {255, 161, 231, 250},
      hsv: {192.0, 0.356, 0.980},
      hsl: {192.0, 0.892, 0.806},
      cmyk: {0.356, 0.076, 0.0, 0.020},
      inverted: false
    },
    secondary: %{
      name: :secondary,
      hex: "#3AABA3",
      rgb: {58, 171, 163},
      argb: {255, 58, 171, 163},
      hsv: {176.0, 0.661, 0.671},
      hsl: {176.0, 0.493, 0.449},
      cmyk: {0.661, 0.0, 0.047, 0.329},
      inverted: false
    },
    ternary: %{
      name: :ternary,
      hex: "#FF8000",
      rgb: {255, 128, 0},
      argb: {255, 255, 128, 0},
      hsv: {30.0, 1.0, 1.0},
      hsl: {30.0, 1.0, 0.5},
      cmyk: {0.0, 0.498, 1.0, 0.0},
      inverted: false
    },
    quaternary: %{
      name: :quaternary,
      hex: "#9B42E2",
      rgb: {155, 66, 226},
      argb: {255, 155, 66, 226},
      hsv: {274.0, 0.708, 0.886},
      hsl: {274.0, 0.734, 0.573},
      cmyk: {0.314, 0.708, 0.0, 0.114},
      inverted: false
    },
    success: %{
      name: :success,
      hex: "#97C53C",
      rgb: {151, 197, 60},
      argb: {255, 151, 197, 60},
      hsv: {80.0, 0.695, 0.773},
      hsl: {80.0, 0.534, 0.504},
      cmyk: {0.234, 0.0, 0.695, 0.227},
      inverted: false
    },
    warning: %{
      name: :warning,
      hex: "#FFCC00",
      rgb: {255, 204, 0},
      argb: {255, 255, 204, 0},
      hsv: {48.0, 1.0, 1.0},
      hsl: {48.0, 1.0, 0.5},
      cmyk: {0.0, 0.2, 1.0, 0.0},
      inverted: false
    },
    error: %{
      name: :error,
      hex: "#FF5B5B",
      rgb: {255, 91, 91},
      argb: {255, 255, 91, 91},
      hsv: {0.0, 0.643, 1.0},
      hsl: {0.0, 1.0, 0.678},
      cmyk: {0.0, 0.643, 0.643, 0.0},
      inverted: false
    },
    info: %{
      name: :info,
      hex: "#00FFFF",
      rgb: {0, 255, 255},
      argb: {255, 0, 255, 255},
      hsv: {180.0, 1.0, 1.0},
      hsl: {180.0, 1.0, 0.5},
      cmyk: {1.0, 0.0, 0.0, 0.0},
      inverted: false
    },
    happy: %{
      name: :happy,
      hex: "#EE80C3",
      rgb: {238, 128, 195},
      argb: {255, 238, 128, 195},
      hsv: {326.0, 0.462, 0.933},
      hsl: {326.0, 0.767, 0.718},
      cmyk: {0.0, 0.462, 0.181, 0.067},
      inverted: false
    },
    background: %{
      name: :background,
      hex: "#32302F",
      rgb: {50, 48, 47},
      argb: {255, 50, 48, 47},
      hsv: {20.0, 0.06, 0.196},
      hsl: {20.0, 0.031, 0.190},
      cmyk: {0.0, 0.04, 0.06, 0.804},
      inverted: false
    },
    menu: %{
      name: :menu,
      hex: "#ABCDF1",
      rgb: {171, 205, 241},
      argb: {255, 171, 205, 241},
      hsv: {210.0, 0.290, 0.945},
      hsl: {210.0, 0.714, 0.808},
      cmyk: {0.290, 0.149, 0.0, 0.055},
      inverted: false
    },
    notice: %{
      name: :notice,
      hex: "#5FD7FF",
      rgb: {95, 215, 255},
      argb: {255, 95, 215, 255},
      hsv: {196.0, 0.627, 1.0},
      hsl: {196.0, 1.0, 0.686},
      cmyk: {0.627, 0.157, 0.0, 0.0},
      inverted: false
    },
    critical: %{
      name: :critical,
      hex: "#FBFF00",
      rgb: {251, 255, 0},
      argb: {255, 251, 255, 0},
      hsv: {61.2, 1.0, 1.0},
      hsl: {61.2, 1.0, 0.5},
      cmyk: {0.016, 0.0, 1.0, 0.0},
      inverted: true
    },
    alert: %{
      name: :alert,
      hex: "#FBFF00",
      rgb: {251, 255, 0},
      argb: {255, 251, 255, 0},
      hsv: {61.2, 1.0, 1.0},
      hsl: {61.2, 1.0, 0.5},
      cmyk: {0.016, 0.0, 1.0, 0.0},
      inverted: true
    },
    emergency: %{
      name: :emergency,
      hex: "#FF0000",
      rgb: {255, 0, 0},
      argb: {255, 255, 0, 0},
      hsv: {0.0, 1.0, 1.0},
      hsl: {0.0, 1.0, 0.5},
      cmyk: {0.0, 1.0, 1.0, 0.0},
      inverted: true
    }
  },
  gradients: %{
    gradient_1: %{
      name: :gradient_1,
      hex: "#FF8000",
      rgb: {255, 128, 0},
      argb: {255, 255, 128, 0},
      hsv: {30.0, 1.0, 1.0},
      hsl: {30.0, 1.0, 0.5},
      cmyk: {0.0, 0.498, 1.0, 0.0},
      inverted: false
    },
    gradient_2: %{
      name: :gradient_2,
      hex: "#FF9429",
      rgb: {255, 148, 41},
      argb: {255, 255, 148, 41},
      hsv: {30.0, 0.839, 1.0},
      hsl: {30.0, 1.0, 0.580},
      cmyk: {0.0, 0.420, 0.839, 0.0},
      inverted: false
    },
    gradient_3: %{
      name: :gradient_3,
      hex: "#FFA952",
      rgb: {255, 169, 82},
      argb: {255, 255, 169, 82},
      hsv: {30.0, 0.678, 1.0},
      hsl: {30.0, 1.0, 0.661},
      cmyk: {0.0, 0.337, 0.678, 0.0},
      inverted: false
    },
    gradient_4: %{
      name: :gradient_4,
      hex: "#FFBD7A",
      rgb: {255, 189, 122},
      argb: {255, 255, 189, 122},
      hsv: {30.0, 0.522, 1.0},
      hsl: {30.0, 1.0, 0.739},
      cmyk: {0.0, 0.259, 0.522, 0.0},
      inverted: false
    },
    gradient_5: %{
      name: :gradient_5,
      hex: "#FFD2A3",
      rgb: {255, 210, 163},
      argb: {255, 255, 210, 163},
      hsv: {30.0, 0.361, 1.0},
      hsl: {30.0, 1.0, 0.820},
      cmyk: {0.0, 0.176, 0.361, 0.0},
      inverted: false
    },
    gradient_6: %{
      name: :gradient_6,
      hex: "#FFE6CC",
      rgb: {255, 230, 204},
      argb: {255, 255, 230, 204},
      hsv: {30.0, 0.200, 1.0},
      hsl: {30.0, 1.0, 0.900},
      cmyk: {0.0, 0.098, 0.200, 0.0},
      inverted: false
    }
  }
