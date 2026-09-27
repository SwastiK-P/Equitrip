#!/usr/bin/env bash
#
# Booking-change reading, tested without the app: the gate, the fact reader
# and the matcher are Foundation-only, so they compile here with swiftc and
# run against fixture emails built around the Kashi trips.
#
#   scripts/booking-mail-tests/run.sh

set -euo pipefail
cd "$(dirname "$0")"
G=../../Equitrip
out=$(mktemp -d)/booking-tests
swiftc -swift-version 5 -o "$out" \
  $G/Gmail/ExpenseMailGate.swift $G/Gmail/MailMessage.swift $G/Intelligence/TravelDate.swift \
  $G/Gmail/BookingMailFacts.swift $G/Gmail/BookingMatcher.swift main.swift
"$out"
