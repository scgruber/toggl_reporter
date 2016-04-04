# Toggl Reporter Script

This is a simple script that uses the Toggl API to query activities in a time range, and prints out a grouped list of those activities.
This can be useful in looking back over what you have done recently, or as a preliminary step in producing a status report.

## Example usage

    $ ruby toggl_reporter.rb -k $MY_TOGGL_API_KEY
    Development:
      * [23m] Write code
      * [120m] Wait for compiler
      * [11m] Run test suite


    $ ruby toggl_reporter.rb -h
    Usage: toggl_reporter [options]
        -k, --api-key KEY                The user's Toggl API key (required)
            --start DATE                 Start date for time entries to consider (default: 7 days ago)
            --end DATE                   End date for time entries to consider (default: today)
        -t, --threshold SECS             Drop all activities with a shorter duration (default: 300)
        -i, --include P1,P2,P3           Include only these projects in summary
        -e, --exclude P1,P2,P3           Exclude these projects from summary
