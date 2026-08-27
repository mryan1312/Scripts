#!/bin/bash

# Secure Token/FileVault authorization refresh for an actively logged-in
# macOS console user.
# Intended for Addigy Smart Software and execution as root.
#
# Account handling:
#   - Simple local: validate the local password, then refresh authorization.
#   - Mobile/cached directory: require live directory authentication, permit a
#     mismatched cached password, then require the cache to match after refresh.
#   - Network-only: stop safely because no local record exists to hold a token.

set -u
set -o pipefail
set +x

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
LC_ALL=C
export LC_ALL

readonly ADMIN_USER="kalmerlocal"

# IMPORTANT: Select this token from Addigy's variable picker. Do not hardcode
# the real password or its base64 value directly into this saved script.
ADMIN_PASSWORD_B64=$KALMERLOCAL_PASSWORD_B64

LOCK_DIR="/var/run/com.kalmer.securetoken-repair.lock"
ADMIN_PASSWORD=""
TARGET_PASSWORD=""
TARGET_USER=""
REISSUE_REQUIRED=0
ACCOUNT_TYPE="unknown"
DIRECTORY_NODE=""

log() {
    /usr/bin/printf '%s\n' "SecureTokenRepair: $*"
}

die() {
    log "ERROR: $*"
    exit 1
}

cleanup() {
    if [[ "$REISSUE_REQUIRED" -eq 1 && -n "$ADMIN_PASSWORD" && -n "$TARGET_PASSWORD" && -n "$TARGET_USER" ]]; then
        log "WARNING: Exit occurred after FileVault authorization removal; attempting emergency Secure Token enablement."
        if enable_secure_token && token_enabled "$TARGET_USER" && \
            filevault_user_enabled "$TARGET_USER"; then
            REISSUE_REQUIRED=0
            log "Emergency Secure Token enablement succeeded and was verified."
        else
            log "CRITICAL: Emergency Secure Token enablement failed; do not restart until the account is repaired."
        fi
    fi
    ADMIN_PASSWORD=""
    TARGET_PASSWORD=""
    ADMIN_PASSWORD_B64=""
    unset ADMIN_PASSWORD TARGET_PASSWORD ADMIN_PASSWORD_B64
    unset VERIFY_USER VERIFY_PASSWORD ST_ACTION ST_ADMIN_USER
    unset ST_ADMIN_PASSWORD ST_TARGET_USER ST_TARGET_PASSWORD
    unset VERIFY_NODE ACCOUNT_TYPE DIRECTORY_NODE
    if [[ -d "$LOCK_DIR" ]]; then
        /bin/rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

require_root() {
    [[ "$(/usr/bin/id -u)" -eq 0 ]] || die "This script must run as root."
}

acquire_lock() {
    /bin/mkdir "$LOCK_DIR" 2>/dev/null || \
        die "Another Secure Token repair appears to be running."
    /bin/chmod 700 "$LOCK_DIR"
}

local_account_exists() {
    /usr/bin/dscl /Local/Default -read "/Users/$1" RecordName >/dev/null 2>&1
}

search_account_exists() {
    /usr/bin/dscl /Search -read "/Users/$1" RecordName >/dev/null 2>&1
}

get_original_node() {
    local node=""

    node="$(/usr/bin/dscl -plist /Local/Default \
        -read "/Users/$1" OriginalNodeName 2>/dev/null | \
        /usr/bin/plutil -extract 'dsAttrTypeStandard:OriginalNodeName.0' \
        raw -o - - 2>/dev/null || true)"

    if [[ -z "$node" ]]; then
        node="$(/usr/bin/dscl /Local/Default \
            -read "/Users/$1" OriginalNodeName 2>/dev/null | \
            /usr/bin/awk '
                /^OriginalNodeName:/ {
                    sub(/^OriginalNodeName:[[:space:]]*/, "")
                    if (length($0)) { print; exit }
                    getline
                    sub(/^[[:space:]]*/, "")
                    print
                    exit
                }
            ' || true)"
    fi

    /usr/bin/printf '%s' "$node"
}

classify_account() {
    local username="$1"
    local auth_authority=""

    ACCOUNT_TYPE="unknown"
    DIRECTORY_NODE=""

    if local_account_exists "$username"; then
        auth_authority="$(/usr/bin/dscl /Local/Default \
            -read "/Users/$username" AuthenticationAuthority 2>/dev/null || true)"
        DIRECTORY_NODE="$(get_original_node "$username" || true)"

        if /usr/bin/printf '%s\n' "$auth_authority" | \
            /usr/bin/grep -q ';LocalCachedUser;' || [[ -n "$DIRECTORY_NODE" ]]; then
            ACCOUNT_TYPE="mobile"
        else
            ACCOUNT_TYPE="local"
        fi
    elif search_account_exists "$username"; then
        ACCOUNT_TYPE="network"
    fi
}

is_admin() {
    /usr/sbin/dseditgroup -o checkmember -m "$1" admin 2>/dev/null | \
        /usr/bin/grep -q 'yes'
}

token_enabled() {
    /usr/sbin/sysadminctl -secureTokenStatus "$1" 2>&1 | \
        /usr/bin/grep -q 'Secure token is ENABLED'
}

prompt_username() {
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/sudo -u "$CONSOLE_USER" \
        /usr/bin/osascript - "$CONSOLE_USER" <<'APPLESCRIPT'
on run argv
    set consoleUser to item 1 of argv
    set response to display dialog ¬
        "Confirm your macOS account name. This must match the account currently signed in." ¬
        default answer consoleUser ¬
        buttons {"Cancel", "Continue"} ¬
        default button "Continue" ¬
        cancel button "Cancel" ¬
        with title "Repair macOS Secure Token" ¬
        with icon caution ¬
        giving up after 300
    if gave up of response then error number -1712
    return text returned of response
end run
APPLESCRIPT
}

prompt_password() {
    local prompt_message="$1"
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/sudo -u "$CONSOLE_USER" \
        /usr/bin/osascript - "$prompt_message" <<'APPLESCRIPT'
on run argv
set response to display dialog (item 1 of argv) ¬
    default answer "" ¬
    with hidden answer ¬
    buttons {"Cancel", "Repair"} ¬
    default button "Repair" ¬
    cancel button "Cancel" ¬
    with title "Repair macOS Secure Token" ¬
    with icon caution ¬
    giving up after 300
if gave up of response then error number -1712
return text returned of response
end run
APPLESCRIPT
}

show_result() {
    local message="$1"
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/sudo -u "$CONSOLE_USER" \
        /usr/bin/osascript - "$message" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
    display dialog (item 1 of argv) ¬
        buttons {"OK"} ¬
        default button "OK" ¬
        with title "Repair macOS Secure Token" ¬
        with icon note ¬
        giving up after 120
end run
APPLESCRIPT
}

# Validate a local account password without placing it in the process arguments
# or printing it. dscl prompts on the pseudo-terminal created by expect.
verify_password() {
    VERIFY_NODE="$1"
    VERIFY_USER="$2"
    VERIFY_PASSWORD="$3"
    export VERIFY_NODE VERIFY_USER VERIFY_PASSWORD

    /usr/bin/expect <<'EXPECT'
log_user 1
set timeout 30
spawn /usr/bin/dscl $env(VERIFY_NODE) -authonly $env(VERIFY_USER)
expect {
    -re {Password:} {
        send -- "$env(VERIFY_PASSWORD)\r"
    }
    -re {password:} {
        send -- "$env(VERIFY_PASSWORD)\r"
    }
    timeout { exit 70 }
    eof { exit 71 }
}
expect eof
set result [wait]
exit [lindex $result 3]
EXPECT
    local result=$?

    VERIFY_NODE=""
    VERIFY_USER=""
    VERIFY_PASSWORD=""
    unset VERIFY_NODE VERIFY_USER VERIFY_PASSWORD
    return "$result"
}

# Verify a password directly against the local account record's cached
# SALTED-SHA512-PBKDF2 verifier. This deliberately bypasses Open Directory
# authentication routing, so a reachable AD/Kerberos node cannot turn the
# check into a live-directory authentication and produce a false cache match.
#
# Return values:
#   0  password matches the offline cache
#   1  password does not match the offline cache
#   >1 verifier prerequisite or account-data error
verify_cached_shadowhash() {
    local username="$1"
    local supplied_password="$2"
    local account_plist=""
    local shadow_data_b64=""
    local salt_b64=""
    local entropy_b64=""
    local iterations=""
    local verifier_result=2

    [[ "$(/usr/bin/id -u)" -eq 0 ]] || return 77
    [[ "$username" =~ ^[A-Za-z0-9._-]+$ ]] || return 64
    [[ -x /usr/bin/ruby ]] || return 69

    account_plist="/private/var/db/dslocal/nodes/Default/users/${username}.plist"
    [[ -r "$account_plist" ]] || return 66

    # ShadowHashData is an embedded binary plist stored as a data value in the
    # outer local-account plist. Keep all verifier material in memory/pipes.
    shadow_data_b64="$(
        /usr/bin/plutil -extract ShadowHashData.0 raw -o - \
            "$account_plist" 2>/dev/null
    )" || return 65

    [[ -n "$shadow_data_b64" ]] || return 65

    salt_b64="$(
        /usr/bin/printf '%s' "$shadow_data_b64" | \
            /usr/bin/base64 -D | \
            /usr/bin/plutil \
                -extract SALTED-SHA512-PBKDF2.salt raw -o - - 2>/dev/null
    )" || return 65

    entropy_b64="$(
        /usr/bin/printf '%s' "$shadow_data_b64" | \
            /usr/bin/base64 -D | \
            /usr/bin/plutil \
                -extract SALTED-SHA512-PBKDF2.entropy raw -o - - 2>/dev/null
    )" || return 65

    iterations="$(
        /usr/bin/printf '%s' "$shadow_data_b64" | \
            /usr/bin/base64 -D | \
            /usr/bin/plutil \
                -extract SALTED-SHA512-PBKDF2.iterations raw -o - - 2>/dev/null
    )" || return 65

    [[ -n "$salt_b64" && -n "$entropy_b64" && \
        "$iterations" =~ ^[0-9]+$ ]] || return 65

    # The password travels only through stdin. Hash components travel through
    # anonymous file descriptors. None are placed in process arguments or logs.
    /usr/bin/printf '%s' "$supplied_password" | \
        /usr/bin/ruby /dev/fd/3 \
            3<<'RUBY' \
            4<<<"$salt_b64" \
            5<<<"$entropy_b64" \
            6<<<"$iterations"
require "openssl"

begin
  salt = IO.new(4).read.strip.unpack1("m0")
  expected = IO.new(5).read.strip.unpack1("m0")
  iterations = Integer(IO.new(6).read.strip)
  password = STDIN.read.b

  exit 2 if salt.empty? || expected.empty? || !iterations.positive?

  candidate = OpenSSL::PKCS5.pbkdf2_hmac(
    password,
    salt,
    iterations,
    expected.bytesize,
    OpenSSL::Digest::SHA512.new
  )

  difference = candidate.bytes.zip(expected.bytes).reduce(0) do |result, pair|
    result | (pair[0] ^ pair[1])
  end

  exit(difference.zero? ? 0 : 1)
rescue
  exit 2
end
RUBY
    verifier_result=$?

    shadow_data_b64=""
    salt_b64=""
    entropy_b64=""
    iterations=""
    supplied_password=""
    unset shadow_data_b64 salt_b64 entropy_b64 iterations supplied_password

    return "$verifier_result"
}

# sysadminctl recommends '-' for passwords. expect supplies the two hidden
# prompts in order: token administrator first, target account second.
enable_secure_token() {
    ST_ACTION="on"
    ST_ADMIN_USER="$ADMIN_USER"
    ST_ADMIN_PASSWORD="$ADMIN_PASSWORD"
    ST_TARGET_USER="$TARGET_USER"
    ST_TARGET_PASSWORD="$TARGET_PASSWORD"
    export ST_ACTION ST_ADMIN_USER ST_ADMIN_PASSWORD ST_TARGET_USER ST_TARGET_PASSWORD

    /usr/bin/expect <<'EXPECT'
log_user 1
set timeout 60
set prompt_count 0

spawn /usr/sbin/sysadminctl \
    -adminUser $env(ST_ADMIN_USER) \
    -adminPassword - \
    -secureTokenOn $env(ST_TARGET_USER) \
    -password -

expect {
    -re {Enter password for [^\r\n]*:} {
        incr prompt_count
        if {$prompt_count == 1} {
            send -- "$env(ST_ADMIN_PASSWORD)\r"
        } elseif {$prompt_count == 2} {
            send -- "$env(ST_TARGET_PASSWORD)\r"
        } else {
            exit 72
        }
        exp_continue
    }
    timeout { exit 70 }
    eof {}
}

set result [wait]
if {$prompt_count != 2} {
    exit 73
}
exit [lindex $result 3]
EXPECT
    local result=$?

    ST_ACTION=""
    ST_ADMIN_USER=""
    ST_ADMIN_PASSWORD=""
    ST_TARGET_USER=""
    ST_TARGET_PASSWORD=""
    unset ST_ACTION ST_ADMIN_USER ST_ADMIN_PASSWORD ST_TARGET_USER ST_TARGET_PASSWORD
    return "$result"
}

filevault_user_enabled() {
    /usr/bin/fdesetup list 2>/dev/null | \
        /usr/bin/awk -F, -v user="$1" \
            '$1 == user { found=1 } END { exit !found }'
}

refresh_postconditions_met() {
    local username="$1"
    local password="$2"
    local require_filevault_membership="$3"
    local account_type="$4"

    token_enabled "$username" || return 1

    if [[ "$account_type" == "mobile" ]]; then
        verify_cached_shadowhash "$username" "$password" || return 1
    fi

    if [[ "$require_filevault_membership" == "yes" ]]; then
        filevault_user_enabled "$username" || return 1
    fi

    return 0
}

main() {
    local original_token_state="disabled"
    local target_was_filevault_enabled="no"
    local password_prompt=""
    local cache_matched_before="not_applicable"
    local cache_verify_result=0
    local enable_result=0

    require_root
    acquire_lock

    [[ -x /usr/bin/expect ]] || die "/usr/bin/expect is unavailable on this Mac."

    CONSOLE_USER="$(/usr/bin/stat -f '%Su' /dev/console)"
    if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" || "$CONSOLE_USER" == "loginwindow" || "$CONSOLE_USER" == "_mbsetupuser" ]]; then
        die "No eligible user is signed into the graphical console."
    fi
    CONSOLE_UID="$(/usr/bin/id -u "$CONSOLE_USER" 2>/dev/null)" || \
        die "Unable to resolve the console user's UID."
    readonly CONSOLE_USER CONSOLE_UID

    local_account_exists "$ADMIN_USER" || die "The $ADMIN_USER account does not exist locally."
    is_admin "$ADMIN_USER" || die "The $ADMIN_USER account is not a local administrator."
    token_enabled "$ADMIN_USER" || \
        die "The $ADMIN_USER account does not have a Secure Token. No changes were made."

    if [[ -z "$ADMIN_PASSWORD_B64" || "$ADMIN_PASSWORD_B64" == '$KALMERLOCAL_PASSWORD_B64' ]]; then
        die "The Addigy secret variable was empty or was not substituted."
    fi
    ADMIN_PASSWORD="$(/usr/bin/printf '%s' "$ADMIN_PASSWORD_B64" | /usr/bin/base64 -D 2>/dev/null)" || \
        die "The Addigy administrator secret is not valid base64."
    ADMIN_PASSWORD_B64=""
    unset ADMIN_PASSWORD_B64
    [[ -n "$ADMIN_PASSWORD" ]] || die "The decoded Addigy administrator password is empty."

    verify_password /Local/Default "$ADMIN_USER" "$ADMIN_PASSWORD" || \
        die "The stored $ADMIN_USER password was rejected. No changes were made."

    if ! TARGET_USER="$(prompt_username 2>/dev/null)"; then
        die "The user cancelled or the username prompt timed out."
    fi
    [[ -n "$TARGET_USER" && "$TARGET_USER" != *'/'* && "$TARGET_USER" != *$'\n'* ]] || \
        die "The entered account name is invalid."
    [[ "$TARGET_USER" == "$CONSOLE_USER" ]] || \
        die "The entered account does not match the active console account."
    [[ "$TARGET_USER" != "$ADMIN_USER" ]] || \
        die "The target account cannot be $ADMIN_USER."

    classify_account "$TARGET_USER"
    case "$ACCOUNT_TYPE" in
        local)
            log "Detected a simple local account: $TARGET_USER."
            ;;
        mobile)
            [[ -n "$DIRECTORY_NODE" ]] || \
                die "The account is mobile/cached, but its original directory node could not be identified. No changes were made."
            log "Detected a mobile directory account: $TARGET_USER."
            ;;
        network)
            show_result "This is a network-only account and does not have a local/mobile account record. macOS cannot attach a Secure Token to it yet. IT must create or convert it to a mobile/local account first."
            die "Network-only account detected. Secure Token repair is not applicable without a local account record."
            ;;
        *)
            die "The console account could not be resolved through the local or directory search nodes."
            ;;
    esac

    if [[ "$ACCOUNT_TYPE" == "mobile" ]]; then
        password_prompt="A mobile directory account was detected. Connect to the company network or VPN, then enter your current network password. It will be verified live against the directory and used to repair this Mac's cached credentials and Secure Token; it will not be saved."
    else
        password_prompt="Enter your current macOS login password. It will be checked against this Mac's local account and will not be saved."
    fi

    if ! TARGET_PASSWORD="$(prompt_password "$password_prompt" 2>/dev/null)"; then
        die "The user cancelled or the password prompt timed out."
    fi
    [[ -n "$TARGET_PASSWORD" ]] || die "No password was entered."

    if [[ "$ACCOUNT_TYPE" == "mobile" ]]; then
        log "Verifying live directory connectivity and the current directory password."
        verify_password "$DIRECTORY_NODE" "$TARGET_USER" "$TARGET_PASSWORD" || \
            die "Live directory authentication failed. Confirm company-network/VPN connectivity, DNS, time, account status, and the current directory password. No token changes were made."

        log "Checking the current directory password directly against the offline cached password hash."
        if verify_cached_shadowhash "$TARGET_USER" "$TARGET_PASSWORD"; then
            cache_matched_before="yes"
            log "The offline cached password matches the current directory password."
        else
            cache_verify_result=$?
            case "$cache_verify_result" in
                1)
                    cache_matched_before="no"
                    log "A directory-to-offline-cache password mismatch was confirmed; continuing with the Secure Token repair."
                    ;;
                *)
                    die "Unable to inspect the offline cached password hash safely. Verifier result: $cache_verify_result. No token changes were made."
                    ;;
            esac
        fi
    else
        verify_password /Local/Default "$TARGET_USER" "$TARGET_PASSWORD" || \
            die "The user's local password was rejected. No token changes were made."
    fi

    if token_enabled "$TARGET_USER"; then
        original_token_state="enabled"
    fi

    if filevault_user_enabled "$TARGET_USER"; then
        target_was_filevault_enabled="yes"
    fi

    if [[ "$target_was_filevault_enabled" == "yes" ]]; then
        log "Validated prerequisites; removing FileVault unlock authorization for $TARGET_USER."
        /usr/bin/fdesetup remove -user "$TARGET_USER" || \
            die "FileVault unlock authorization removal failed. No Secure Token change was attempted."
        if filevault_user_enabled "$TARGET_USER"; then
            die "FileVault reported removal, but $TARGET_USER is still present in the FileVault user list."
        fi
        REISSUE_REQUIRED=1
    else
        log "$TARGET_USER is not currently listed for FileVault unlock; skipping FileVault authorization removal."
    fi

    if [[ "$original_token_state" == "enabled" ]]; then
        log "Refreshing Secure Token authorization for $TARGET_USER."
    else
        log "Issuing a Secure Token to $TARGET_USER."
    fi

    enable_result=0
    enable_secure_token || enable_result=$?
    if [[ "$enable_result" -ne 0 ]] || \
        ! refresh_postconditions_met "$TARGET_USER" "$TARGET_PASSWORD" \
            "$target_was_filevault_enabled" "$ACCOUNT_TYPE"; then
        log "WARNING: The first Secure Token enablement attempt did not satisfy all postconditions; retrying once."
        enable_result=0
        enable_secure_token || enable_result=$?
    fi

    token_enabled "$TARGET_USER" || {
        show_result "The Secure Token refresh did not complete. Please contact IT and do not restart this Mac until IT verifies the account."
        die "CRITICAL: $TARGET_USER does not have a Secure Token after two enablement attempts."
    }

    if [[ "$target_was_filevault_enabled" == "yes" ]] && \
        ! filevault_user_enabled "$TARGET_USER"; then
        show_result "The Secure Token was enabled, but FileVault startup authorization was not restored. Please contact IT before restarting."
        die "Secure Token is enabled, but prior FileVault membership was not restored."
    fi

    if [[ "$ACCOUNT_TYPE" == "mobile" ]]; then
        log "Verifying the current directory password directly against the refreshed offline cached password hash."
        if verify_cached_shadowhash "$TARGET_USER" "$TARGET_PASSWORD"; then
            log "The refreshed offline mobile cache accepts the current directory password."
        else
            cache_verify_result=$?
            show_result "The Secure Token was enabled, but this Mac still does not accept your network password in its offline credential cache. Stay connected to the company network or VPN and contact IT before restarting."
            if [[ "$cache_verify_result" -eq 1 ]]; then
                die "Secure Token is enabled, but the current directory password does not match the refreshed offline cache. Pre-refresh cache match: $cache_matched_before."
            fi
            die "Secure Token is enabled, but the post-refresh offline-cache verifier failed with result $cache_verify_result. Pre-refresh cache match: $cache_matched_before."
        fi
    fi

    REISSUE_REQUIRED=0

    TARGET_PASSWORD=""
    ADMIN_PASSWORD=""
    unset TARGET_PASSWORD ADMIN_PASSWORD
    log "SUCCESS: Secure Token, offline-cache, and required FileVault authorization postconditions were verified for $TARGET_USER."
    show_result "Your macOS Secure Token authorization was refreshed successfully."
}

main "$@"
