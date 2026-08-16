#!/usr/bin/env bash
# /sbin/zbox-zboxtui-setup.sh — kmscon (tty1/tty2) + zBoxTUI on tty1.
#
#   sudo /sbin/zbox-zboxtui-setup.sh --enable
#   sudo /sbin/zbox-zboxtui-setup.sh --disable
#
# Optional: --font fira|hack|jetbrains|meslo  --palette mocha|latte  --font-size 12
set -euo pipefail

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
export APT_LISTCHANGES_FRONTEND=none
export NEEDRESTART_MODE=a

# --- paths ---
readonly SCRIPT_NAME="zbox-zboxtui-setup"
readonly KMSCON_CONF="/etc/kmscon/kmscon.conf"
readonly CONSOLE_MARKER_BEGIN="# BEGIN zbox-console"
readonly CONSOLE_MARKER_END="# END zbox-console"
readonly ZBOXTUI_MARKER_BEGIN="# BEGIN zboxtui"
readonly ZBOXTUI_MARKER_END="# END zboxtui"
readonly NERD_FONTS_ROOT="/usr/share/fonts/truetype/NerdFonts"
readonly BOOT_VT_CONF="/etc/zbox/default-console-vt"
readonly VENV_DIR="/opt/zboxtui/venv"
readonly ZBOXTUI_BIN="/usr/local/bin/zboxtui"
readonly LIB_DIR="/usr/lib/zboxtui"
readonly BUILD_DIR="/tmp/zboxtui-build"

# --- layout (fixed) ---
readonly TTY_ZBOXTUI="tty1"
readonly TTY_KMSCON="tty2"

# --- tunables ---
NERD_FONT="${NERD_FONT:-fira}"
FONT_SIZE="${FONT_SIZE:-12}"
PALETTE="${PALETTE:-mocha}"
NERD_FONT_VERSION="${NERD_FONT_VERSION:-3.3.0}"
ZBOXTUI_GIT_URL="${ZBOXTUI_GIT_URL:-https://github.com/zPodFactory/zBoxTUI.git}"
ZBOXTUI_GIT_REF="${ZBOXTUI_GIT_REF:-main}"

DO_ENABLE=0
DO_DISABLE=0
DO_INSTALL=0
SKIP_KMSCON_RESTART=0

# font metadata (resolve_font)
FONT_ZIP="" FONT_DIR="" FONT_LABEL="" FONT_FAMILY="" FONT_FC_PATTERN=""

[[ -n "${PACKER_BUILDER_TYPE:-}" ]] && SKIP_KMSCON_RESTART=1

log() { echo "[${SCRIPT_NAME}] $*" >&2; }
warn() { echo "[${SCRIPT_NAME}] WARNING: $*" >&2; }
die() { echo "[${SCRIPT_NAME}] ERROR: $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
zbox-zboxtui-setup — kmscon on tty1+tty2, zBoxTUI autostart on tty1

  --install             Install kmscon + zBoxTUI (venv, fonts); console left on stock getty
  --enable              Ensure installed, then wire tty1 (zBoxTUI) + tty2 (kmscon shell)
  --disable             Revert to agetty, remove zBoxTUI/kmscon config, apt purge kmscon

  --font NAME           fira (default), hack, jetbrains, meslo, cascadia, dejavu, ubuntu
  --palette NAME        mocha (default), latte
  --font-size N         Font size in pt (default: 12)

Environment: ZBOXTUI_GIT_URL, ZBOXTUI_GIT_REF, NERD_FONT, FONT_SIZE, PALETTE
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --enable) DO_ENABLE=1 ;;
      --disable) DO_DISABLE=1 ;;
      --install) DO_INSTALL=1 ;;
      --font=*) NERD_FONT="${1#*=}" ;;
      --font) shift; [[ $# -gt 0 ]] || die "--font needs a value"; NERD_FONT="$1" ;;
      --palette=*) PALETTE="${1#*=}" ;;
      --palette) shift; [[ $# -gt 0 ]] || die "--palette needs a value"; PALETTE="$1" ;;
      --font-size=*) FONT_SIZE="${1#*=}" ;;
      --font-size) shift; [[ $# -gt 0 ]] || die "--font-size needs a value"; FONT_SIZE="$1" ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1 (use --install, --enable or --disable)" ;;
    esac
    shift
  done
  [[ "$(id -u)" -eq 0 ]] || die "run as root"
  [[ "$((DO_ENABLE + DO_DISABLE + DO_INSTALL))" -eq 1 ]] || die "specify exactly one of --install, --enable or --disable"
}

codename() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    echo "${VERSION_CODENAME:-trixie}"
  else
    echo trixie
  fi
}

strip_conf_block() {
  local file="$1" begin="$2" end="$3"
  [[ -f "$file" ]] || return 0
  grep -qF "$begin" "$file" || return 0
  awk -v b="$begin" -v e="$end" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$file" >"${file}.tmp"
  mv "${file}.tmp" "$file"
}

resolve_font() {
  case "${1,,}" in
    jetbrains|jb|jetbrains-mono)
      FONT_ZIP=JetBrainsMono.zip; FONT_DIR=$NERD_FONTS_ROOT/JetBrainsMono
      FONT_LABEL="JetBrains Mono Nerd Font"; FONT_FAMILY="JetBrainsMono Nerd Font"
      FONT_FC_PATTERN='jetbrains.*nerd font' ;;
    hack)
      FONT_ZIP=Hack.zip; FONT_DIR=$NERD_FONTS_ROOT/Hack
      FONT_LABEL="Hack Nerd Font"; FONT_FAMILY="Hack Nerd Font"
      FONT_FC_PATTERN='hack nerd font' ;;
    fira|firacode|fira-code)
      FONT_ZIP=FiraCode.zip; FONT_DIR=$NERD_FONTS_ROOT/FiraCode
      FONT_LABEL="Fira Code Nerd Font"; FONT_FAMILY="FiraCode Nerd Font"
      FONT_FC_PATTERN='fira code nerd font' ;;
    meslo|meslo-lg)
      FONT_ZIP=Meslo.zip; FONT_DIR=$NERD_FONTS_ROOT/Meslo
      FONT_LABEL="Meslo Nerd Font"; FONT_FAMILY="MesloLGS Nerd Font"
      FONT_FC_PATTERN='meslo.*nerd font' ;;
    cascadia|caskaydia)
      FONT_ZIP=CascadiaCode.zip; FONT_DIR=$NERD_FONTS_ROOT/CascadiaCode
      FONT_LABEL="Cascadia Code Nerd Font"; FONT_FAMILY="CaskaydiaCove Nerd Font"
      FONT_FC_PATTERN='caskaydia.*nerd font|cascadia.*nerd font' ;;
    dejavu)
      FONT_ZIP=DejaVuSansMono.zip; FONT_DIR=$NERD_FONTS_ROOT/DejaVuSansMono
      FONT_LABEL="DejaVu Sans Mono Nerd Font"; FONT_FAMILY="DejaVuSansMono Nerd Font"
      FONT_FC_PATTERN='dejavu sans mono nerd font' ;;
    ubuntu)
      FONT_ZIP=UbuntuMono.zip; FONT_DIR=$NERD_FONTS_ROOT/UbuntuMono
      FONT_LABEL="Ubuntu Mono Nerd Font"; FONT_FAMILY="Ubuntu Mono Nerd Font"
      FONT_FC_PATTERN='ubuntu mono nerd font' ;;
    *) die "unknown font '$1'" ;;
  esac
}

font_installed() {
  fc-list 2>/dev/null | grep -qiE "$FONT_FC_PATTERN"
}

detect_font_name() {
  local n
  if font_installed; then
    n="$(fc-list 2>/dev/null | grep -iE "$FONT_FC_PATTERN" | head -1 | sed 's/.*: \([^:]*\):.*/\1/')"
    [[ -n "$n" ]] && { echo "$n"; return; }
  fi
  for c in "$FONT_FAMILY Mono" "$FONT_FAMILY"; do
    n="$(fc-match -f '%{family}\n' "$c" 2>/dev/null | head -1)"
    [[ -n "$n" && "$n" != "DejaVu Sans Mono" && "$n" != "monospace" ]] && { echo "$n"; return; }
  done
  echo "$FONT_FAMILY"
}

palette_block() {
  if [[ "${PALETTE,,}" == latte ]]; then
    cat <<'EOF'
palette=custom
palette-background=239,241,245
palette-foreground=76,79,105
palette-black=220,224,232
palette-red=210,15,57
palette-green=64,160,43
palette-yellow=223,142,29
palette-blue=30,102,245
palette-magenta=234,118,176
palette-cyan=23,146,153
palette-light-grey=76,79,105
palette-dark-grey=140,143,161
palette-light-red=210,15,57
palette-light-green=64,160,43
palette-light-yellow=223,142,29
palette-light-blue=30,102,245
palette-light-magenta=234,118,176
palette-light-cyan=23,146,153
palette-white=76,79,105
EOF
  else
    cat <<'EOF'
palette=custom
palette-background=30,30,46
palette-foreground=205,214,244
palette-black=49,50,68
palette-red=243,139,168
palette-green=166,227,161
palette-yellow=249,226,175
palette-blue=137,180,250
palette-magenta=245,194,231
palette-cyan=148,226,213
palette-light-grey=205,214,244
palette-dark-grey=108,112,134
palette-light-red=243,139,168
palette-light-green=166,227,161
palette-light-yellow=249,226,175
palette-light-blue=137,180,250
palette-light-magenta=245,194,231
palette-light-cyan=148,226,213
palette-white=205,214,244
EOF
  fi
}

ensure_backports() {
  local cn suite file line
  cn="$(codename)"
  suite="${cn}-backports"
  if apt-cache policy kmscon 2>/dev/null | grep -qE 'Candidate: [0-9]'; then
    return 0
  fi
  file="/etc/apt/sources.list.d/${cn}-backports.list"
  line="deb http://deb.debian.org/debian ${suite} main"
  log "Adding ${suite} apt source..."
  if [[ ! -f "$file" ]]; then
    printf '%s\n' "$line" >"$file"
  elif ! grep -qF "$suite" "$file"; then
    printf '%s\n' "$line" >>"$file"
  fi
  apt-get update -qq
}

install_apt_base() {
  log "Installing apt packages..."
  local pkgs=(
    python3 python3-venv python3-pip git curl ca-certificates unzip
    fontconfig libfontconfig1 libpango-1.0-0 libpangocairo-1.0-0
  )
  [[ "${NERD_FONT,,}" == hack ]] && pkgs+=(fonts-hack)
  apt-get update -qq
  apt-get install -y --no-install-recommends "${pkgs[@]}"
}

install_kmscon_pkg() {
  local cn suite
  cn="$(codename)"
  suite="${cn}-backports"
  log "Installing kmscon..."
  if apt-cache policy kmscon 2>/dev/null | grep -q "$suite"; then
    apt-get install -y --no-install-recommends -t "$suite" kmscon
  else
    apt-get install -y --no-install-recommends kmscon 2>/dev/null \
      || apt-get install -y --no-install-recommends -t "$suite" kmscon
  fi
}

install_nerd_font() {
  if font_installed; then
    log "$FONT_LABEL already installed"
    return 0
  fi
  log "Downloading $FONT_LABEL..."
  local tmp="${TMPDIR:-/tmp}/zbox-font.$$" url
  url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/${FONT_ZIP}"
  mkdir -p "$tmp" "$FONT_DIR"
  if ! curl -fsSL -o "$tmp/${FONT_ZIP}" "$url"; then
    warn "font download failed; using system monospace"
    rm -rf "$tmp"
    return 0
  fi
  unzip -qo "$tmp/${FONT_ZIP}" -d "$FONT_DIR" || warn "font unpack failed"
  rm -rf "$tmp"
  fc-cache -f 2>/dev/null || true
}

write_kmscon_conf() {
  local font_name="$1" pal
  pal="$(palette_block)"
  log "Writing ${KMSCON_CONF} (${font_name}, ${FONT_SIZE}pt, ${PALETTE})"
  install -d -m 0755 /etc/kmscon
  if [[ -f "$KMSCON_CONF" ]] && ! grep -qF "$CONSOLE_MARKER_BEGIN" "$KMSCON_CONF"; then
    cp -a "$KMSCON_CONF" "${KMSCON_CONF}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  strip_conf_block "$KMSCON_CONF" "$CONSOLE_MARKER_BEGIN" "$CONSOLE_MARKER_END"
  tee -a "$KMSCON_CONF" >/dev/null <<EOF
${CONSOLE_MARKER_BEGIN}
term=xterm-256color
font-engine=pango
font-name=${font_name}
font-size=${FONT_SIZE}
font-dpi=96
${pal}
session-max=12
session-control
switchvt
mouse
hwaccel
drm
gpus=all
${CONSOLE_MARKER_END}
EOF
}

append_zboxtui_kmscon_snippet() {
  strip_conf_block "$KMSCON_CONF" "$ZBOXTUI_MARKER_BEGIN" "$ZBOXTUI_MARKER_END"
  tee -a "$KMSCON_CONF" >/dev/null <<EOF
${ZBOXTUI_MARKER_BEGIN}
login=/usr/lib/zboxtui/zboxtui-console-login
term=xterm-256color
${ZBOXTUI_MARKER_END}
EOF
}

fetch_zboxtui() {
  log "Fetching zBoxTUI (${ZBOXTUI_GIT_URL} @ ${ZBOXTUI_GIT_REF})..."
  rm -rf "$BUILD_DIR"
  git clone --depth 1 --branch "$ZBOXTUI_GIT_REF" "$ZBOXTUI_GIT_URL" "$BUILD_DIR"
}

install_zboxtui_venv() {
  local src="$1"
  local venv_python="${VENV_DIR}/bin/python"
  log "Installing zBoxTUI into ${VENV_DIR} (pip from ${src})"
  install -d -m 0755 "$(dirname "$VENV_DIR")"
  [[ -x "$venv_python" ]] || python3 -m venv "$VENV_DIR"
  "${VENV_DIR}/bin/pip" install --upgrade pip
  "${VENV_DIR}/bin/pip" install "$src"
  [[ -x "${VENV_DIR}/bin/zboxtui" ]] || die "venv missing zboxtui binary"
  install -d -m 0755 "$(dirname "$ZBOXTUI_BIN")"
  ln -sf "${VENV_DIR}/bin/zboxtui" "$ZBOXTUI_BIN"
}

install_zboxtui_config() {
  [[ -f "${BUILD_DIR}/packaging/app.conf.sample" ]] \
    || die "missing ${BUILD_DIR}/packaging/ from git clone"
  log "Installing /etc/zboxtui and logrotate"
  install -d -m 0755 /etc/zboxtui /var/log
  [[ -f /etc/zboxtui/app.conf ]] \
    || install -m 0644 "${BUILD_DIR}/packaging/app.conf.sample" /etc/zboxtui/app.conf
  install -m 0644 "${BUILD_DIR}/packaging/zboxtui.logrotate" /etc/logrotate.d/zboxtui
  touch /var/log/zboxtui.log
  chmod 0644 /var/log/zboxtui.log
}

install_console_wrappers() {
  log "Installing console wrappers in ${LIB_DIR}"
  install -d -m 0755 "$LIB_DIR"
  tee "${LIB_DIR}/zboxtui-console-login" >/dev/null <<'EOF'
#!/bin/sh
# kmscon login on tty1 — no interactive shell without zBoxTUI.
set -eu
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export COLORTERM=truecolor
export TERM="${TERM:-xterm-256color}"
ZBOXTUI_BIN="${ZBOXTUI_BIN:-/usr/local/bin/zboxtui}"
if ! [ -x "$ZBOXTUI_BIN" ]; then
    exec sleep infinity
fi
exec /usr/lib/zboxtui/zboxtui-console-loop
EOF
  chmod 0755 "${LIB_DIR}/zboxtui-console-login"
  tee "${LIB_DIR}/zboxtui-console-loop" >/dev/null <<'EOF'
#!/bin/bash
set -u
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export COLORTERM="${COLORTERM:-truecolor}"
export TERM="${TERM:-xterm-256color}"
ZBOXTUI_BIN="${ZBOXTUI_BIN:-/usr/local/bin/zboxtui}"
while true; do
    [ -x "$ZBOXTUI_BIN" ] || exec sleep infinity
    "$ZBOXTUI_BIN" || true
    sleep 1
done
EOF
  chmod 0755 "${LIB_DIR}/zboxtui-console-loop"
}

install_profile_colorterm() {
  install -d -m 0755 /etc/profile.d
  tee /etc/profile.d/zz-zboxtui-kmscon-colorterm.sh >/dev/null <<'EOF'
# Interactive kmscon shells (zsh on tty2). tty1 login skips profile.d.
if [ -n "${KMSCON_SESSION:-}" ] || [ "${COLORTERM:-}" = "kmscon" ]; then
    export COLORTERM=truecolor
    export TERM="${TERM:-xterm-256color}"
fi
EOF
  chmod 0644 /etc/profile.d/zz-zboxtui-kmscon-colorterm.sh
}

write_kmscon_dropin() {
  local dropin="$1"
  install -d -m 0755 "$(dirname "$dropin")"
  tee "$dropin" >/dev/null <<'EOF'
[Service]
Environment=COLORTERM=truecolor
Environment=TERM=xterm-256color
ExecStart=
ExecStart=kmscon --vt=%I --seats=seat0 --no-switchvt --login -- /usr/lib/zboxtui/zboxtui-console-login
EOF
  chmod 0644 "$dropin"
}

write_kmscon_color_dropin() {
  local dropin="$1"
  install -d -m 0755 "$(dirname "$dropin")"
  tee "$dropin" >/dev/null <<'EOF'
[Service]
Environment=COLORTERM=truecolor
Environment=TERM=xterm-256color
EOF
  chmod 0644 "$dropin"
}

# Undo kmscon package "all VTs" autovt link; keep tty3–tty6 on stock getty.
prepare_kmscon_systemd() {
  [[ -L /etc/systemd/system/autovt@.service ]] && rm -f /etc/systemd/system/autovt@.service
  systemctl disable kmsconvt@.service 2>/dev/null || true
}

# Enable kmscon on a VT. tty1 gets zBoxTUI drop-in; tty2 keeps Debian agetty under kmscon.
enable_kmscon_tty() {
  local tty="$1"
  local zboxtui="${2:-0}"
  local dropin_dir="/etc/systemd/system/kmsconvt@${tty}.service.d"
  local autovt="/etc/systemd/system/autovt@${tty}.service"
  log "Enabling kmscon on ${tty} (zboxtui=${zboxtui})"
  systemctl stop "getty@${tty}.service" 2>/dev/null || true
  systemctl disable "getty@${tty}.service" 2>/dev/null || true
  systemctl mask "getty@${tty}.service" 2>/dev/null || true
  systemctl enable "kmsconvt@${tty}.service"
  ln -sf /usr/lib/systemd/system/kmsconvt@.service "$autovt"
  rm -f "${dropin_dir}/zboxtui-login.conf" "${dropin_dir}/kmscon-color.conf"
  if [[ "$zboxtui" -eq 1 ]]; then
    write_kmscon_dropin "${dropin_dir}/zboxtui-login.conf"
  else
    write_kmscon_color_dropin "${dropin_dir}/kmscon-color.conf"
  fi
}

write_boot_vt() {
  log "First-boot console VT: ${TTY_ZBOXTUI}"
  install -d -m 0755 /etc/zbox
  echo "${TTY_ZBOXTUI#tty}" >"$BOOT_VT_CONF"
}

restart_kmscon_sessions() {
  [[ "$SKIP_KMSCON_RESTART" -eq 1 ]] && {
    log "Skipping kmscon restart (Packer build VM)"
    return 0
  }
  systemctl daemon-reload
  systemctl restart "kmsconvt@${TTY_ZBOXTUI}.service" 2>/dev/null || true
  systemctl restart "kmsconvt@${TTY_KMSCON}.service" 2>/dev/null || true
}


restore_getty_all() {
  local n tty
  prepare_kmscon_systemd
  for n in 1 2 3 4 5 6; do
    tty="tty${n}"
    rm -f "/etc/systemd/system/autovt@${tty}.service"
    systemctl stop "kmsconvt@${tty}.service" 2>/dev/null || true
    systemctl disable "kmsconvt@${tty}.service" 2>/dev/null || true
    rm -f \
      "/etc/systemd/system/kmsconvt@${tty}.service.d/zboxtui-login.conf" \
      "/etc/systemd/system/kmsconvt@${tty}.service.d/kmscon-color.conf"
    rmdir "/etc/systemd/system/kmsconvt@${tty}.service.d" 2>/dev/null || true
    systemctl unmask "getty@${tty}.service" 2>/dev/null || true
    systemctl enable "getty@${tty}.service" 2>/dev/null || true
    systemctl restart "getty@${tty}.service" 2>/dev/null || true
  done
  systemctl daemon-reload
}

# True once the software (kmscon + zBoxTUI venv) is present, regardless of console wiring.
software_installed() {
  [[ -x "$ZBOXTUI_BIN" ]] && command -v kmscon >/dev/null 2>&1
}

# Installs kmscon + zBoxTUI (apt, fonts, git clone, venv). Does not touch console wiring.
install_software() {
  log "font=${NERD_FONT} size=${FONT_SIZE} palette=${PALETTE}"

  resolve_font "$NERD_FONT"
  ensure_backports
  install_apt_base
  command -v kmscon >/dev/null 2>&1 || install_kmscon_pkg
  # Undo kmscon package's own "all VTs" autovt default; getty stays in charge
  # of every VT until an explicit --enable wires tty1/tty2.
  prepare_kmscon_systemd
  install_nerd_font

  local font_name
  font_name="$(detect_font_name)"
  write_kmscon_conf "$font_name"

  fetch_zboxtui
  install_zboxtui_venv "$BUILD_DIR"
  install_zboxtui_config
  install_console_wrappers
  append_zboxtui_kmscon_snippet
  install_profile_colorterm

  log "Removing build tree ${BUILD_DIR}"
  rm -rf "$BUILD_DIR"
}

# Wires tty1 (zBoxTUI) + tty2 (kmscon shell); assumes the software is already installed.
wire_console() {
  prepare_kmscon_systemd
  enable_kmscon_tty "$TTY_KMSCON" 0
  enable_kmscon_tty "$TTY_ZBOXTUI" 1
  systemctl daemon-reload
  write_boot_vt
  restart_kmscon_sessions
}

cmd_install() {
  log "=== install: kmscon + zBoxTUI software (console left on stock getty) ==="
  if software_installed; then
    log "Already installed; nothing to do."
  else
    install_software
  fi
  log "Done. Console left on stock getty."
  echo "  Enable:   sudo /sbin/zbox-zboxtui-setup.sh --enable"
}

cmd_enable() {
  log "=== enable: kmscon ${TTY_ZBOXTUI}+${TTY_KMSCON}, zBoxTUI on ${TTY_ZBOXTUI} ==="

  if software_installed; then
    log "zBoxTUI + kmscon already installed; wiring consoles only"
  else
    install_software
  fi

  wire_console

  log "Done."
  echo "  zBoxTUI:  Ctrl+Alt+F1 (${TTY_ZBOXTUI})"
  echo "  kmscon:  Ctrl+Alt+F2 (${TTY_KMSCON}, login shell)"
  echo "  Revert:   sudo /sbin/zbox-zboxtui-setup.sh --disable"
}

cmd_disable() {
  log "=== disable: revert to stock agetty, remove zBoxTUI/kmscon ==="

  restore_getty_all
  strip_conf_block "$KMSCON_CONF" "$CONSOLE_MARKER_BEGIN" "$CONSOLE_MARKER_END"
  strip_conf_block "$KMSCON_CONF" "$ZBOXTUI_MARKER_BEGIN" "$ZBOXTUI_MARKER_END"
  rm -f /etc/profile.d/zz-zboxtui-kmscon-colorterm.sh
  rm -f "$BOOT_VT_CONF"
  rm -f /etc/logrotate.d/zboxtui /var/log/zboxtui.log
  rm -rf /etc/zboxtui /opt/zboxtui /usr/lib/zboxtui /usr/share/zboxtui
  rm -f "$ZBOXTUI_BIN"
  rm -rf "$BUILD_DIR"

  log "Purging kmscon..."
  apt-get purge -y kmscon 2>/dev/null || true
  apt-get autoremove -y --purge 2>/dev/null || apt-get autoremove -y || true

  log "Done. tty1–tty6 use stock getty. Nerd fonts remain under ${NERD_FONTS_ROOT}."
}

# --- main ---
parse_args "$@"

if [[ "$DO_INSTALL" -eq 1 ]]; then
  cmd_install
elif [[ "$DO_ENABLE" -eq 1 ]]; then
  cmd_enable
else
  cmd_disable
fi
