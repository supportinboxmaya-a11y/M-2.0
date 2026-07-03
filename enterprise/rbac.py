"""Role-based access control."""


class Role:
    ADMIN = "admin"
    DEVELOPER = "developer"
    VIEWER = "viewer"


ROLE_PERMISSIONS = {
    Role.ADMIN: {"read", "write", "execute", "manage_users", "manage_keys",
                 "view_audit", "manage_orgs", "autonomous"},
    Role.DEVELOPER: {"read", "write", "execute", "autonomous"},
    Role.VIEWER: {"read"},
}


class RBAC:
    def permissions_for(self, role: str) -> set:
        return set(ROLE_PERMISSIONS.get(role, set()))

    def can(self, role: str, permission: str) -> bool:
        return permission in self.permissions_for(role)

    def require(self, role: str, permission: str) -> None:
        """Raise PermissionError when the role lacks the permission."""
        if not self.can(role, permission):
            raise PermissionError(f"role '{role}' lacks '{permission}'")

    def roles(self) -> dict:
        return {r: sorted(p) for r, p in ROLE_PERMISSIONS.items()}
