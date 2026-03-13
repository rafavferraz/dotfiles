set -gx GOPATH $HOME/go
fish_add_path ~/.local/bin $GOPATH/bin

if status is-interactive
    starship init fish | source
end
