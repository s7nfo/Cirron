#include <stdio.h>
#include <string.h>
#include <linux/perf_event.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <stdint.h>

struct counter
{
    uint64_t instruction_count;
    uint64_t time_enabled_ns;
};

int start()
{
    struct perf_event_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.type = PERF_TYPE_HARDWARE;
    attr.size = sizeof(attr);
    attr.exclude_kernel = 1;
    attr.exclude_hv = 1;
    attr.sample_period = 0;
    attr.config = PERF_COUNT_HW_INSTRUCTIONS;
    attr.read_format = PERF_FORMAT_TOTAL_TIME_ENABLED | PERF_FORMAT_TOTAL_TIME_RUNNING;

    int fd = syscall(SYS_perf_event_open, &attr, 0, -1, -1, 0);
    if (fd == -1)
    {
        fprintf(stderr, "Failed to perf_event_open: %s.\n", strerror(errno));
        return -1;
    }

    return fd;
}

int end(int fd, struct counter *out)
{
    if (out == NULL)
    {
        fprintf(stderr, "Error: 'out' pointer is NULL in end().\n");
        return -1;
    }

    if (ioctl(fd, PERF_EVENT_IOC_DISABLE, PERF_IOC_FLAG_GROUP) == -1)
    {
        fprintf(stderr, "Error disabling perf event (fd: %d): %s\n", fd, strerror(errno));
        return -1;
    }

    uint64_t read_format[5];
    if (read(fd, read_format, sizeof(read_format)) == -1)
    {
        fprintf(stderr, "Error reading perf event results (fd: %d): %s\n", fd, strerror(errno));
        return -1;
    }
    else
    {
        close(fd);
        out->instruction_count = read_format[0];
        out->time_enabled_ns = read_format[1];
    }

    return 0;
}