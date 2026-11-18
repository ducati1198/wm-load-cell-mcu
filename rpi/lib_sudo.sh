# Ask for the sudo password ONE time and keep it valid until the script that called this ends,
# so the steps (stop Klipper, flash, start Klipper) never ask again. Sourced by the other scripts.
ask_sudo() {
  [ "${WM_SUDO_OK:-0}" = "1" ] && return 0
  if [ "$(id -u)" != "0" ] && ! sudo -n true 2>/dev/null; then
    echo "The password of this user is needed once (to stop and start Klipper). It is asked only this one time."
    sudo -v || { echo "STOP: no sudo rights, nothing was changed."; exit 1; }
  fi
  export WM_SUDO_OK=1
  # keep the sudo ticket alive while this script runs; ends by itself when the script ends
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 40; done ) >/dev/null 2>&1 &
}
