fish_add_path ~/.local/bin

if status is-interactive
    starship init fish | source
end
