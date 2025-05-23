if status is-interactive
  # Commands to run in interactive sessions can go here

  # Use vim bindings
  fish_vi_key_bindings

  # Add local executables to path
  set -U fish_user_paths ~/.local/bin
  set -Ux EDITOR nvim

  # This should be set by libelf in /etc/profile.d, but it seems like fish was
  # overlooked. Those scripts use the contents of
  # /etc/debuginfod/archlinux.urls, but there's just the one server currently,
  # so we set it manually:
  set -Ux DEBUGINFOD_URLS https://debuginfod.archlinux.org
end

# Accept autosuggestions in a sane way
function fish_user_key_bindings
  bind -M insert \cE forward-char
end

# Turn off greeting
function fish_greeting
end

function y
  #set cwdtmp (mktemp -ut "yazi-cwd.XXXXX")
  set filetmp (mktemp -ut "yazi-file.XXXXX")
  #yazi $argv --cwd-file="$cwdtmp" --chooser-file="$filetmp"
	yazi $argv --chooser-file="$filetmp"
  #if set cwd (cat -- "$cwdtmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
	#	cd -- "$cwd"
	#end
  if test -e "$filetmp"
    cat "$filetmp" | zim
  end
  #rm -f -- "$cwdtmp"
  rm -f -- "$filetmp"
end

function ya
  env EDITOR=zim yazi
end
