if status is-interactive
    starship init fish | source
end

# Docker Desktop CLI (macOS)
if test -d /Applications/Docker.app/Contents/Resources/bin
    fish_add_path /Applications/Docker.app/Contents/Resources/bin
end
