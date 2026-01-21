import 'dart:ui' show Color;

/// Centralized color constants for the Homelab Simulator app.
///
/// These colors provide a consistent theme across all UI components
/// and game objects. Use these instead of inline Color() definitions.
abstract final class AppColors {
  // ============ UI BACKGROUNDS ============

  /// Primary dark background color (scaffold, main screen)
  static const Color darkBackground = Color(0xFF0D0D1A);

  /// Secondary background color (panels, sections)
  static const Color secondaryBackground = Color(0xFF1A1A2E);

  /// Component/card background color
  static const Color componentBackground = Color(0xFF252540);

  /// Container background (darker variant)
  static const Color containerBackground = Color(0xFF151528);

  /// Selection/active state background
  static const Color selectionBackground = Color(0xFF303060);

  // ============ MODAL/DIALOG COLORS ============

  /// Modal accent color (purple)
  static const Color modalAccent = Color(0xFF9C27B0);

  /// Modal accent light variant
  static const Color modalAccentLight = Color(0xFFBA68C8);

  /// Modal accent dark variant
  static const Color modalAccentDark = Color(0xFF7B1FA2);

  // ============ GAME COMPONENT COLORS ============

  /// Room background color
  static const Color roomBackground = Color(0xFF1A1A2E);

  /// Grid overlay color (semi-transparent white)
  static const Color gridOverlay = Color(0x33FFFFFF);

  // ============ PLACEMENT FEEDBACK ============

  /// Valid placement fill (semi-transparent green)
  static const Color validPlacementFill = Color(0x6600FF88);

  /// Valid placement border (bright green)
  static const Color validPlacementBorder = Color(0xFF00FF88);

  /// Invalid placement fill (semi-transparent red)
  static const Color invalidPlacementFill = Color(0x66FF4444);

  /// Invalid placement border (bright red)
  static const Color invalidPlacementBorder = Color(0xFFFF4444);

  // ============ DEVICE STATUS ============

  /// Device selection highlight color
  static const Color deviceSelection = Color(0xFFFFFF00);

  /// Running device indicator (green LED)
  static const Color runningIndicator = Color(0xFF00FF00);

  /// Off device indicator (gray LED)
  static const Color offIndicator = Color(0xFF666666);

  // ============ DOOR COLORS ============

  /// Door frame color
  static const Color doorFrame = Color(0xFF4A4A5A);

  /// Door normal state color
  static const Color doorNormal = Color(0xFF3366CC);

  /// Door highlighted state color
  static const Color doorHighlight = Color(0xFF5588FF);

  /// Door handle color (gold)
  static const Color doorHandle = Color(0xFFFFD700);

  /// Door border color
  static const Color doorBorder = Color(0xFF555555);

  /// Door arrow color (white)
  static const Color doorArrow = Color(0xFFFFFFFF);

  // ============ TERMINAL COLORS ============

  /// Terminal base color
  static const Color terminalBase = Color(0xFF2D2D2D);

  /// Terminal screen color
  static const Color terminalScreen = Color(0xFF00AA55);

  /// Terminal highlight color
  static const Color terminalHighlight = Color(0xFF00DD77);

  /// Terminal border color
  static const Color terminalBorder = Color(0xFF3D3D3D);

  // ============ PLAYER COLORS ============

  /// Player body color (teal)
  static const Color playerBody = Color(0xFF4ECDC4);

  /// Player outline color (darker teal)
  static const Color playerOutline = Color(0xFF2E8B84);

  // ============ DEVICE TYPE COLORS ============
  // Used for categorizing different device types visually

  /// Server device color (blue)
  static const Color deviceServer = Color(0xFF3498DB);

  /// Computer device color (purple)
  static const Color deviceComputer = Color(0xFF9B59B6);

  /// Phone device color (red)
  static const Color devicePhone = Color(0xFFE74C3C);

  /// Router device color (orange)
  static const Color deviceRouter = Color(0xFFF39C12);

  /// Switch device color (teal)
  static const Color deviceSwitch = Color(0xFF1ABC9C);

  /// IoT device color (green)
  static const Color deviceIot = Color(0xFF27AE60);

  /// NAS device color (dark gray)
  static const Color deviceNas = Color(0xFF34495E);

  /// Monitor device color (lighter gray)
  static const Color deviceMonitor = Color(0xFF7F8C8D);

  // ============ CLOUD PROVIDER COLORS ============

  /// AWS orange
  static const Color providerAws = Color(0xFFFF9900);

  /// GCP blue
  static const Color providerGcp = Color(0xFF4285F4);

  /// Azure blue
  static const Color providerAzure = Color(0xFF0078D4);

  /// DigitalOcean blue
  static const Color providerDigitalOcean = Color(0xFF0080FF);

  /// Vultr blue
  static const Color providerVultr = Color(0xFF007BFC);

  /// Cloudflare orange
  static const Color providerCloudflare = Color(0xFFF38020);

  /// No provider (gray)
  static const Color providerNone = Color(0xFF9E9E9E);

  // ============ SERVICE CATEGORY COLORS ============
  // Same as device type colors for consistency

  /// Compute category (blue)
  static const Color categoryCompute = Color(0xFF3498DB);

  /// Storage category (green)
  static const Color categoryStorage = Color(0xFF27AE60);

  /// Database category (orange)
  static const Color categoryDatabase = Color(0xFFF39C12);

  /// Networking category (purple)
  static const Color categoryNetworking = Color(0xFF9B59B6);

  /// Serverless category (red)
  static const Color categoryServerless = Color(0xFFE74C3C);

  /// Container category (teal)
  static const Color categoryContainer = Color(0xFF1ABC9C);

  /// Other category (blue-gray)
  static const Color categoryOther = Color(0xFF607D8B);

  // ============ ROOM TYPE COLORS ============

  /// Server room color (blue)
  static const Color roomServer = Color(0xFF3498DB);

  /// Network room color (purple)
  static const Color roomNetwork = Color(0xFF9B59B6);

  /// Cloud region room color (orange)
  static const Color roomCloudRegion = Color(0xFFF39C12);

  /// Storage room color (green)
  static const Color roomStorage = Color(0xFF27AE60);

  /// Office room color (teal)
  static const Color roomOffice = Color(0xFF1ABC9C);

  /// Custom/generic room color (gray)
  static const Color roomCustom = Color(0xFF888888);

  // ============ CHARACTER HAIR COLORS ============

  /// Black hair
  static const Color hairBlack = Color(0xFF1A1A1A);

  /// Brown hair
  static const Color hairBrown = Color(0xFF8B4513);

  /// Blonde hair
  static const Color hairBlonde = Color(0xFFFFD700);

  /// Red hair
  static const Color hairRed = Color(0xFFB22222);

  /// Gray hair
  static const Color hairGray = Color(0xFF808080);

  /// Blue hair
  static const Color hairBlue = Color(0xFF4169E1);

  /// Green hair
  static const Color hairGreen = Color(0xFF228B22);

  /// Purple hair
  static const Color hairPurple = Color(0xFF9932CC);

  // ============ CLOUD SERVICE ICON COLOR ============

  /// Cloud service icon color (white)
  static const Color cloudServiceIcon = Color(0xFFFFFFFF);

  // ============ GREY SCALE (for UI elements) ============

  /// Grey 300 - Light grey for text/values
  static const Color grey300 = Color(0xFFE0E0E0);

  /// Grey 400 - Medium light grey for secondary text
  static const Color grey400 = Color(0xFFBDBDBD);

  /// Grey 500 - Medium grey for labels/hints
  static const Color grey500 = Color(0xFF9E9E9E);

  /// Grey 600 - Medium dark grey for muted text
  static const Color grey600 = Color(0xFF757575);

  /// Grey 700 - Dark grey for borders
  static const Color grey700 = Color(0xFF616161);

  /// Grey 800 - Very dark grey for backgrounds
  static const Color grey800 = Color(0xFF424242);

  /// Grey 900 - Nearly black for dark backgrounds
  static const Color grey900 = Color(0xFF212121);

  // ============ ACCENT COLORS ============

  /// Cyan 200 - Light cyan for text highlights
  static const Color cyan200 = Color(0xFF80DEEA);

  /// Cyan 400 - Accent color for highlights
  static const Color cyan400 = Color(0xFF26C6DA);

  /// Cyan 500 - Medium cyan for active states
  static const Color cyan500 = Color(0xFF00BCD4);

  /// Cyan 700 - Medium cyan for borders
  static const Color cyan700 = Color(0xFF0097A7);

  /// Cyan 800 - Dark cyan for badges/chips
  static const Color cyan800 = Color(0xFF00838F);

  /// Cyan 900 - Very dark cyan for backgrounds
  static const Color cyan900 = Color(0xFF006064);

  /// Green 400 - Light green for positive states
  static const Color green400 = Color(0xFF66BB6A);

  /// Green 700 - Medium green for borders
  static const Color green700 = Color(0xFF388E3C);

  /// Green 800 - Dark green for backgrounds
  static const Color green800 = Color(0xFF2E7D32);

  /// Red 800 - Dark red for error backgrounds
  static const Color red800 = Color(0xFFC62828);

  /// Blue 400 - Light blue for icons
  static const Color blue400 = Color(0xFF42A5F5);

  /// Blue 700 - Medium blue for chips
  static const Color blue700 = Color(0xFF1976D2);

  /// Blue 800 - Dark blue for backgrounds
  static const Color blue800 = Color(0xFF1565C0);

  /// Blue 900 - Very dark blue for backgrounds
  static const Color blue900 = Color(0xFF0D47A1);

  /// Orange 800 - Dark orange for warnings
  static const Color orange800 = Color(0xFFEF6C00);

  /// Amber 400 - Light amber for icons and highlights
  static const Color amber400 = Color(0xFFFFCA28);

  /// Amber 700 - Dark amber for borders
  static const Color amber700 = Color(0xFFFFA000);

  // ============ PANEL/OVERLAY COLORS ============

  /// Panel background - equivalent to Colors.black87 (0xDD000000)
  static const Color panelBackground = Color(0xDD000000);

  /// Overlay background - equivalent to Colors.black54 (0x8A000000)
  static const Color overlayBackground = Color(0x8A000000);

  /// Divider color - neutral grey for separating content
  static const Color divider = Color(0xFF9E9E9E);

  // ============ TEXT COLORS ============

  /// Pure white for primary text
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// White with 70% opacity (white70)
  static const Color textSecondary = Color(0xB3FFFFFF);

  /// White with 54% opacity (white54)
  static const Color textTertiary = Color(0x8AFFFFFF);

  /// White with 40% opacity (for hints)
  static const Color textHint = Color(0x66FFFFFF);

  /// White with 38% opacity (for disabled text)
  static const Color textDisabled = Color(0x61FFFFFF);

  /// White with 30% opacity (for borders/dividers)
  static const Color borderLight = Color(0x4DFFFFFF);

  /// White with 10% opacity (for subtle borders)
  static const Color borderSubtle = Color(0x1AFFFFFF);

  // ============ ADDITIONAL ACCENT COLORS ============

  /// Cyan 600 - Medium dark cyan for buttons
  static const Color cyan600 = Color(0xFF00ACC1);

  /// Cyan with 70% opacity for icons
  static const Color cyanMuted = Color(0xB300BCD4);

  /// Red accent for errors
  static const Color redAccent = Color(0xFFFF5252);

  /// Red with 70% opacity for delete icons
  static const Color redMuted = Color(0xB3F44336);
}
