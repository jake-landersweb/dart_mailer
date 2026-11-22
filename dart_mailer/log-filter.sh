#!/bin/sh
set -o pipefail

# Match complete events and copy only validated fields. Never forward raw logs.
"$@" 2>&1 | awk '
  /^MAILER (ready|queue_poll_ok|application_error)$/ { print; fflush(); next }
  /^MAILER create_email status=[1-5][0-9]{2} source=(python-requests|other)$/ {
    print; fflush(); next
  }
  /^MAILER (queue_inserted|smtp_attempt|smtp_accepted) id=m-[0-9]{13}-[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/ {
    print; fflush(); next
  }
'
