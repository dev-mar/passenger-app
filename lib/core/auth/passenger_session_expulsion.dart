bool passengerSessionSyncBlocked = false;

void markPassengerSessionExpelled() {
  passengerSessionSyncBlocked = true;
}

void resetPassengerSessionExpulsionState() {
  passengerSessionSyncBlocked = false;
}
