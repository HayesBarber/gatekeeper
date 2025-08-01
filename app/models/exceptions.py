class ClientNotFound(Exception):
    def __init__(self, client_id: str):
        self.client_id = client_id
        super().__init__(f"Client '{client_id}' not found.")

class ChallengeNotVerified(Exception):
    def __init__(self, client_id: str):
        self.client_id = client_id
        super().__init__(f"Challenge for client '{client_id}' could not be verified.")
