#!/bin/sh
# Re-assert extended (non-mirrored) layout after login; kscreen's kded module
# has sometimes restored both outputs at +0+0 (duplicate). Harmless if already correct.
sleep 8
kscreen-doctor output.eDP-1.position.0,0 output.HDMI-1-0.position.1920,0 >/dev/null 2>&1
