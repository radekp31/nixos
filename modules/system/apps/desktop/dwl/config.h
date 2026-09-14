/* Keep this file synchronized with the dwl release used by pkgs.dwl. */

#define COLOR(hex) { \
    ((hex >> 24) & 0xFF) / 255.0f, \
    ((hex >> 16) & 0xFF) / 255.0f, \
    ((hex >> 8) & 0xFF) / 255.0f, \
    (hex & 0xFF) / 255.0f \
}

/* appearance */
static const int sloppyfocus = 1;
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx = 1;
static const int showbar = 1;
static const int topbar = 1;
static const char *fonts[] = { "monospace:size=10" };
const float rootcolor[] = COLOR(0x000000ff);
static const float fullscreen_bg[] = { 0.1f, 0.1f, 0.1f, 1.0f };
static uint32_t colors[][3] = {
    /*               fg          bg          border    */
    [SchemeNorm] = { 0xbbbbbbff, 0x222222ff, 0x444444ff },
    [SchemeSel]  = { 0xeeeeeeff, 0x005577ff, 0x005577ff },
    [SchemeUrg]  = { 0,          0,          0x770000ff },
};

/* tagging */
static char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

/* logging */
static int log_level = WLR_ERROR;

/* window rules */
static const Rule rules[] = {
	/* app_id            title   tags mask   isfloating   monitor */
	/* "monitor" is an index into dwl's mons list, not a monrules index and
	 * not a name. dwl inserts each new monitor at the head of that list, so
	 * index 0 is the monitor that dwl created LAST. On this machine index 0
	 * is DP-2 (2560x1440) and index 1 is HDMI-A-1 (1920x1080). Re-check the
	 * order after you replug a cable or change the boot order.
	 * A "tags mask" of 0 keeps the client on the tag you currently view.
	 * A non-zero mask pins the client to that tag, and dwl does NOT switch
	 * the view, so the window becomes invisible when you view another tag. */
	{ "dota2",           NULL,   0,          0,           0 },
	/* gamescope wraps the game in its own surface. The window then reports
	 * app_id "gamescope", not "dota2", so it needs its own rule. */
	{ "gamescope",       NULL,   0,          0,           0 },
	{ "Gimp_EXAMPLE",    NULL,   0,          1,          -1 },
};

/* layouts */
static const Layout layouts[] = {
    { "[]=", tile },
    { "><>", NULL },
    { "[M]", monocle },
};

///* monitors */
//static const MonitorRule monrules[] = {
//    { NULL, 0.55f, 1, 1, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1, -1 },
//};
/* dwl has no "primary monitor" option. It picks the initial selmon with
 * selmon = xytomon(0, 0), so the monitor that covers the layout origin
 * becomes the main monitor. The first client opens there. Keep DP-2 at
 * x=0, y=0 to make the 1440p screen the main one.
 * Layout:
 *           +----------------+
 *           |                |
 *   +-------+                |
 *   | HDMI  |   DP-2  1440p  |
 *   | 1080p |   main         |
 *   +-------+                |
 *           |                |
 *           +----------------+
 *   x=-1920            x=0
 *   y=180              y=0
 * dwl always uses the preferred mode of each monitor: 2560x1440@144 on
 * DP-2 and 1920x1080@60 on HDMI-A-1. */
static const MonitorRule monrules[] = {
	/* name        mfact  nmaster scale layout       rotate/reflect                 x     y */
	/* LG 27GL850, 2560x1440. Main monitor, because it covers the origin. */
	{ "DP-2",      0.55f, 1,      1.0f, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,     0,    0 },
	/* Samsung S24E650, 1920x1080. A negative x puts it left of DP-2.
	 * y=180 centres its 1080 px against the 1440 px of DP-2. That leaves
	 * 180 px at the top and at the bottom of DP-2 with no neighbour. */
	{ "HDMI-A-1",  0.55f, 1,      1.0f, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1920,  180 },
	/* default fallback */
	{ NULL,        0.55f, 1,      1.0f, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,    -1,   -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
    .options = NULL,
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

/* trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

//#define MODKEY WLR_MODIFIER_ALT
#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY, SKEY, TAG) \
    { MODKEY, KEY, view, {.ui = 1 << TAG} }, \
    { MODKEY|WLR_MODIFIER_CTRL, KEY, toggleview, {.ui = 1 << TAG} }, \
    { MODKEY|WLR_MODIFIER_SHIFT, SKEY, tag, {.ui = 1 << TAG} }, \
    { MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, SKEY, toggletag, {.ui = 1 << TAG} }

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */

/* ---------------------------------------------------------------------------
 * 2026-09-14: why termcmd is a plain binary and NOT xdg-terminal-exec.
 * Read this before you change termcmd back. The investigation took hours.
 *
 * SYMPTOM
 *   Mod+Shift+Return started no terminal. The fallback Mod+Shift+T also
 *   started no terminal. No window appeared on any tag or on any monitor.
 *   Mod+p, Mod+j, Mod+k, Mod+Shift+C and Mod+1 to Mod+9 all worked.
 *
 * CAUSE
 *   termcmd was "xdg-terminal-exec". That command is a dash script of 1484
 *   lines. Every instance that dwl forks hangs. The script never reaches its
 *   final exec, so no terminal ever starts.
 *
 * EVIDENCE
 *   One session left 34 of these processes alive. All were direct children
 *   of dwl. All were blocked in anon_pipe_read. All stopped at exactly the
 *   same place: byte 40855 of 43718 in the script. An identical offset in
 *   every process proves the fault is deterministic and is not a race.
 *   Bursts of 3 to 4 processes in one second come from key repeat.
 *
 * WHAT THE EVIDENCE PROVES
 *   The keybinding matches correctly. spawn() works correctly. dwl forked
 *   the command 34 times, so the key and the compositor are not at fault.
 *   Only the script fails. fuzzel is a plain binary and always starts from
 *   Mod+p, which confirms that spawn() itself is healthy.
 *
 * CAUSES TESTED AND RULED OUT - do not test these again
 *   - SIGCHLD ignored across execvp. SigIgn is 0 in dwl and in the child.
 *   - stdin is /dev/tty3. An stdin that never gives EOF still succeeds.
 *   - A different environment. The environment of a real hung child was
 *     read from /proc and it matches a run that succeeds.
 *   - The cold cache path inside the script. It succeeds.
 *   - A process limit. pids.max is "max" and pids.events shows "max 0".
 *   The hang never appeared outside dwl. A faithful copy of the dwl spawn
 *   conditions (stdin /dev/tty3, stderr the append log, stdout dup2 from
 *   stderr, setsid, the dwl environment) succeeded under strace every time.
 *   The mechanism inside dash stays unknown. This entry removes the failing
 *   component. It does not repair dash.
 *
 * RULE THAT FOLLOWS
 *   Put only a plain binary in a spawn() command. Do not put a shell script
 *   there. The SHCMD() macro above carries the same risk. Use it with care.
 *
 * NOTE ON seat-keyboard-restore.patch IN default.nix
 *   That patch works. This session shows no "no keymap" abort from wezterm.
 *   The keymap defect was a separate fault. It was NOT the cause of this
 *   symptom. Keep the patch. Do not expect it to fix a terminal keybinding.
 *
 * HOW TO DIAGNOSE THIS AGAIN
 *   dwl sends the stderr of every spawned child to
 *     ~/.local/share/sddm/wayland-session.log
 *   List the children that dwl spawned with
 *     ps -eo pid,ppid,args | awk '$2==<dwl pid>'
 *   For a hung shell script, read the script offset with
 *     cat /proc/<pid>/fdinfo/10
 *   The "pos" value gives the byte that dash has read to. Compare that value
 *   across the hung processes. Equal values mean a deterministic fault.
 * ------------------------------------------------------------------------- */

/* --always-new-process gives one new window for each keypress. Without the
 * flag wezterm gives the request to the GUI instance that already runs, and
 * the new window then belongs to that instance. */
static const char *termcmd[] = { "wezterm", "start", "--always-new-process", NULL };
//static const char *menucmd[] = { "fuzzel", "--dmenu", NULL };
static const char *menucmd[] = { "fuzzel", NULL };

static const Key keys[] = {
    { MODKEY, XKB_KEY_p, spawn, {.v = menucmd} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Return, spawn, {.v = termcmd} },
    /* Fallback key for the same terminal. The test that this comment once
     * described is complete. Both keys failed together while termcmd was
     * xdg-terminal-exec. The Return key was therefore never the fault. See
     * the long note above termcmd. Keep this key only as a second way to
     * start a terminal. Delete it freely. */
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_T, spawn, {.v = termcmd} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_R, reload, {0} },
    { MODKEY, XKB_KEY_b, togglebar, {0} },

    { MODKEY, XKB_KEY_j, focusstack, {.i = +1} },
    { MODKEY, XKB_KEY_k, focusstack, {.i = -1} },
    { MODKEY, XKB_KEY_i, incnmaster, {.i = +1} },
    { MODKEY, XKB_KEY_d, incnmaster, {.i = -1} },
    { MODKEY, XKB_KEY_h, setmfact, {.f = -0.05f} },
    { MODKEY, XKB_KEY_l, setmfact, {.f = +0.05f} },
    { MODKEY, XKB_KEY_Return, zoom, {0} },
    { MODKEY, XKB_KEY_Tab, view, {0} },

    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_C, killclient, {0} },
    { MODKEY, XKB_KEY_t, setlayout, {.v = &layouts[0]} },
    { MODKEY, XKB_KEY_f, setlayout, {.v = &layouts[1]} },
    { MODKEY, XKB_KEY_m, setlayout, {.v = &layouts[2]} },
    { MODKEY, XKB_KEY_space, setlayout, {0} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_space, togglefloating, {0} },
    { MODKEY, XKB_KEY_e, togglefullscreen, {0} },

    { MODKEY, XKB_KEY_0, view, {.ui = ~0} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_parenright, tag, {.ui = ~0} },
    { MODKEY, XKB_KEY_comma, focusmon, {.i = WLR_DIRECTION_LEFT} },
    { MODKEY, XKB_KEY_period, focusmon, {.i = WLR_DIRECTION_RIGHT} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_less, tagmon, {.i = WLR_DIRECTION_LEFT} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_greater, tagmon, {.i = WLR_DIRECTION_RIGHT} },

    TAGKEYS(XKB_KEY_1, XKB_KEY_exclam, 0),
    TAGKEYS(XKB_KEY_2, XKB_KEY_at, 1),
    TAGKEYS(XKB_KEY_3, XKB_KEY_numbersign, 2),
    TAGKEYS(XKB_KEY_4, XKB_KEY_dollar, 3),
    TAGKEYS(XKB_KEY_5, XKB_KEY_percent, 4),
    TAGKEYS(XKB_KEY_6, XKB_KEY_asciicircum, 5),
    TAGKEYS(XKB_KEY_7, XKB_KEY_ampersand, 6),
    TAGKEYS(XKB_KEY_8, XKB_KEY_asterisk, 7),
    TAGKEYS(XKB_KEY_9, XKB_KEY_parenleft, 8),

    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Q, quit, {0} },
    { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT, XKB_KEY_Terminate_Server, quit, {0} },
};

static const Button buttons[] = {
    { ClkLtSymbol, 0,      BTN_LEFT,   setlayout,      {.v = &layouts[0]} },
    { ClkLtSymbol, 0,      BTN_RIGHT,  setlayout,      {.v = &layouts[2]} },
    { ClkTitle,    0,      BTN_MIDDLE, zoom,           {0} },
    { ClkStatus,   0,      BTN_MIDDLE, spawn,          {.v = termcmd} },
    { ClkClient,   MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
    { ClkClient,   MODKEY, BTN_MIDDLE, togglefloating, {0} },
    { ClkClient,   MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
    { ClkTagBar,   0,      BTN_LEFT,   view,           {0} },
    { ClkTagBar,   0,      BTN_RIGHT,  toggleview,     {0} },
    { ClkTagBar,   MODKEY, BTN_LEFT,   tag,            {0} },
    { ClkTagBar,   MODKEY, BTN_RIGHT,  toggletag,      {0} },
};
