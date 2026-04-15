_encode_rips_completions() {
  local current previous
  current="${COMP_WORDS[COMP_CWORD]}"
  previous="${COMP_WORDS[COMP_CWORD-1]}"

  local flags="--input-dir --output-dir --help --dvd --dark-scenes --cartoon --grainy --quality --crf --wait --verbose"

  case "$previous" in
    -i|--input-dir|-o|--output-dir)
      COMPREPLY=($(compgen -d -- "$current"))
      return ;;
    -q|--quality)
      COMPREPLY=($(compgen -W "low medium high extra-high" -- "$current"))
      return ;;
    --crf)
      COMPREPLY=($(compgen -W "16 17 18 19 20 21 22 23 24 25 26" -- "$current"))
      return ;;
    -w|--wait)
      COMPREPLY=($(compgen -W "30 60 120 180 300 600" -- "$current"))
      return ;;
  esac

  COMPREPLY=($(compgen -W "$flags" -- "$current"))
}

complete -F _encode_rips_completions encode_rips.sh