# does the quickest output of brew --prefix possible for the basic cases:
# - `brew --prefix` (output HOMEBREW_PREFIX)
# - `brew --prefix <formula>` (output HOMEBREW_PREFIX/opt/<formula>)
# anything else? delegate to the slower cmd/--prefix.rb
# HOMEBREW_PREFIX and HOMEBREW_REPOSITORY are set by brew.sh
# shellcheck disable=SC2154
homebrew-prefix() {
  while [[ "$#" -gt 0 ]]
  do
    case "$1" in
      # check we actually have --prefix and not e.g. --prefixsomething
      --prefix)
        local prefix="1"
        shift
        ;;
      # reject all other flags
      -*) return 1 ;;
      *)
        [[ -n "${formula}" ]] && return 1
        local formula="$1"
        shift
        ;;
    esac
  done
  [[ -z "${prefix}" ]] && return 1
  [[ -z "${formula}" ]] && echo "${HOMEBREW_PREFIX}" && return 0

  local formula_exists
  if [[ -f "${HOMEBREW_REPOSITORY}/Library/Taps/homebrew/homebrew-core/Formula/${formula}.rb" ]]
  then
    formula_exists="1"
  else
    local formula_path
    formula_path="$(
      shopt -s nullglob
      echo "${HOMEBREW_REPOSITORY}/Library/Taps"/*/*/{Formula/,HomebrewFormula/,}"${formula}.rb"
    )"
    [[ -n "${formula_path}" ]] && formula_exists="1"
  fi

  if [[ -z "${formula_exists}" &&
        -z "${HOMEBREW_NO_INSTALL_FROM_API}" ]]
  then
    if [[ -f "${HOMEBREW_CACHE}/api/formula_names.txt" ]] &&
       grep -Fxq "${formula}" "${HOMEBREW_CACHE}/api/formula_names.txt"
    then
      formula_exists="1"
    elif [[ -f "${HOMEBREW_CACHE}/api/formula_aliases.txt" ]]
    then
      while IFS="|" read -r alias_name real_name
      do
        case "${alias_name}" in
          "${formula}")
            formula_exists="1"
            formula="${real_name}"
            break
            ;;
          *) ;;
        esac
      done <"${HOMEBREW_CACHE}/api/formula_aliases.txt"
    fi
  fi

  [[ -z "${formula_exists}" ]] && return 1

  echo "${HOMEBREW_PREFIX}/opt/${formula}"
  return 0
}
