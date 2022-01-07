# Adapted from liquidprompt

# LP_OS detection, default to Linux
case $(uname) in
    FreeBSD)   LP_OS=FreeBSD ;;
    DragonFly) LP_OS=FreeBSD ;;
    OpenBSD)   LP_OS=OpenBSD ;;
    Darwin)    LP_OS=Darwin  ;;
    SunOS)     LP_OS=SunOS   ;;
    *)         LP_OS=Linux   ;;
esac

# do not load if not an interactive shell
test -z "$TERM" -o "x$TERM" = xdumb && return

_LP_OPEN_ESC="%{"
_LP_CLOSE_ESC="%}"
_LP_USER_SYMBOL="%n"
_LP_HOST_SYMBOL="%m"
_LP_TIME_SYMBOL="%t"
_LP_MARK_SYMBOL='%(!.#.%%)'
_LP_PERCENT='%%'
_LP_PWD_SYMBOL="%~"

# Store $2 (or $?) as a true/false value in variable named $1
# $? is propagated
#   _lp_bool foo 5
#   => foo=false
#   _lp_bool foo 0
#   => foo=true
_lp_bool()
{
    local res=${2:-$?}
    if [[ $res = 0 ]]; then
        eval $1=true
    else
        eval $1=false
    fi
    return $res
}

# Save $IFS as we want to restore the default value at the beginning of the
# prompt function
_LP_IFS="$IFS"

# Extended regexp patterns for sed
# GNU/BSD sed
_LP_SED_EXTENDED=r
[[ "$LP_OS" = Darwin ]] && _LP_SED_EXTENDED=E

# Reset so all PWD dependent variables are computed after loading
unset LP_OLD_PWD

#################
# CONFIGURATION #
#################

# The following code is run just once. But it is encapsulated in a function
# to benefit of 'local' variables.
#
# What we do here:
# 1. Setup variables that can be used by the user: the "API" of Liquid Prompt
#    for config/theme. Those variables are local to the function.
#    In practice, this is only color variables.
# 2. Setup default values
# 3. Load the configuration
_lp_source_config()
{
    # TermInfo feature detection
    local ti_sgr0="$( { tput sgr0 || tput me ; } 2>/dev/null )"
    local ti_bold="$( { tput bold || tput md ; } 2>/dev/null )"
    local ti_setaf
    local ti_setab
    if tput setaf 0 >/dev/null 2>&1; then
        ti_setaf() { tput setaf "$1" ; }
    elif tput AF 0 >/dev/null 2>&1; then
        # FreeBSD
        ti_setaf() { tput AF "$1" ; }
    elif tput AF 0 0 0 >/dev/null 2>&1; then
        # OpenBSD
        ti_setaf() { tput AF "$1" 0 0 ; }
    else
        echo "liquidprompt: terminal $TERM not supported" >&2
        ti_setaf () { : ; }
    fi
    if tput setab 0 >/dev/null 2>&1; then
        ti_setab() { tput setab "$1" ; }
    elif tput AB 0 >/dev/null 2>&1; then
        # FreeBSD
        ti_setab() { tput AB "$1" ; }
    elif tput AB 0 0 0 >/dev/null 2>&1; then
        # OpenBSD
        ti_setab() { tput AB "$1" 0 0 ; }
    else
        echo "liquidprompt: terminal $TERM not supported" >&2
        ti_setab() { : ; }
    fi

    # Colors: variables are local so they will have a value only
    # during config loading and will not conflict with other values
    # with the same names defined by the user outside the config.
    local BOLD="${_LP_OPEN_ESC}${ti_bold}${_LP_CLOSE_ESC}"

    local BLACK="${_LP_OPEN_ESC}$(ti_setaf 0)${_LP_CLOSE_ESC}"
    local BOLD_GRAY="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 0)${_LP_CLOSE_ESC}"
    local WHITE="${_LP_OPEN_ESC}$(ti_setaf 7)${_LP_CLOSE_ESC}"
    local BOLD_WHITE="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 7)${_LP_CLOSE_ESC}"

    local RED="${_LP_OPEN_ESC}$(ti_setaf 1)${_LP_CLOSE_ESC}"
    local BOLD_RED="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 1)${_LP_CLOSE_ESC}"
    local WARN_RED="${_LP_OPEN_ESC}$(ti_setaf 0 ; ti_setab 1)${_LP_CLOSE_ESC}"
    local CRIT_RED="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 7 ; ti_setab 1)${_LP_CLOSE_ESC}"
    local DANGER_RED="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 3 ; ti_setab 1)${_LP_CLOSE_ESC}"

    local GREEN="${_LP_OPEN_ESC}$(ti_setaf 2)${_LP_CLOSE_ESC}"
    local BOLD_GREEN="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 2)${_LP_CLOSE_ESC}"

    local YELLOW="${_LP_OPEN_ESC}$(ti_setaf 3)${_LP_CLOSE_ESC}"
    local BOLD_YELLOW="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 3)${_LP_CLOSE_ESC}"

    local BLUE="${_LP_OPEN_ESC}$(ti_setaf 4)${_LP_CLOSE_ESC}"
    local BOLD_BLUE="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 4)${_LP_CLOSE_ESC}"

    local PURPLE="${_LP_OPEN_ESC}$(ti_setaf 5)${_LP_CLOSE_ESC}"
    local PINK="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 5)${_LP_CLOSE_ESC}"

    local CYAN="${_LP_OPEN_ESC}$(ti_setaf 6)${_LP_CLOSE_ESC}"
    local BOLD_CYAN="${_LP_OPEN_ESC}${ti_bold}$(ti_setaf 6)${_LP_CLOSE_ESC}"

    # NO_COL is special: it will be used at runtime, not just during config loading
    NO_COL="${_LP_OPEN_ESC}${ti_sgr0}${_LP_CLOSE_ESC}"

    # compute the hash of the hostname
    # and get the corresponding number in [1-6] (red,green,yellow,blue,purple or cyan)
    # FIXME check portability of cksum and add more formats (bold? 256 colors?)
    local hash=$(( 1 + $(hostname | cksum | cut -d " " -f 1) % 6 ))
    LP_COLOR_HOST_HASH="${_LP_OPEN_ESC}$(ti_setaf $hash)${_LP_CLOSE_ESC}"

    unset ti_sgr0 ti_bold ti_setaf ti_setab

    # TODO: remove options

    # Default values (globals)
    LP_BATTERY_THRESHOLD=25
    LP_PATH_LENGTH=35
    LP_PATH_KEEP=2
    LP_PATH_DEFAULT="$_LP_PWD_SYMBOL"
    LP_HOSTNAME_ALWAYS=0
    LP_USER_ALWAYS=0
    LP_PERCENTS_ALWAYS=1
    LP_PS1=""
    LP_PS1_PREFIX=""
    LP_PS1_POSTFIX=" ❯ "
    LP_TITLE_OPEN="\e]0;"
    LP_TITLE_CLOSE="\a"
    LP_SCREEN_TITLE_OPEN="\033k"
    LP_SCREEN_TITLE_CLOSE="\033\134"

    LP_ENABLE_PERM=1
    LP_ENABLE_SHORTEN_PATH=-1
    LP_ENABLE_PROXY=1
    LP_ENABLE_JOBS=1
    LP_ENABLE_BATT=1
    LP_ENABLE_TIME=1
    # TODO: RVM too
    LP_ENABLE_VIRTUALENV=1
    LP_ENABLE_SCLS=1
    LP_ENABLE_VCS_ROOT=0
    LP_ENABLE_TITLE=0
    LP_ENABLE_SCREEN_TITLE=0
    LP_ENABLE_SSH_COLORS=1

    # TODO: better icons, especially for git
    LP_MARK_DEFAULT="$_LP_MARK_SYMBOL"
    LP_MARK_BATTERY="⌁"
    LP_MARK_ADAPTER="⏚"
    LP_MARK_PROXY="↥"
    LP_MARK_DISABLED="⌀"
    LP_MARK_UNTRACKED="*"
    LP_MARK_STASH="+"
    LP_MARK_BRACKET_OPEN="["
    LP_MARK_BRACKET_CLOSE="]"
    LP_MARK_SHORTEN_PATH=" … "

    # TODO figure out indicators/colors for tmux, x11
    # TODO better colors, especially for git
    LP_COLOR_PATH=$WHITE
    LP_COLOR_PATH_ROOT=$YELLOW
    LP_COLOR_PROXY=$BLUE
    LP_COLOR_JOB_D=$YELLOW
    LP_COLOR_JOB_R=$BOLD_YELLOW
    LP_COLOR_JOB_Z=$BOLD_YELLOW
    LP_COLOR_ERR=$RED
    LP_COLOR_MARK=$WHITE
    LP_COLOR_MARK_ROOT=$RED
    LP_COLOR_USER_LOGGED=""
    LP_COLOR_USER_ALT=$WHITE
    LP_COLOR_USER_ROOT=$YELLOW
    LP_COLOR_HOST=""
    LP_COLOR_SSH=$BLUE
    LP_COLOR_SU=$BOLD_YELLOW
    LP_COLOR_TELNET=$WARN_RED
    LP_COLOR_X11_ON=$GREEN
    LP_COLOR_X11_OFF=$YELLOW
    LP_COLOR_WRITE=$GREEN
    LP_COLOR_NOWRITE=$RED
    LP_COLOR_UP=$GREEN
    LP_COLOR_COMMITS=$YELLOW
    LP_COLOR_CHANGES=$RED
    LP_COLOR_DIFF=$PURPLE
    LP_COLOR_CHARGING_ABOVE=$GREEN
    LP_COLOR_CHARGING_UNDER=$YELLOW
    LP_COLOR_DISCHARGING_ABOVE=$YELLOW
    LP_COLOR_DISCHARGING_UNDER=$RED
    LP_COLOR_TIME=$FG[238]
    LP_COLOR_IN_MULTIPLEXER=$BLUE
    LP_COLOR_VIRTUALENV=$CYAN

    LP_COLORMAP_0=""
    LP_COLORMAP_1=$GREEN
    LP_COLORMAP_2=$BOLD_GREEN
    LP_COLORMAP_3=$YELLOW
    LP_COLORMAP_4=$BOLD_YELLOW
    LP_COLORMAP_5=$RED
    LP_COLORMAP_6=$BOLD_RED
    LP_COLORMAP_7=$WARN_RED
    LP_COLORMAP_8=$CRIT_RED
    LP_COLORMAP_9=$DANGER_RED
}

# do source config files
_lp_source_config
unset _lp_source_config

case "$LP_OS" in
    Darwin) [[ "$LP_ENABLE_BATT" = 1 ]] && { command -v pmset >/dev/null || LP_ENABLE_BATT=0 ; };;
    *)      [[ "$LP_ENABLE_BATT" = 1 ]] && { command -v acpi >/dev/null || LP_ENABLE_BATT=0 ; };;
esac

command -v screen >/dev/null ; _lp_bool _LP_ENABLE_SCREEN $?
command -v tmux >/dev/null   ; _lp_bool _LP_ENABLE_TMUX $?

# If we are running in a terminal multiplexer, brackets are colored
# TODO: some other icon for multiplexer
if [[ "$TERM" == screen* ]]; then
    LP_BRACKET_OPEN="${LP_COLOR_IN_MULTIPLEXER}${LP_MARK_BRACKET_OPEN}${NO_COL}"
    LP_BRACKET_CLOSE="${LP_COLOR_IN_MULTIPLEXER}${LP_MARK_BRACKET_CLOSE}${NO_COL}"
    (( LP_ENABLE_TITLE = LP_ENABLE_TITLE && LP_ENABLE_SCREEN_TITLE ))
    LP_TITLE_OPEN="$LP_SCREEN_TITLE_OPEN"
    LP_TITLE_CLOSE="$LP_SCREEN_TITLE_CLOSE"
else
    LP_BRACKET_OPEN="${LP_MARK_BRACKET_OPEN}"
    LP_BRACKET_CLOSE="${LP_MARK_BRACKET_CLOSE}"
fi

[[ "_$TERM" == _linux* ]] && LP_ENABLE_TITLE=0

# update_terminal_cwd is a shell function available on MacOS X Lion that
# will update an icon of the directory displayed in the title of the terminal
# window.
# See http://hints.macworld.com/article.php?story=20110722211753852
if [[ "$TERM_PROGRAM" == Apple_Terminal ]] && command -v update_terminal_cwd >/dev/null; then
    _LP_TERM_UPDATE_DIR=update_terminal_cwd
    # Remove "update_terminal_cwd; " that has been add by Apple in /et/bashrc.
    # See issue #196
    PROMPT_COMMAND="${PROMPT_COMMAND//update_terminal_cwd; /}"
else
    _LP_TERM_UPDATE_DIR=:
fi

# Escape the given strings
# Must be used for all strings that may comes from remote sources,
# like VCS branch names
_lp_escape()
{
    printf "%q" "$*"
}

###############
# Who are we? #
###############

# Yellow for root, bold if the user is not the login one, else no color.
if [[ "$EUID" -ne "0" ]] ; then  # if user is not root
    # if user is not login user
    if [[ ${USER} != "$(logname 2>/dev/null || echo "$LOGNAME")" ]]; then
        LP_USER="${LP_COLOR_USER_ALT}${_LP_USER_SYMBOL}${NO_COL}"
    else
        if [[ "${LP_USER_ALWAYS}" -ne "0" ]] ; then
            LP_USER="${LP_COLOR_USER_LOGGED}${_LP_USER_SYMBOL}${NO_COL}"
        else
            LP_USER=""
        fi
    fi
else # root!
    LP_USER="${LP_COLOR_USER_ROOT}${_LP_USER_SYMBOL}${NO_COL}"
    LP_COLOR_MARK="${LP_COLOR_MARK_ROOT}"
    LP_COLOR_PATH="${LP_COLOR_PATH_ROOT}"
    # Disable VCS info for all paths
    if [[ "$LP_ENABLE_VCS_ROOT" != 1 ]]; then
        LP_DISABLED_VCS_PATH=/
        LP_MARK_DISABLED="$_LP_MARK_SYMBOL"
    fi
fi


#################
# Where are we? #
#################

_lp_connection()
{
    if [[ -n "$SSH_CLIENT$SSH2_CLIENT$SSH_TTY" ]] ; then
        echo ssh
    else
        # TODO check on *BSD
        local sess_src="$(who am i | sed -n 's/.*(\(.*\))/\1/p')"
        local sess_parent="$(ps -o comm= -p $PPID 2> /dev/null)"
        if [[ -z "$sess_src" || "$sess_src" = ":"* ]] ; then
            echo lcl  # Local
        elif [[ "$sess_parent" = "su" || "$sess_parent" = "sudo" ]] ; then
            echo su   # Remote su/sudo
        else
            echo tel  # Telnet
        fi
    fi
}

# Put the hostname if not locally connected
# color it in cyan within SSH, and a warning red if within telnet
# else display the host without color
# The connection is not expected to change from inside the shell, so we
# build this just once
LP_HOST=""
[[ -r /etc/debian_chroot ]] && LP_HOST="($(< /etc/debian_chroot))"

# If we are connected with a X11 support
if [[ -n "$DISPLAY" ]]; then
    LP_HOST="${LP_COLOR_X11_ON}${LP_HOST}@${NO_COL}"
else
    LP_HOST="${LP_COLOR_X11_OFF}${LP_HOST}@${NO_COL}"
fi

case "$(_lp_connection)" in
lcl)
    if [[ "${LP_HOSTNAME_ALWAYS}" -eq "0" ]] ; then
        # FIXME do we want to display the chroot if local?
        LP_HOST="" # no hostname if local
    else
        LP_HOST="${LP_HOST}${LP_COLOR_HOST}${_LP_HOST_SYMBOL}${NO_COL}"
    fi
    ;;
ssh)
    # If we want a different color for each host
    [[ "$LP_ENABLE_SSH_COLORS" -eq 1 ]] && LP_COLOR_SSH="$LP_COLOR_HOST_HASH"
    LP_HOST="${LP_HOST}${LP_COLOR_SSH}${_LP_HOST_SYMBOL}${NO_COL}"
    ;;
su)
    LP_HOST="${LP_HOST}${LP_COLOR_SU}${_LP_HOST_SYMBOL}${NO_COL}"
    ;;
tel)
    LP_HOST="${LP_HOST}${LP_COLOR_TELNET}${_LP_HOST_SYMBOL}${NO_COL}"
    ;;
*)
    LP_HOST="${LP_HOST}${_LP_HOST_SYMBOL}" # defaults to no color
    ;;
esac

# Useless now, so undefine
unset _lp_connection


_lp_get_home_tilde_collapsed()
{
    local tilde="~"
    echo "${PWD/#$HOME/$tilde}"
}

# Shorten the path of the current working directory
# * Show only the current directory
# * Show as much of the cwd path as possible, if shortened display a
#   leading mark, such as ellipses, to indicate that part is missing
# * show at least LP_PATH_KEEP leading dirs and current directory
_lp_shorten_path()
{

    if [[ "$LP_ENABLE_SHORTEN_PATH" != 1 ]] ; then
        LP_PWD="$LP_PATH_DEFAULT"
        return
    fi

    local ret=""

    local p="$(_lp_get_home_tilde_collapsed)"
    local mask="${LP_MARK_SHORTEN_PATH}"
    local -i max_len=$(( ${COLUMNS:-80} * LP_PATH_LENGTH / 100 ))

    if [[ ${LP_PATH_KEEP} == -1 ]]; then
        # only show the current directory, excluding any parent dirs
        ret="${p##*/}" # discard everything up to and including the last slash
        [[ "${ret}" == "" ]] && ret="/" # if in root directory
    elif (( ${#p} <= max_len )); then
        ret="${p}"
    elif [[ ${LP_PATH_KEEP} == 0 ]]; then
        # len is over max len, show as much of the tail as is allowed
        ret="${p##*/}" # show at least complete current directory
        p="${p:0:${#p} - ${#ret}}"
        ret="${mask}${p:${#p} - (${max_len} - ${#ret} - ${#mask})}${ret}"
    else
        # len is over max len, show at least LP_PATH_KEEP leading dirs and
        # current directory
        local tmp=${p//\//}
        local -i delims=$(( ${#p} - ${#tmp} ))

        for (( dir=0; dir < LP_PATH_KEEP; dir++ )); do
            (( dir == delims )) && break

            local left="${p#*/}"
            local name="${p:0:${#p} - ${#left}}"
            p="${left}"
            ret="${ret}${name%/}/"
        done

        if (( delims <= LP_PATH_KEEP )); then
            # no dirs between LP_PATH_KEEP leading dirs and current dir
            ret="${ret}${p##*/}"
        else
            local base="${p##*/}"

            p="${p:0:${#p} - ${#base}}"

            [[ ${ret} != "/" ]] && ret="${ret%/}" # strip trailing slash

            local -i len_left=$(( max_len - ${#ret} - ${#base} - ${#mask} ))

            ret="${ret}${mask}${p:${#p} - ${len_left}}${base}"
        fi
    fi
    # Escape special chars
    LP_PWD="${ret//\%/%%}"
}

################
# Related jobs #
################

# Display the count of each if non-zero:
# - detached screens sessions and/or tmux sessions running on the host
# - attached running jobs (started with $ myjob &)
# - attached stopped jobs (suspended with Ctrl-Z)
_lp_jobcount_color()
{
    [[ "$LP_ENABLE_JOBS" != 1 ]] && return

    local m_stop="z"
    local m_run="&"
    local ret

    if $_LP_ENABLE_DETACHED_SESSIONS; then
        local -i detached=0
        $_LP_ENABLE_SCREEN && let detached=$(screen -ls 2> /dev/null | grep -c '[Dd]etach[^)]*)$')
        $_LP_ENABLE_TMUX && let detached+=$(tmux list-sessions 2> /dev/null | grep -cv 'attached')
        (( detached > 0 )) && ret="${ret}${LP_COLOR_JOB_D}${detached}d${NO_COL}"
    fi

    local running=$(( $(jobs -r | wc -l) ))
    if [[ $running != 0 ]] ; then
        [[ -n "$ret" ]] && ret="${ret}/"
        ret="${ret}${LP_COLOR_JOB_R}${running}${m_run}${NO_COL}"
    fi

    local stopped=$(( $(jobs -s | wc -l) ))
    if [[ $stopped != 0 ]] ; then
        [[ -n "$ret" ]] && ret="${ret}/"
        ret="${ret}${LP_COLOR_JOB_Z}${stopped}${m_stop}${NO_COL}"
    fi

    echo -n "$ret"
}



######################
# VCS branch display #
######################

_lp_are_vcs_enabled()
{
    [[ -z "$LP_DISABLED_VCS_PATH" ]] && return 0
    local path
    local IFS=:
    for path in $LP_DISABLED_VCS_PATH; do
        [[ "$PWD" == *"$path"* ]] && return 1
    done
    return 0
}

# GIT #

# Get the branch name of the current directory
_lp_git_branch()
{
    \git rev-parse --inside-work-tree >/dev/null 2>&1 || return

    local branch
    # Recent versions of Git support the --short option for symbolic-ref, but
    # not 1.7.9 (Ubuntu 12.04)
    if branch="$(\git symbolic-ref -q HEAD)"; then
        _lp_escape "${branch#refs/heads/}"
    else
        # In detached head state, use commit instead
        # No escape needed
        \git rev-parse --short -q HEAD
    fi
}

# Set a color depending on the branch state:
# - green if the repository is up to date
# - yellow if there is some commits not pushed
# - red * if there are changes to commit
# - + if there's a stash
_lp_git_branch_color()
{
    local branch
    branch="$(_lp_git_branch)"
    if [[ -n "$branch" ]] ; then

        local end
        end="$NO_COL"
        if LC_ALL=C \git status --porcelain 2>/dev/null | grep -Eq '^\s*[MADRC]'; then
            end="$LP_COLOR_CHANGES$LP_MARK_UNTRACKED$end"
        fi

        if [[ -n "$(\git stash list -n 1 2>/dev/null)" ]]; then
            end="$LP_COLOR_COMMITS$LP_MARK_STASH$end"
        fi

        local remote
        remote="$(\git config --get branch.${branch}.remote 2>/dev/null)"

        local -i has_commit
        local -i behind_commit
        has_commit=0
        behind_commit=0
        if [[ -n "$remote" ]]; then
            local remote_branch
            remote_branch="$(\git config --get branch.${branch}.merge)"
            if [[ -n "$remote_branch" ]]; then
                has_commit="$(\git rev-list --count ${remote_branch/refs\/heads/refs\/remotes\/$remote}..HEAD 2>/dev/null)"
                [[ -z "$has_commit" ]] && has_commit=0
                behind_commit="$(\git rev-list --count HEAD..${remote_branch/refs\/heads/refs\/remotes\/$remote} 2>/dev/null)"
                [[ -z "$behind_commit" ]] && behind_commit=0
            fi
        fi

        local ahead_behind
        ahead_behind=""
        if [[ "$has_commit" -gt "0" && "$behind_commit" -gt "0" ]]; then
            ahead_behind="+$has_commit/-$behind_commit"
        elif [[ "$has_commit" -gt "0" ]]; then
            ahead_behind="+$has_commit"
        elif [[ "$behind_commit" -gt "0" ]]; then
            ahead_behind="-$behind_commit"
        fi

        local ret
        if [[ -n "$ahead_behind" ]]; then
            # some commit(s) to push
            ret="${LP_COLOR_COMMITS}${branch}${NO_COL} (${LP_COLOR_COMMITS}$ahead_behind${NO_COL})"
        else
            ret="${LP_COLOR_UP}${branch}" # nothing to commit or push
        fi
        echo -ne "$ret$end"
    fi
}

##################
# Kubernetes     #
##################

# Get the current kubernetes context
_lp_kube_context()
{
    local context
    if type "kubectl" > /dev/null; then
        context="$(kubectl config current-context | cut -d '_' -f 4)"
        if [[ -n "$context" ]] ; then
            echo -n "${LP_COLOR_TIME}($context)${NO_COL}"
        fi
    fi
}

##################
# Battery status #
##################

# Get the battery status in percent
# returns 0 (and battery level) if battery is discharging and under threshold
# returns 1 (and battery level) if battery is discharging and above threshold
# returns 2 (and battery level) if battery is charging but under threshold
# returns 3 (and battery level) if battery is charging and above threshold
# returns 4 if no battery support
case "$LP_OS" in
    Linux)
    _lp_battery()
    {
        [[ "$LP_ENABLE_BATT" != 1 ]] && return 4
        local acpi
        acpi="$(acpi --battery 2>/dev/null)"
        # Extract the battery load value in percent
        # First, remove the beginning of the line...
        local bat="${acpi#Battery *, }"
        bat="${bat%%%*}" # remove everything starting at '%'

        if [[ -z "${bat}" ]] ; then
            # not battery level found
            return 4

        # discharging
        elif [[ "$acpi" == *"Discharging"* ]] ; then
            if [[ ${bat} -le $LP_BATTERY_THRESHOLD ]] ; then
                # under threshold
                echo -n "${bat}"
                return 0
            else
                # above threshold
                echo -n "${bat}"
                return 1
            fi

        # charging
        else
            if [[ ${bat} -le $LP_BATTERY_THRESHOLD ]] ; then
                # under threshold
                echo -n "${bat}"
                return 2
            else
                # above threshold
                echo -n "${bat}"
                return 3
            fi
        fi
    }
    ;;
    Darwin)
    _lp_battery()
    {
        [[ "$LP_ENABLE_BATT" != 1 ]] && return 4
        local pmset="$(pmset -g batt | sed -n -e '/InternalBattery/p')"
        local bat="$(cut -f2 <<<"$pmset")"
        bat="${bat%%%*}"
        case "$pmset" in
            *charged* | "")
            return 4
            ;;
            *discharging*)
            if [[ ${bat} -le $LP_BATTERY_THRESHOLD ]] ; then
                # under threshold
                echo -n "${bat}"
                return 0
            else
                # above threshold
                echo -n "${bat}"
                return 1
            fi
            ;;
            *)
            if [[ ${bat} -le $LP_BATTERY_THRESHOLD ]] ; then
                # under threshold
                echo -n "${bat}"
                return 2
            else
                # above threshold
                echo -n "${bat}"
                return 3
            fi
            ;;
        esac
    }
    ;;
esac

# Compute a gradient of background/foreground colors depending on the battery status
# Display:
# a  green   if the battery is charging    and above threshold
# a yellow   if the battery is charging    and under threshold
# a yellow   if the battery is discharging but above threshold
# a    red   if the battery is discharging and above threshold
_lp_battery_color()
{
    [[ "$LP_ENABLE_BATT" != 1 ]] && return

    local mark=$LP_MARK_BATTERY
    local chargingmark=$LP_MARK_ADAPTER
    local bat
    local ret
    bat="$(_lp_battery)"
    ret=$?

    if [[ $ret == 4 || $bat == 100 ]] ; then
        # no battery support or battery full: nothing displayed
        return
    elif [[ $ret == 3 && $bat != 100 ]] ; then
        # charging and above threshold and not 100%
        # green
        echo -ne "${LP_COLOR_CHARGING_ABOVE}$chargingmark${NO_COL}"
        return
    elif [[ $ret == 2 ]] ; then
        # charging but under threshold
        # yellow
        echo -ne "${LP_COLOR_CHARGING_UNDER}$chargingmark${NO_COL}"
        return
    elif [[ $ret == 1 ]] ; then
        # discharging but above threshold
        # yellow
        echo -ne "${LP_COLOR_DISCHARGING_ABOVE}$mark${NO_COL}"
        return

    # discharging and under threshold
    elif [[ "$bat" != "" ]] ; then
        ret="${LP_COLOR_DISCHARGING_UNDER}${mark}${NO_COL}"

        if [[ "$LP_PERCENTS_ALWAYS" -eq "1" ]]; then
            if   (( bat <=  0 )); then
                ret="${ret}${LP_COLORMAP_0}"
            elif (( bat <=  5 )); then         #  5
                ret="${ret}${LP_COLORMAP_9}"
            elif (( bat <= 10 )); then         #  5
                ret="${ret}${LP_COLORMAP_8}"
            elif (( bat <= 20 )); then         # 10
                ret="${ret}${LP_COLORMAP_7}"
            elif (( bat <= 30 )); then         # 10
                ret="${ret}${LP_COLORMAP_6}"
            elif (( bat <= 40 )); then         # 10
                ret="${ret}${LP_COLORMAP_5}"
            elif (( bat <= 50 )); then         # 10
                ret="${ret}${LP_COLORMAP_4}"
            elif (( bat <= 65 )); then         # 15
                ret="${ret}${LP_COLORMAP_3}"
            elif (( bat <= 80 )); then         # 15
                ret="${ret}${LP_COLORMAP_2}"
            elif (( bat < 100 )); then         # 20
                ret="${ret}${LP_COLORMAP_1}"
            else # >= 100
                ret="${ret}${LP_COLORMAP_0}"
            fi

            ret="${ret}${bat}$_LP_PERCENT"
        fi # LP_PERCENTS_ALWAYS
        echo -ne "${ret}${NO_COL}"
    fi # ret
}

_lp_color_map() {
    # Default scale: 0..100
    # Custom scale: 0..$2
    local -i scale value
    scale=${2:-100}
    # Transform the value to a 0..100 scale
    value=100*$1/scale
    if (( value < 50 )); then
        if (( value <  30 )); then
            if   (( value <  10 )); then
                echo -ne "${LP_COLORMAP_0}"
            elif (( value <  20 )); then
                echo -ne "${LP_COLORMAP_1}"
            else # 40..59
                echo -ne "${LP_COLORMAP_2}"
            fi
        elif (( value <  40 )); then
            echo -ne "${LP_COLORMAP_3}"
        else # 80..99
            echo -ne "${LP_COLORMAP_4}"
        fi
    elif (( value <  80 )); then
        if (( value <  60 )); then
            echo -ne "${LP_COLORMAP_5}"
        elif (( value <  70 )); then
            echo -ne "${LP_COLORMAP_6}"
        else
            echo -ne "${LP_COLORMAP_7}"
        fi
    elif (( value < 90 )) ; then
        echo -ne "${LP_COLORMAP_8}"
    else # (( value >= 90 ))
        echo -ne "${LP_COLORMAP_9}"
    fi
}

##########
# DESIGN #
##########


# Sed expression using extended regexp to remove shell codes around terminal
# escape sequences
_LP_CLEAN_ESC="$(printf "s,%q|%q,,g" "$_LP_OPEN_ESC" "$_LP_CLOSE_ESC")"

# Remove all colors and escape characters of the given string and return a pure text
_lp_as_text()
{
    # Remove colors from the computed prompt
    echo -n "$1" | sed -$_LP_SED_EXTENDED "s/\x1B\[[0-9;]*[mK]//g;$_LP_CLEAN_ESC"
}

_lp_title()
{
    [[ "$LP_ENABLE_TITLE" != "1" ]] && return

    # Get the current computed prompt as pure text
    echo -n "${_LP_OPEN_ESC}${LP_TITLE_OPEN}$(_lp_as_text "$1")${LP_TITLE_CLOSE}${_LP_CLOSE_ESC}"
}

# insert a space on the right
_lp_sr()
{
    [[ -n "$1" ]] && echo -n "$1 "
}

# insert a space on the left
_lp_sl()
{
    [[ -n "$1" ]] && echo -n " $1"
}

# insert two space, before and after
_lp_sb()
{
    [[ -n "$1" ]] && echo -n " $1 "
}


_lp_time()
{
    [[ "$LP_ENABLE_TIME" != 1 ]] && return
    if [[ "$LP_TIME_ANALOG" != 1 ]]; then
        echo -n "${LP_COLOR_TIME}${_LP_TIME_SYMBOL}${NO_COL}"
    else
        echo -n "${LP_COLOR_TIME}"
        _lp_time_analog
        echo -n "${NO_COL}"
    fi
}

########################
# Construct the prompt #
########################


_lp_set_prompt()
{
    # Display the return value of the last command, if different from zero
    # As this get the last returned code, it should be called first
    local -i err=$?
    if (( err != 0 )); then
        #LP_ERR=" $LP_COLOR_ERR!$NO_COL"
        LP_ERR=$LP_COLOR_ERR
        # just change the prompt to red
    else
        LP_ERR=''     # Hidden
    fi

    # Reset IFS to its default value to avoid strange behaviors
    # (in case the user is playing with the value at the prompt)
    local IFS="$_LP_IFS"

    # execute the old prompt
    eval "${${LP_OLD_PROMPT_COMMAND#*$'\n'}%$'\n'*}"

    # left of main prompt: space at right
    LP_JOBS="$(_lp_sl "$(_lp_jobcount_color)")"
    LP_BATT="$(_lp_sl "$(_lp_battery_color)")"
    LP_TIME="$(_lp_sl "$(_lp_time)")"

    # in main prompt: no space
    if [[ "$LP_ENABLE_PROXY,$http_proxy" = 1,?* ]] ; then
        LP_PROXY="$LP_COLOR_PROXY$LP_MARK_PROXY$NO_COL"
    else
        LP_PROXY=
    fi

    # Display the current Python virtual environment, if available
    if [[ "$LP_ENABLE_VIRTUALENV,$VIRTUAL_ENV" = 1,?* ]] ; then
        LP_VENV=" [${LP_COLOR_VIRTUALENV}${VIRTUAL_ENV##*/}${NO_COL}]"
    else
        LP_VENV=
    fi

    # Display the current software collections enabled, if available
    if [[ "$LP_ENABLE_SCLS,$X_SCLS" = 1,?* ]] ; then
        LP_SCLS=" [${LP_COLOR_VIRTUALENV}${X_SCLS%"${X_SCLS##*[![:space:]]}"}${NO_COL}]"
    else
        LP_SCLS=
    fi

    # if change of working directory
    if [[ "$LP_OLD_PWD" != "LP:$PWD" ]]; then
        # Update directory icon for MacOS X
        $_LP_TERM_UPDATE_DIR

        LP_VCS=""
        LP_VCS_TYPE=""
        # LP_HOST is a global set at load time

        _lp_shorten_path   # set LP_PWD

        # LP_PERM: shows a ":"
        # - colored in green if user has write permission on the current dir
        # - colored in red if not
        if [[ "$LP_ENABLE_PERM" = 1 ]]; then
            if [[ -w "${PWD}" ]]; then
            else
                LP_PWD="${LP_COLOR_NOWRITE}${LP_PWD}${NO_COL}"
            fi
        fi

        if _lp_are_vcs_enabled; then
            LP_VCS="$(_lp_git_branch_color)"
            LP_VCS_TYPE="git"
        else # if this vcs rep is disabled
            LP_VCS="" # not necessary, but more readable
            LP_VCS_TYPE="disabled"
        fi

        if [[ -z "$LP_VCS_TYPE" ]] ; then
            LP_VCS=""
        else
            LP_VCS="$(_lp_sl "${LP_VCS}")"
        fi

        # TODO?
        # The color is different if user is root
        LP_PWD="${LP_COLOR_PATH}${LP_PWD}${NO_COL}"

        LP_OLD_PWD="LP:$PWD"

    # if do not change of working directory but...
    elif [[ -n "$LP_VCS_TYPE" ]]; then # we are still in a VCS dir
        case "$LP_VCS_TYPE" in
            git*)    LP_VCS="$(_lp_sl "$(_lp_git_branch_color)")";;
            disabled)LP_VCS="";;
        esac
    fi

    PS1="${LP_PS1_PREFIX}"
    # add user, host and permissions colon
    if [[ -n "$LP_USER" || -n "$LP_HOST" ]]; then
        PS1="${PS1}${LP_USER}${LP_HOST} "
    fi

    LP_KUBE="$(_lp_kube_context)"
    PS1="${PS1}${LP_PWD}${LP_SCLS}${LP_VENV}${LP_PROXY}"

    # Add VCS infos
    # If root, the info has not been collected unless LP_ENABLE_VCS_ROOT
    # is set.
    PS1="${PS1}${LP_VCS}"

    # add return code and prompt mark
    PS1="${PS1}${LP_ERR}${LP_PS1_POSTFIX}${NO_COL}"

    # "invisible" parts
    # Get the current prompt on the fly and make it a title
    LP_TITLE="$(_lp_title "$PS1")"

    # Insert it in the prompt
    PS1="${LP_TITLE}${PS1}"

    # add title escape time, jobs, load and battery to rprompt
    RPROMPT="${LP_KUBE}${LP_JOBS}${LP_BATT}${LP_TIME}"
}

prompt_tag()
{
    export LP_PS1_PREFIX="$(_lp_sr "$1")"
}

# Activate Liquid Prompt
prompt_on()
{
    # if Liquid Prompt has not been already set
    if [[ -z "$LP_OLD_PS1" ]] ; then
        LP_OLD_PS1="$PS1"
        LP_OLD_PROMPT_COMMAND="$(whence -f precmd)"
    fi
    function precmd {
        _lp_set_prompt
    }
}

# Come back to the old prompt
prompt_off()
{
    PS1=$LP_OLD_PS1
    precmd() { : ; }
    eval "$LP_OLD_PROMPT_COMMAND"
}

# By default, sourcing liquidprompt will activate Liquid Prompt
prompt_on
