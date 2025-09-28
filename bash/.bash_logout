# ~/.bash_logout: executed by bash(1) when login shell exits

# When leaving the console, clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
    if [ -x /usr/bin/clear_console ]; then
      /usr/bin/clear_console -q  # Seems to be ubuntu only
    else
      /usr/bin/clear
    fi
fi

# The user's exit code is automatically preserved
