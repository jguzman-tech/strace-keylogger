# strace-keylogger
Demo program of how the strace can be used as a keylogger

`strace` is a common linux utility that will report all the system calls of a process. It is a great tool for debugging things on a low-level. I've found it useful for finding shared-library errors, hidden permission errors, and discovering file path issues.

These system calls include the `read` system call which is necessary to read keyboard input. I used this for awk practice, this is a simple application but awk is generally not suited for tasks like this.

```
This is a demo of how to use strace as a "poor man's keylogger".
Usage: sudo ./strace_keylogger.awk <PID>
```

![Example Usage (GIF)](./demo.gif)