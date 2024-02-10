#include <stdio.h>
#include <string.h>
#include <linux/perf_event.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <stdlib.h>

struct counter
{
    uint64_t time_enabled_ns;
    uint64_t instruction_count;
    uint64_t branch_misses;
    uint64_t page_faults;
};

struct read_format
{
    uint64_t nr;
    uint64_t time_enabled;
    uint64_t time_running;
    struct
    {
        uint64_t value;
    } values[];
};

struct perf_event_config
{
    uint64_t type;
    uint64_t config;
};

struct perf_event_config events[] = {
    {PERF_TYPE_HARDWARE, PERF_COUNT_HW_INSTRUCTIONS},
    {PERF_TYPE_HARDWARE, PERF_COUNT_HW_BRANCH_MISSES},
    {PERF_TYPE_SOFTWARE, PERF_COUNT_SW_PAGE_FAULTS},
    // {PERF_TYPE_SOFTWARE, PERF_COUNT_SW_CONTEXT_SWITCHES}, For whatever reason, these two always show 0
    // {PERF_TYPE_SOFTWARE, PERF_COUNT_SW_CPU_MIGRATIONS},
};

const int NUM_EVENTS = sizeof(events) / sizeof(events[0]);

int start()
{
    // Construct base perf_event_attr struct
    struct perf_event_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.size = sizeof(attr);
    attr.disabled = 1;
    attr.exclude_kernel = 1;
    attr.exclude_hv = 1;
    attr.sample_period = 0;
    attr.read_format = PERF_FORMAT_GROUP | PERF_FORMAT_TOTAL_TIME_ENABLED | PERF_FORMAT_TOTAL_TIME_RUNNING;

    int group = -1;
    int leader_fd;

    // Enable every event in perf_event_config
    for (int i = 0; i < NUM_EVENTS; i++)
    {
        attr.type = events[i].type;
        attr.config = events[i].config;

        int fd = syscall(SYS_perf_event_open, &attr, 0, -1, group, 0);
        if (fd == -1)
        {
            fprintf(stderr, "Failed to open event %lu: %s.\n", events[i].config, strerror(errno));
            return -1;
        }

        if (i == 0)
        {
            group = fd;
            leader_fd = fd;
        }
    }

    // Enable the event group
    if (ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP) == -1)
    {
        fprintf(stderr, "Failed to enable perf events: %s.\n", strerror(errno));
        // Consider cleaning up previously opened file descriptors here
        return -1;
    }

    return leader_fd;
}

int end(int fd, struct counter *out)
{
    if (out == NULL)
    {
        fprintf(stderr, "Error: 'out' pointer is NULL in end().\n");
        return -1;
    }

    // Disable the event group
    if (ioctl(fd, PERF_EVENT_IOC_DISABLE, PERF_IOC_FLAG_GROUP) == -1)
    {
        fprintf(stderr, "Error disabling perf event (fd: %d): %s\n", fd, strerror(errno));
        return -1;
    }

    // Allocate buffer for reading results
    int size = sizeof(struct read_format) + (sizeof(uint64_t) * NUM_EVENTS);
    struct read_format *buffer = (struct read_format *)malloc(size);
    if (!buffer)
    {
        fprintf(stderr, "Failed to allocate memory for read buffer.\n");
        return -1;
    }

    // Read results
    int ret_val = read(fd, buffer, size);
    if (ret_val == -1)
    {
        fprintf(stderr, "Error reading perf event results: %s\n", strerror(errno));
        free(buffer);
        return -1;
    }
    else if (ret_val != size)
    {
        fprintf(stderr, "Error reading perf event results: read %d bytes, expected %d\n", ret_val, size);
        free(buffer);
        return -1;
    }

    // Assign time_enabled_ns
    out->time_enabled_ns = buffer->time_enabled;

    // Directly assign values to struct fields treating them as an array 8)
    uint64_t *counter_ptr = (uint64_t *)out;
    counter_ptr++; // Now points to instruction_count, the first counter field

    for (int i = 0; i < NUM_EVENTS; i++)
    {
        counter_ptr[i] = buffer->values[i].value;
    }

    close(fd);
    free(buffer);
    return 0;
}