/// Bloquea sync FCM tras expulsión de sesión hasta próximo login.
bool passengerSessionSyncBlocked = false;

void markPassengerSessionExpelled() {
  passengerSessionSyncBlocked = true;
}

void resetPassengerSessionExpulsionState() {
  passengerSessionSyncBlocked = false;
}
